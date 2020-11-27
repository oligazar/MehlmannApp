import 'package:built_collection/src/list.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/common/api/api_client.dart';
import 'package:mahlmann_app/common/interfaces/disposable.dart';
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
  final _db = DbClient();
  final _api = ApiClient();
  final _mapData = rx.BehaviorSubject<MapData>.seeded(MapData());
  final _bounds = rx.BehaviorSubject<LatLngBounds>();
  final _area = rx.BehaviorSubject<double>();
  final _mode = rx.BehaviorSubject<BtnsMode>.seeded(BtnsMode.none);
  final _fieldInfo = rx.BehaviorSubject<Field>();
  final _fieldComments = rx.BehaviorSubject<List<Comment>>();
  final _inboxGroups = rx.BehaviorSubject<List<Group>>(); // purple

  final _fields = Set<Field>(); // orange
  final _searchedFields = Set<Field>(); // orange
  final _fieldsGroup = Set<Field>(); // red
  final _inboxFields = Set<Field>(); // red

  Stream<MapData> get mapData => _mapData.stream;

  Stream<LatLngBounds> get bounds => _bounds.stream;

  Stream<double> get area => _area.stream;

  Stream<BtnsMode> get mode => _mode.stream;

  Stream<List<Comment>> get fieldComments => _fieldComments.stream;
  
  Stream<List<Group>> get inboxGroups => _inboxGroups.stream;
  
  Stream<Field> get fieldInfo => _fieldInfo.stream;
  
  bool get hasFieldInfo => _fieldInfo.hasValue;

  BtnsMode get currentMode => _mode.value;

  BlocMap() {
    _prepareData();
  }

  @override
  void dispose() {
    _mapData.close();
    _bounds.close();
    _area.close();
    _mode.close();
    _fieldInfo.close();
    _fieldComments.close();
    _inboxGroups.close();
  }

  void onFieldsQuery(String query) async {
    _mode.add(BtnsMode.none);
    print("query: $query");

    final searchedFields = await _db.queryFields(query: query);
    _searchedFields.addAll(searchedFields ?? []);

    final polygons = _createPolygons(_fields);
    _updateMapData(polygons: polygons);

    _updateBounds(searchedFields);
  }

  // Click handlers

  void onMapTap(LatLng latLng) {
    if (_mode.value != BtnsMode.measurement) return;
    // https://pub.dev/packages/maps_toolkit
    final pins = _mapData.value.pins ?? Set<ModelMarker>();
    final lat = latLng.latitude;
    final lng = latLng.longitude;
    final marker = ModelMarker(
      id: "markerId-pin-${pins.length + 1}-$lat-$lng",
      latLng: LatLng(lat, lng),
      hue: BitmapDescriptor.hueRed,
      // color: f.name,
    );
    pins.addAll([marker]);
    final path = (pins).map((p) => p.latLng).toList();
    _updateMapData(
      pins: pins,
      polygons: _handleMeasurement(path),
    );
  }

  void onMeasurementClick() {
    final newMode = _mode.value == BtnsMode.measurement
        ? BtnsMode.none
        : BtnsMode.measurement;
    _mode.add(newMode);
    
    
    if (newMode == BtnsMode.none) {
      _updateMapData(
        pins: Set<ModelMarker>(),
        polygons: _handleMeasurement([]),
      );
    } else {
      _updateMapData(
        polygons: _createPolygons(_fields),
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
      polygons: _createPolygons(_fields),
    );
  }

  void onSearchFieldClick() {
    final newMode =
        _mode.value == BtnsMode.search ? BtnsMode.none : BtnsMode.search;
    _mode.add(newMode);
  }

  void onFountainsBtnClicked() {
    _updateMapData(showFountains: !_mapData.value.showFountains);
  }

  void onBackBtnClick() {
    final pins = _mapData.value.pins ?? Set<ModelMarker>();
    pins.removeWhere((m) => m.id.contains('pin-${pins.length}'));
    final path = pins.map((p) => p.latLng).toList();
    _updateMapData(
      pins: pins,
      polygons: _handleMeasurement(path),
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
    final groups = await _api.fetchGroups();
    _inboxGroups.value = groups;
  }

  void handleSentence(BuiltList<int> fieldIds) async {
    final db = DbClient();
    _inboxFields.clear();
    _inboxFields.addAll(await db.queryFieldsIn(ids: fieldIds.toList()) ?? []);
    
    final polygons = _createPolygons(_fields);
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

  Set<Polygon> _handleMeasurement(List<LatLng> path) {
    final polygons = _createPolygons(_fields);
    if (path.length > 2) {
      // TODO: optimization - pull the code from the library
      // update _area
      final areaSquareMeters = mt.SphericalUtil.computeArea(
          path.map((c) => mt.LatLng(c.latitude, c.longitude)).toList());
      final areaHa = areaSquareMeters / 10000;
      _area.add(areaHa);

      final polygon = Polygon(
        strokeWidth: 1,
        polygonId: PolygonId("measurement"),
        fillColor: Colors.redAccent.withAlpha(160),
        strokeColor: Colors.black,
        points: path,
      );
      polygons.updateWhere(
          Set.of([polygon]), (o, n) => o.polygonId == n.polygonId);
    } else {
      _area.add(null);
      polygons.removeWhere((p) => p.polygonId.value == "measurement");
    }

    return polygons;
  }

  void _updateMapData({
    Set<ModelMarker> fountains,
    Set<ModelMarker> pins,
    Set<Polygon> polygons,
    bool showFountains,
    ModelMarker currentPosition,
  }) {
    final MapData mapData = _mapData.value;
    _mapData.value = mapData != null
        ? mapData.copyWith(
            fountains: fountains ?? mapData.fountains,
            pins: pins ?? mapData.pins,
            polygons: polygons ?? mapData.polygons,
            showFountains: showFountains ?? mapData.showFountains,
            currentPosition: currentPosition ?? mapData.currentPosition,
          )
        : MapData(
            fountains: fountains,
            pins: pins,
            polygons: polygons,
            showFountains: showFountains,
            currentPosition: currentPosition,
    );
  }

  Iterable<ModelMarker> _createFountainsMarkers(
    List<Fountain> fountains, {
    String id,
  }) {
    return fountains.map((f) {
      final lat = f.latitude;
      final lng = f.longitude;
      return ModelMarker(
        id: id ?? "markerId-$lat-$lng",
        title: f.name,
        latLng: LatLng(lat, lng),
        hue: BitmapDescriptor.hueBlue,
        // color: f.name,
      );
    });
  }

  LatLngBounds _createBounds(List<LatLng> points) {
    if (points?.isEmpty == true) return null;
    final southwestLat = points.map((p) => p.latitude).reduce(
        (value, element) => value < element ? value : element); // smallest
    final southwestLon = points
        .map((p) => p.longitude)
        .reduce((value, element) => value < element ? value : element);
    final northeastLat = points.map((p) => p.latitude).reduce(
        (value, element) => value > element ? value : element); // biggest
    final northeastLon = points
        .map((p) => p.longitude)
        .reduce((value, element) => value > element ? value : element);
    return LatLngBounds(
        southwest: LatLng(southwestLat, southwestLon),
        northeast: LatLng(northeastLat, northeastLon));
  }

  Future _prepareData() async {
    final fields = await _db.queryFields();
    _fields.addAll(fields ?? []);
    final polygons = _createPolygons(_fields);
    final fountains = await _db.queryFountains();

    final markers = _mapData.value.fountains ?? Set<ModelMarker>();
    markers.addAll(_createFountainsMarkers(fountains));

    _updateMapData(
      fountains: markers,
      polygons: polygons,
    );
    _updateBounds(_fields);
  }

  Set<Polygon> _createPolygons(Iterable<Field> fields) {
    final polygons = Set<Polygon>();
    fields.forEach((field) {
      final points = <LatLng>[];
      field.coordinates?.forEach((c) {
        if (c.latitude != null && c.longitude != null) {
          points.add(LatLng(c.latitude, c.longitude));
        }
      });
      final color = _getColorFor(field);
      final polygon = Polygon(
        strokeWidth: 2,
        polygonId: PolygonId(field.id.toString()),
        fillColor: color.withAlpha(150),
        strokeColor: color,
        points: points,
        consumeTapEvents: currentMode != BtnsMode.measurement,
        onTap: () => _onFieldClick(field),
      );
      polygons.add(polygon);
    });
    return polygons;
  }

  void _updateBounds(Iterable<Field> fields) {
    final coordinates = fields
        .expand(
            (f) => f.coordinates.map((c) => LatLng(c.latitude, c.longitude)))
        .toList();
    final bounds = _createBounds(coordinates);
    // update bounds
    _bounds.add(bounds);
  }

  // onPolygonPress
  Future _onFieldClick(Field field) async {
    if (currentMode != BtnsMode.measurement) {
      _fieldComments.value = [];

      void _updateFields() {
	      final polygons = _createPolygons(_fields);
	      _updateMapData(polygons: polygons);
      }
      
      if (currentMode != BtnsMode.createSentence) {
        _fieldInfo.add(field);
        _updateFields();
        //       		selectedRegion: field,
        //           showFieldWindow: true,
        //           showSetWindow: false,
        //           showSearchWindow: false,
        //           showInboxWindow: false,

        final comments = await _api.fetchComments(field.id);
        _fieldComments.value = comments;
      } else {
      	// grouping == true
        _fieldsGroup.add(field);
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
}
