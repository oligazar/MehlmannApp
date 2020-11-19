import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/common/interfaces/disposable.dart';
import 'package:mahlmann_app/common/sqlite/sqlite_client.dart';
import 'package:mahlmann_app/models/built_value/btns_mode.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/built_value/fountain.dart';
import 'package:mahlmann_app/models/map/map_data.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;
import 'package:rxdart/rxdart.dart' as rx;

class BlocMap extends Disposable {
  final _db = SqliteClient();
  final _mapData = rx.BehaviorSubject<MapData>.seeded(MapData());
  final _bounds = rx.BehaviorSubject<LatLngBounds>();
  final _area = rx.BehaviorSubject<double>();
  final _mode = rx.BehaviorSubject<BtnsMode>.seeded(BtnsMode.none);

  Stream<MapData> get mapData => _mapData.stream;

  Stream<LatLngBounds> get bounds => _bounds.stream;

  Stream<double> get area => _area.stream;

  Stream<BtnsMode> get mode => _mode.stream;

  // BtnsMode get currentMode => _mode.value;

  BlocMap() {
    _prepareData();
  }

  void onFieldsQuery(String query) async {
    // _customers.search(query);
    _mode.add(BtnsMode.none);
    print("query: $query");

    // mark fields as selected
    // search fields that match the input (contains)
    final matchedFields = await _db.queryFields(query: query);
    final matchedPolygons = _createPolygons(matchedFields, isSelected: true);
    _updatePolygons(matchedPolygons);

    // create bounds
    final coordinates = matchedFields
        .expand(
            (f) => f.coordinates.map((c) => LatLng(c.latitude, c.longitude)))
        .toList();
    final bounds = _createBounds(coordinates);
    // update bounds
    _bounds.add(bounds);
  }

  @override
  void dispose() {
    _mapData.close();
    _bounds.close();
    _area.close();
    _mode.close();
  }

  Future _prepareData() async {
    final fields = await _db.queryFields();
    final polygons = _createPolygons(fields);
    final fountains = await _db.queryFountains();

    final markers = _mapData.value.markers ?? Set<ModelMarker>();
    markers.addAll(_createFountainsMarkers(fountains));

    _updateMapData(
      // markers: markers,
      polygons: polygons,
    );
  }

  Set<Polygon> _createPolygons(
    List<Field> fields, {
    isSelected = false,
  }) {
    final polygons = Set<Polygon>();
    fields.forEach((field) {
      final points = <LatLng>[];
      field.coordinates?.forEach((c) {
        if (c.latitude != null && c.longitude != null) {
          points.add(LatLng(c.latitude, c.longitude));
        }
      });
      final polygon = Polygon(
          strokeWidth: 2,
          polygonId: PolygonId(field.id.toString()),
          fillColor: isSelected ? Colors.redAccent : Colors.lightGreen,
          strokeColor: isSelected ? Colors.red : Colors.green,
          points: points,
          consumeTapEvents: true,
          onTap: () {
            final matchedPolygons = _createPolygons([field], isSelected: true);
            _updatePolygons(matchedPolygons);
          });
      polygons.add(polygon);
    });
    return polygons;
  }

  void _updatePolygons(Set<Polygon> newPolygons) {
    final polygons = _mapData.value.polygons ?? Set<Polygon>();
    polygons.addAll(newPolygons);
    _updateMapData(polygons: polygons);
  }

  void setIsZoomed(bool isZoomed) {
    _updateMapData(isZoomed: isZoomed);
  }

  void _updateMapData({
    Set<ModelMarker> markers,
    Set<Polygon> polygons,
    bool isZoomed,
  }) {
    final MapData mapData = _mapData.value;
    _mapData.value = mapData != null
        ? mapData.copyWith(
            markers: markers ?? mapData.markers,
            polygons: polygons ?? mapData.polygons,
            isZoomed: isZoomed ?? mapData.isZoomed)
        : MapData(markers: markers, polygons: polygons, isZoomed: isZoomed);
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

  LatLngBounds _createBounds(List<LatLng> positions) {
    if (positions?.isEmpty == true) return null;
    final southwestLat = positions.map((p) => p.latitude).reduce(
        (value, element) => value < element ? value : element); // smallest
    final southwestLon = positions
        .map((p) => p.longitude)
        .reduce((value, element) => value < element ? value : element);
    final northeastLat = positions.map((p) => p.latitude).reduce(
        (value, element) => value > element ? value : element); // biggest
    final northeastLon = positions
        .map((p) => p.longitude)
        .reduce((value, element) => value > element ? value : element);
    return LatLngBounds(
        southwest: LatLng(southwestLat, southwestLon),
        northeast: LatLng(northeastLat, northeastLon));
  }

  // static ModelMarker createMarker(
  //     {String title,
  //       String snippet,
  //       double lat,
  //       double lng,
  //       MarkerColors color,
  //       String id,
  //       Function onTap}) =>
  //     ModelMarker(
  //       id: id ?? "markerId-$lat-$lng",
  //       latLng: LatLng(lat ?? 0, lng ?? 0),
  //       title: title,
  //       desc: snippet,
  //       color: color,
  //     );

  void onMapTap(LatLng latLng) {
    if (_mode.value != BtnsMode.measurement) return;
    // https://pub.dev/packages/maps_toolkit
    final markers = _mapData.value.markers ?? Set<ModelMarker>();
    final pinMarkers = markers.where((m) {
      return m.id.contains('pin');
    }).toList();
    final lat = latLng.latitude;
    final lng = latLng.longitude;
    final count = pinMarkers.length + 1;
    final marker = ModelMarker(
      id: "markerId-pin-$count-$lat-$lng",
      latLng: LatLng(lat, lng),
      hue: BitmapDescriptor.hueRed,
      // color: f.name,
    );
    final path = (pinMarkers..add(marker)).map((p) => p.latLng).toList();
    markers.addAll([marker]);
    _updateMapData(
      markers: markers,
      polygons: _handleMeasurement(path),
    );
  }

  Set<Polygon> _handleMeasurement(List<LatLng> path) {
    final polygons = _mapData.value.polygons ?? Set<Polygon>();
    if (path.length > 2) {
      // TODO: optimization - pull the code from the library
      // update _area
      final area = mt.SphericalUtil.computeArea(
          path.map((c) => mt.LatLng(c.latitude, c.longitude)).toList());
      _area.add(area);

      final polygon = Polygon(
        strokeWidth: 1,
        polygonId: PolygonId("measurement"),
        fillColor: Colors.redAccent.withAlpha(160),
        strokeColor: Colors.black,
        points: path,
      );
      polygons.updateWhere(Set.of([polygon]), (o, n) => o.polygonId == n.polygonId);
    } else {
      _area.add(null);
      polygons.removeWhere((p) => p.polygonId.value == "measurement");
    }

    return polygons;
  }

  void onBackBtnClick() {
    final markers = _mapData.value.markers ?? Set<ModelMarker>();
    final pinMarkers = markers.where((m) => m.id.contains('pin')).toSet();
    final count = pinMarkers.length;
    markers.removeWhere((m) => m.id.contains('pin-$count'));
    pinMarkers.removeWhere((m) => m.id.contains('pin-$count'));
    final path = pinMarkers.map((p) => p.latLng).toList();
    _updateMapData(
      markers: markers,
      polygons: _handleMeasurement(path),
    );
  }

  void onMeasurementClick() {
    final newMode = _mode.value == BtnsMode.measurement
        ? BtnsMode.none
        : BtnsMode.measurement;
    _mode.add(newMode);
    if (newMode == BtnsMode.none) {
      final markers = _mapData.value.markers ?? Set<ModelMarker>();
      markers.removeWhere((m) => m.id.contains('pin'));
      _updateMapData(
        markers: markers,
        polygons: _handleMeasurement([]),
      );
    }
  }

  void onSearchFieldClick() {
    final newMode =
        _mode.value == BtnsMode.search ? BtnsMode.none : BtnsMode.search;
    _mode.add(newMode);
  }
}
