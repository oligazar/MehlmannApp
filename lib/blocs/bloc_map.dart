import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/common/api/api_client.dart';
import 'package:mahlmann_app/common/date_formatter.dart';
import 'package:mahlmann_app/common/interfaces/disposable.dart';
import 'package:mahlmann_app/common/prefs.dart';
import 'package:mahlmann_app/common/sqlite/db_client.dart';
import 'package:mahlmann_app/models/built_value/btns_mode.dart';
import 'package:mahlmann_app/models/built_value/comment.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/built_value/fountain.dart';
import 'package:mahlmann_app/models/built_value/group.dart';
import 'package:mahlmann_app/models/map/map_data.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;
import 'package:rxdart/rxdart.dart' as rx;

class BlocMap extends Disposable {
  // Try GetIt sometimes for this things!
  final _db = DbClient();
  final _api = ApiClient();
  final _mapData = rx.BehaviorSubject<MapData>.seeded(MapData());
  final _isLoading = rx.BehaviorSubject<bool>.seeded(false);
  final _bounds = rx.BehaviorSubject<LatLngBounds>();
  final _measurement = rx.BehaviorSubject<double>();
  final _mode = rx.BehaviorSubject<BtnsMode>.seeded(BtnsMode.none);
  final _fieldInfo = rx.BehaviorSubject<Field>();
  final _searchedFieldSuggestions = rx.BehaviorSubject<List<Field>>.seeded([]); // orange
  final _fieldComments = rx.BehaviorSubject<List<Comment>>();
  final _inboxGroups = rx.BehaviorSubject<List<Group>>(); // purple

  final _fields = Set<Field>(); // orange
  final _searchedFields = Set<Field>(); // orange
  final _fieldsGroup = Set<Field>(); // red
  final _inboxFields = Set<Field>(); // red

  Stream<MapData> get mapData => _mapData.stream;
  Stream<bool> get isLoading => _isLoading.stream;

  Stream<LatLngBounds> get bounds => _bounds.stream;

  Stream<double> get measurement => _measurement.stream;

  Stream<BtnsMode> get mode => _mode.stream;

  Stream<List<Comment>> get fieldComments => _fieldComments.stream;

  Stream<List<Group>> get inboxGroups => _inboxGroups.stream;

  Stream<Field> get fieldInfo => _fieldInfo.stream;
  
  Stream<List<Field>> get searchedFieldSuggestions => _searchedFieldSuggestions.stream;

  bool get hasFieldInfo => _fieldInfo.hasValue;

  final List<LatLng> _pins = <LatLng>[];

  BtnsMode get currentMode => _mode.value;

  BlocMap() {
    _prepareData();
  }

  @override
  void dispose() {
    _mapData.close();
    _bounds.close();
    _measurement.close();
    _mode.close();
    _fieldInfo.close();
    _fieldComments.close();
    _inboxGroups.close();
    _searchedFieldSuggestions.close();
    _isLoading.close();
  }
  
  void clearInboxFields() {
    _inboxFields.clear();
    final polygons = _createPolygons();
    _updateMapData(polygons: polygons);
  }

  void onFieldsQuerySubmitted(String query) async {
    _mode.add(BtnsMode.none);
    print("query: $query");

    final searchedFields = await _db.queryFields(query: query);
    _inboxFields.clear();
    _searchedFields.clear();
    _searchedFieldSuggestions.add(null);
    _searchedFields.addAll(searchedFields ?? []);

    final polygons = _createPolygons();
    _updateMapData(polygons: polygons);

    _updateBounds(searchedFields);
  }
  
  void onSuggestionFieldClick(Field field) async {
    _mode.add(BtnsMode.none);
    _searchedFieldSuggestions.add(null);
    _inboxFields.clear();
    _searchedFields.clear();
    _searchedFields.addAll([field]);

    final polygons = _createPolygons();
    _updateMapData(polygons: polygons);

    _updateBounds([field]);
  }

  void onFieldsQueryChanged(String query) async {
    // update suggestions
    if (query.length > 1) {
      final searchedFields = await _db.queryFields(query: query);
      _searchedFieldSuggestions.add(searchedFields ?? []);
    } else {
      _searchedFieldSuggestions.add([]);
    }
  }

  // Click handlers

  void onMapTap(LatLng latLng) {
    if (_mode.value == BtnsMode.measureArea ||
        _mode.value == BtnsMode.measureDistance) {
      _pins.add(latLng);

      _measurement.add(_calculateMeasurement());

      _updateMapData(
        pins: _createPins(),
        polygons: _createPolygons(),
        polylines: _createPolylines(),
      );
    }
  }

  Set<ModelMarker> _createPins() {
    final points = currentMode == BtnsMode.measureDistance && _pins.length > 2
        ? <LatLng>[_pins.first, _pins.last]
        : _pins;
    final pins = points.map((point) {
      final lat = point.latitude;
      final lng = point.longitude;
      return ModelMarker(
        id: "markerId-pin-${_pins.length}-$lat-$lng",
        latLng: LatLng(lat, lng),
        hue: BitmapDescriptor.hueRed,
        // color: f.name,
      );
    });
    final set = pins.toSet();
    print("points: $points, pins: $pins, set: $set");
    return set;
  }

  void onMeasurementClick() {
    BtnsMode newMode = BtnsMode.measureArea;
    switch (_mode.value) {
      case BtnsMode.measureArea:
        newMode = BtnsMode.measureDistance;
        break;
      case BtnsMode.measureDistance:
        newMode = BtnsMode.none;
        _pins.clear();
        break;
    }
    _mode.add(newMode);

    if (newMode == BtnsMode.none) {
      _measurement.add(null);
      _updateMapData(
        pins: Set<ModelMarker>(),
        polygons: _createPolygons(),
        polylines: _createPolylines(),
      );
    } else {
      _measurement.add(_calculateMeasurement());
      _updateMapData(
        pins: _createPins(),
        polygons: _createPolygons(),
        polylines: _createPolylines(),
      );
    }
  }

  void onSelectSentenceClick() {
    final newMode = _mode.value == BtnsMode.createSentence
        ? BtnsMode.selectSentence
        : BtnsMode.createSentence;
    _mode.add(newMode);
  }

  Future onSendSentence(String sentenceName) async {
    final fieldIds = _fieldsGroup.map((fg) => fg.id).toList();
    await _api.setFields(sentenceName, fieldIds);
    _fieldsGroup.clear();
    _updateMapData(
      polygons: _createPolygons(),
    );
  }

  void onSearchFieldBtnClick() {
    final newMode =
        _mode.value == BtnsMode.search ? BtnsMode.none : BtnsMode.search;
    _mode.add(newMode);
    _searchedFieldSuggestions.add(null);
  }

  void onFountainsBtnClicked() {
    _updateMapData(showFountains: !_mapData.value.showFountains);
  }

  void onLabelsBtnClicked() {
    _updateMapData(showLabels: !_mapData.value.showLabels);
  }

  void onBackBtnClick() {
    _pins.removeLast();
    _measurement.add(_calculateMeasurement());
    _updateMapData(
      pins: _createPins(),
      polygons: _createPolygons(),
      polylines: _createPolylines(),
    );
  }

  void onSubmitComment(int fieldId, String text) async {
    final comment = await _api.createComment(fieldId, text);
    if (comment != null) {
      final comments = _fieldComments.value ?? [];
      _fieldComments.value = comments..add(comment);
    }
  }

  void onSentenceInboxClick() async {
    // final groups = await _api.fetchGroups();
    final groups = await _db.queryGroups();
    final filtered = groups.where((group) => group.name?.isNotEmpty == true).toList();
    _inboxGroups.value = filtered;
  }

  void handleSentence(List<int> fieldIds) async {
    final db = DbClient();
    _inboxFields.clear();
    final inboxFields = await db.queryFieldsIn(ids: fieldIds.toList()) ?? [];
    _inboxFields.addAll(inboxFields);

    final polygons = _createPolygons();
    _updateMapData(polygons: polygons);

    _updateBounds(_inboxFields);
  }

  void markCurrentPosition(LatLng latLng) {
    final marker = ModelMarker(
      id: "markerId-currentPosition",
      latLng: latLng,
      hue: BitmapDescriptor.hueRed,
      // color: f.name,
    );
    _updateMapData(
      currentPosition: marker,
    );
  }

  // private functions

  // calculates area in ha or distance in meters depending on the mode
  double _calculateMeasurement() {
    // TODO: optimization - pull the code from the library
    if (currentMode == BtnsMode.measureArea) {
      if (_pins.length > 2) {
        final areaSquareMeters = mt.SphericalUtil.computeArea(
            _pins.map((c) => mt.LatLng(c.latitude, c.longitude)).toList());
        final areaHa = areaSquareMeters / 10000;
        return areaHa;
      }
    } else {
      if (_pins.length > 1) {
        final distanceMeters = mt.SphericalUtil.computeLength(
            _pins.map((c) => mt.LatLng(c.latitude, c.longitude)).toList());
        return distanceMeters;
      }
    }
    return null;
  }

  Set<Polyline> _createPolylines() {
    if (currentMode == BtnsMode.measureDistance && _pins.length > 1) {
      final polyline = Polyline(
        polylineId: PolylineId("measurement"),
        width: 2,
        color: Colors.blue,
        points: _pins,
      );
      return Set.of([polyline]);
    } else {
      return Set<Polyline>();
    }
  }

  void _updateMapData({
    Set<ModelMarker> fountains,
    Set<ModelMarker> pins,
    Set<ModelMarker> labels,
    Set<Polygon> polygons,
    Set<Polyline> polylines,
    bool showFountains,
    bool showLabels,
    bool isSatelliteView,
    ModelMarker currentPosition,
  }) {
    final MapData mapData = _mapData.value;
    _mapData.value = mapData != null
        ? mapData.copyWith(
            fountains: fountains ?? mapData.fountains,
            pins: pins ?? mapData.pins,
            labels: labels ?? mapData.labels,
            polygons: polygons ?? mapData.polygons,
            polylines: polylines ?? mapData.polylines,
            showFountains: showFountains ?? mapData.showFountains,
            showLabels: showLabels ?? mapData.showLabels,
            isSatelliteView: isSatelliteView ?? mapData.isSatelliteView,
            currentPosition: currentPosition ?? mapData.currentPosition,
          )
        : MapData(
            fountains: fountains,
            pins: pins,
            labels: labels,
            polygons: polygons,
            polylines: polylines,
            showFountains: showFountains,
            showLabels: showLabels,
            isSatelliteView: isSatelliteView,
            currentPosition: currentPosition,
          );
  }

  Iterable<ModelMarker> _createFountainsMarkers(
    List<Fountain> fountains, {
    String id,
  }) {
    return fountains.map((f) {
      final lat = f.lat;
      final lng = f.lng;
      return ModelMarker(
        id: id ?? "markerId-$lat-$lng",
        title: f.name,
        latLng: LatLng(lat, lng),
        hue: BitmapDescriptor.hueBlue,
        // color: f.name,
      );
    });
  }

  Iterable<ModelMarker> _createLabelsMarkers(
      List<Field> fields, {
        String id,
      }) {
    return [
      for (Field f in fields)
        if (f.centroid != null) ModelMarker(
        id: id ?? "markerId-${f.centroid.lat}-${f.centroid.lng}",
        title: f.name,
        subTitle: "${f.areaSize}",
        latLng: LatLng(f.centroid.lat, f.centroid.lng),
        hue: BitmapDescriptor.hueBlue,
        // color: f.name,
      )
    ].toSet();
  }

  LatLngBounds _createBounds(List<LatLng> points) {
    if (points?.isEmpty == true) return null;
    final southwestLat = points.map((p) => p.latitude).reduce(
        (value, element) => value < element ? value : element); // smallest
    final southwestLon = points
        .map((p) => p.longitude)
        .reduce((value, element) => value < element ? value : element); // smallest
    final northeastLat = points.map((p) => p.latitude).reduce(
        (value, element) => value > element ? value : element); // biggest
    final northeastLon = points
        .map((p) => p.longitude)
        .reduce((value, element) => value > element ? value : element); // biggest
    return LatLngBounds(
        southwest: LatLng(southwestLat, southwestLon),
        northeast: LatLng(northeastLat, northeastLon));
  }

  Future _prepareData() async {
    final fields = await _db.queryFields();
    _fields.addAll(fields ?? []);
    final labels = _createLabelsMarkers(fields);
    final polygons = _createPolygons();
    final fountains = await _db.queryFountains();

    final markers = _mapData.value.fountains ?? Set<ModelMarker>();
    markers.addAll(_createFountainsMarkers(fountains));

    _updateMapData(
      fountains: markers,
      polygons: polygons,
      labels: labels,
    );
    _updateBounds(_fields);
  }

  Set<Polygon> _createPolygons() {
    final polygons = Set<Polygon>();
    final fields = _inboxFields.isNotEmpty ? _inboxFields : _fields;
    fields.forEach((field) {
      final points = <LatLng>[];
      field.coordinates?.forEach((c) {
        if (c.lat != null && c.lng != null) {
          points.add(LatLng(c.lat, c.lng));
        }
      });
      final color = _getColorFor(field);
      final polygon = Polygon(
        strokeWidth: 2,
        polygonId: PolygonId(field.id.toString()),
        fillColor: color.withAlpha(150),
        strokeColor: color,
        points: points,
        consumeTapEvents: currentMode != BtnsMode.measureArea &&
            currentMode != BtnsMode.measureDistance,
        onTap: () => _onFieldClick(field),
      );
      polygons.add(polygon);
    });

    // handle measurement polygon
    if (_pins.length > 2 && currentMode == BtnsMode.measureArea) {
      final polygon = Polygon(
        strokeWidth: 1,
        polygonId: PolygonId("measurement"),
        fillColor: Colors.redAccent.withAlpha(160),
        strokeColor: Colors.black,
        points: _pins,
      );
      polygons.updateWhere(
          Set.of([polygon]), (o, n) => o.polygonId == n.polygonId);
    } else {
      polygons.removeWhere((p) => p.polygonId.value == "measurement");
    }

    return polygons;
  }

  void _updateBounds(Iterable<Field> fields) {
    final coordinates = fields
        .expand(
            (f) => f.coordinates.map((c) => LatLng(c.lat, c.lng)))
        .toList();
    final bounds = _createBounds(coordinates);
    // update bounds
    _bounds.add(bounds);
  }

  // onPolygonPress
  Future _onFieldClick(Field field) async {
    if (currentMode != BtnsMode.measureArea) {
      _fieldComments.value = [];

      void _updateFields() {
        final polygons = _createPolygons();
        _updateMapData(polygons: polygons);
      }

      if (currentMode != BtnsMode.createSentence) {
        _fieldInfo.add(field);
        _updateFields();

        final comments = await _api.fetchComments(field.id);
        _fieldComments.value = comments;
      } else {
        _fieldInfo.add(null);
        // grouping == true
        if (_fieldsGroup.contains(field)) {
          _fieldsGroup.remove(field);
        } else {
          _fieldsGroup.add(field);
        }
        _updateFields();
      }
    }
  }

  Color _getColorFor(field) {
    Color color = Colors.green;
    if (_searchedFields.contains(field)) {
      color = Colors.orange;
    }
    if (_inboxFields.contains(field) == true) {
      color = Colors.purple;
    }
    if (_fieldInfo.value == field || _fieldsGroup.contains(field)) {
      color = Colors.red;
    }

    return color;
  }

  void switchMapType() {
    _updateMapData(isSatelliteView: !_mapData.value.isSatelliteView);
  }

  Future onRefreshBtnClicked() async {
    _isLoading.add(true);

    try {
      final response = await _api.fetchObjects();
      await Prefs.saveLastUpdate(await DateFormatter.getTimeStringAsync());
  
      await _db.insertFountains(response.fountains.toList());
      await _db.insertFields(response.fields.toList());
      await _db.insertGroups(response.groups.toList());
  
      await _prepareData();
    } catch (e) {
      print("onRefreshBtnClicked: $e");
    } finally {
      _isLoading.add(false);
    }
  }
}
