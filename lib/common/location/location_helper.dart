import 'dart:io';

import 'package:flutter/material.dart';
import 'package:background_locator/background_locator.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/date_formatter.dart';
import 'package:mahlmann_app/common/lang/m_localizations.dart';
import 'package:mahlmann_app/common/logger/m_logger.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/settings/locator_settings.dart';

class PositionResponse {
	String time;
	double lat;
	double lon;
	double accuracy;
	double altitude;
	double speed;
	int timeStamp;
	
	PositionResponse({
		this.time,
		this.lat,
		this.lon,
		this.accuracy,
		this.altitude,
		this.speed,
		this.timeStamp,
	});
	
	String toString() {
		return "time: $time, lat: $lat, lon: $lon, accuracy: $accuracy, altitude: $altitude, speed: $speed";
	}
	
	Map<String, dynamic> toMap() {
		return {
			"time": this.time,
			"latitude": this.lat,
			"longitude": this.lon,
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
	
	static int _count = -1;
	static bool _isInitialized = false;
	final isTrackingNotifier = ValueNotifier<bool>(false);
	MLocalizations _loc;
	
	// static Future<bool> get _isTracking async {
	//   final isTracking = await BackgroundLocator.isRegisterLocationUpdate();
	//   print('Running: $isTracking');
	//   return isTracking;
	// }
	
	static Future<bool> get _isRunning async {
		final isRunning = await BackgroundLocator.isServiceRunning();
		MLogger().d('Running: $isRunning');
		return isRunning;
	}
	
	// Call this as early as possible
	Future initialize(BuildContext context) async {
		_loc = context.loc;
		print('Initializing...');
		await BackgroundLocator.initialize();
		print('Initialization done');
		
		isTrackingNotifier.value = await _isRunning;
		_isInitialized = true;
	}
	
	// ============= Control staff ================
	
	Future<bool> get isTrackingLocation async {
		assert(_isInitialized, "LocationHelper should be initialized before use");
		return _isRunning;
	}
	
	Future<void> startListeningLocation() async {
		assert(_isInitialized, "LocationHelper should be initialized before use");
		// if (await isLocationEnabled) {
		final isNotTracking = !await _isRunning;
		MLogger().d("isNotTracking: $isNotTracking");
		if (isNotTracking) {
			await _startLocator();
		}
		isTrackingNotifier.value = await _isRunning;
		// } else {
		//   print("location is not enabled");
		// }
	}
	
	Future<void> stopListeningLocation() async {
		assert(_isInitialized, "LocationHelper should be initialized before use");
		
		final isRunning = await _isRunning;
		MLogger().d("isRunning: $isRunning");
		if (isRunning) {
			await BackgroundLocator.unRegisterLocationUpdate();
			isTrackingNotifier.value = await _isRunning;
		}
	}
	
	dispose() {
		if (Platform.isAndroid) {
			// GpsManager.dispose();
		} else {
			print('dispose for iOS');
		}
		_instance = null;
		_isInitialized = false;
	}
	
	//
	
	Future _startLocator() async {
		final pref = await SharedPreferences.getInstance();
		Map<String, dynamic> data = {'countInit': 1};
		// Comment initDataCallback, so service not set init variable,
		// variable stay with value of last run after unRegisterLocationUpdate
		final notificationTitle = _loc?.notificationTitle ?? "GPS Aufzeichnung";
		final notificationMsg =
				_loc?.notificationSubtitle ?? "MM GPS Aufzeichnung";
		final notificationBigMsg =
				_loc?.notificationSubtitle ?? "MM GPS Aufzeichnung";
		final accuracy = _desiredAccuracy(pref.getString(PREF_ACCURACY));
		final distanceFilter = pref.getDouble(PREF_DISTANCE_FILTER) ?? 0.0;
		final interval = pref.getInt(PREF_INTERVAL) ?? 5;
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
		if (params.containsKey('countInit')) {
			dynamic tmpCount = params['countInit'];
			if (tmpCount is double) {
				_count = tmpCount.toInt();
			} else if (tmpCount is String) {
				_count = int.parse(tmpCount);
			} else if (tmpCount is int) {
				_count = tmpCount;
			} else {
				_count = -2;
			}
		} else {
			_count = 0;
		}
		print("_onInitBackgroundLocation, count: $_count");
	}
	
	static Future<void> _onDispose() async {
		print("***********Dispose callback handler");
		print("_onDispose, count: $_count");
	}
	
	static Future<void> _onLocationData(LocationDto dto) async {
		MLogger().d(dto.toString());
		_count++;
		
		final time = await DateFormatter.getTimeStringAsync();
		_updateNotificationText(time);
		
		final position = PositionResponse(
				timeStamp: dto.time.toInt(),
				time: time,
				lat: dto.latitude,
				lon: dto.longitude,
				accuracy: dto.accuracy,
				altitude: dto.altitude,
				speed: dto.speed);
		print('position: $position');
		// TODO: handle new position here
	}
	
	static void _onNotificationTap() {
		print('***notificationCallback');
	}
	
	//  If your app is open and you need to change the accuracy just stop the plugin,
	//  init it with new accuracy setting and start it again.
	void applyAccuracy(String accuracy) {
		// TODO: implement this
	}
	
	void applyDistance(double distance) {
		// TODO: implement this
	}
	
	void applyInterval(int value) {
		// TODO: implement this
	}
	
	void applyFastestInterval(int value) {
		// TODO: implement this
	}
	
	void applyMaxWaitTime(int value) {
		// TODO: implement this
	}
	
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
}