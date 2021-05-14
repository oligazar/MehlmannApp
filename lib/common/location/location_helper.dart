import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:background_locator/background_locator.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/date_formatter.dart';
import 'package:mahlmann_app/common/logger/m_logger.dart';
import 'package:mahlmann_app/common/sqlite/db_client.dart';
import 'package:mahlmann_app/models/built_value/path_point.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/settings/locator_settings.dart';

class PositionResponse {
  String time;
  double lat;
  double lng;
  double accuracy;
  double altitude;
  double speed;
  int timeStamp;

  PositionResponse({
    this.time,
    this.lat,
    this.lng,
    this.accuracy,
    this.altitude,
    this.speed,
    this.timeStamp,
  });

  String toString() {
    return "time: $time, lat: $lat, lon: $lng, accuracy: $accuracy, altitude: $altitude, speed: $speed";
  }

  Map<String, dynamic> toMap() {
    return {
      "time": this.time,
      "latitude": this.lat,
      "longitude": this.lng,
      "accuracy": this.accuracy,
      "altitude": this.altitude,
      "speed": this.speed,
      "timeStamp": this.timeStamp,
    };
  }
}

class LocationHelper {
  static LocationHelper _instance;

  LocationHelper._internal() {
    _instance = this;
  }

  factory LocationHelper() => _instance ?? LocationHelper._internal();

  ReceivePort _receivePort = ReceivePort();

  static const String _isolateName = 'LocatorIsolate';

  static SendPort get _sendPort =>
      IsolateNameServer.lookupPortByName(_isolateName);

  Completer<bool> _isInitialized = Completer();
  
  final isTracking = ValueNotifier<bool>(false);
  final locationData = ValueNotifier<PositionResponse>(null);

  static Future<bool> get _isRunning async {
    final isRunning = await BackgroundLocator.isServiceRunning();
    MLogger().d('Running: $isRunning');
    return isRunning;
  }

  // Call this as early as possible
  Future init() async {
    if (_sendPort != null) {
      IsolateNameServer.removePortNameMapping(_isolateName);
    }

    IsolateNameServer.registerPortWithName(_receivePort.sendPort, _isolateName);

    _receivePort.listen(
      (dynamic data) async {
        await _updateNotifiers(data);
      },
    );

    await _initBackgroundLocator();
  }

  // ============= Control staff ================

  Future<bool> get isTrackingLocation async {
    await _isInitialized.future;
    return _isRunning;
  }

  Future<void> startListeningLocation() async {
    await _isInitialized.future;
    // if (await isLocationEnabled) {
    final isNotTracking = !await _isRunning;
    MLogger().d("isNotTracking: $isNotTracking");
    if (isNotTracking) {
      await _startLocator();
    }
    isTracking.value = await _isRunning;
  }

  Future<void> stopListeningLocation() async {
    await _isInitialized.future;

    final isRunning = await _isRunning;
    MLogger().d("isRunning: $isRunning");
    if (isRunning) {
      await BackgroundLocator.unRegisterLocationUpdate();
      isTracking.value = await _isRunning;
    }
  }

  dispose() {
    if (Platform.isAndroid) {
      // GpsManager.dispose();
    } else {
      print('dispose for iOS');
    }
    _instance = null;
    _isInitialized = null;
  }

  //

  Future _startLocator() async {
    final pref = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {'countInit': 1};
    // Comment initDataCallback, so service not set init variable,
    // variable stay with value of last run after unRegisterLocationUpdate
    final notificationTitle = "GPS Aufzeichnung";
    final notificationMsg = "MM GPS Aufzeichnung";
    final notificationBigMsg = "MM GPS Aufzeichnung";
    final accuracy = _desiredAccuracy(pref.getString(PREF_ACCURACY));
    final distanceFilter = 0.0; // pref.getDouble(PREF_DISTANCE_FILTER) ?? 5.0;
    final interval = 1; // pref.getInt(PREF_INTERVAL) ?? 5;
    await BackgroundLocator.registerLocationUpdate(_onLocationData,
        initCallback: _onInitBackgroundLocation,
        initDataCallback: data,
        disposeCallback: _onDispose,
        iosSettings: IOSSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        ),
        autoStop: false,
        androidSettings: AndroidSettings(
            accuracy: LocationAccuracy.NAVIGATION,
            interval: interval,
            distanceFilter: distanceFilter,
            client: LocationClient.google,
            androidNotificationSettings: AndroidNotificationSettings(
                notificationChannelName: 'Location tracking',
                notificationTitle: notificationTitle,
                notificationMsg: notificationMsg,
                notificationBigMsg: notificationBigMsg,
                notificationIcon: '',
                notificationIconColor: Colors.grey,
                notificationTapCallback: _onNotificationTap)));
  }

  // ============= Callbacks ================

  static Future<void> _onInitBackgroundLocation(
      Map<dynamic, dynamic> params) async {
    print("***********Init callback handler");
  }

  static Future<void> _onDispose() async {
    print("***********Dispose callback handler");
  }

  static Future<void> _onLocationData(LocationDto dto) async {
    MLogger().d(dto.toString());

    final time = await DateFormatter.getTimeStringAsync();
    _updateNotificationText(time);

    final position = PositionResponse(
        timeStamp: dto.time.toInt(),
        time: time,
        lat: dto.latitude,
        lng: dto.longitude,
        accuracy: dto.accuracy,
        altitude: dto.altitude,
        speed: dto.speed);
    print('position: $position');

    _sendPort?.send(position);
    // save latlngs to db
    final lat = position?.lat;
    final lng = position?.lng;
    if (lat != null && lng != null) {
      DbClient().insertPathPoint(PathPoint(lat: lat, lng: lng));
    }
  }

  static void _onNotificationTap() {
    print('***notificationCallback');
  }

  //  If your app is open and you need to change the accuracy just stop the plugin,
  //  init it with new accuracy setting and start it again.

  LocationAccuracy _desiredAccuracy(String accuracy) {
    switch (accuracy) {
      case ACCURACY_BEST_FOR_NAVIGATION:
        return LocationAccuracy.NAVIGATION;
      case ACCURACY_BEST:
        return LocationAccuracy.HIGH;
      case ACCURACY_NEAREST_TEN_METERS:
        return LocationAccuracy.BALANCED;
      case ACCURACY_HUNDRED_METERS:
        return LocationAccuracy.LOW;
      case ACCURACY_KILOMETER:
      case ACCURACY_THREE_KILOMETERS:
        return LocationAccuracy.POWERSAVE;
    }
    return LocationAccuracy.NAVIGATION;
  }

  static Future<void> _updateNotificationText(String updateTime) async {
    if (updateTime == null) return;
    if (Platform.isIOS) return;

    await BackgroundLocator.updateNotificationText(
        bigMsg: "Uhrzeit der letzten Aktualisierung: $updateTime");
  }

  Future _initBackgroundLocator() async {
    print('Initializing...');
    await BackgroundLocator.initialize();
    print('Initialization done');

    isTracking.value = await _isRunning;
    _isInitialized.complete(true);
  }

  Future<void> _updateNotifiers(PositionResponse position) async {
    // final log = await FileManager.readLogFile();
    // await _updateNotificationText(dto);

    if (position != null) {
      locationData.value = position;
    }
  }
}
