import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/common/interfaces/disposable.dart';
import 'package:mahlmann_app/common/sqlite/sqlite_client.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/built_value/fountain.dart';
import 'package:mahlmann_app/models/map/map_data.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';
import 'package:rxdart/rxdart.dart' as rx;

class BlocMap extends Disposable {
  final _db = SqliteClient();
  final _mapData = rx.BehaviorSubject<MapData>.seeded(MapData());
  final _bounds = rx.BehaviorSubject<LatLngBounds>();

  Stream<MapData> get mapData => _mapData.stream;

  Stream<LatLngBounds> get bounds => _bounds.stream;

  BlocMap() {
    _prepareData();
  }

  void onFieldsQuery(String query) async {
    // _customers.search(query);
    print("query: $query");

    // react to keyboard click

    // search fields that match the input (contains)
    final matchedFields = await _db.queryFields(query: query);
    // mark fields as selected
    final polygons = _mapData.value.polygons ?? Set<Polygon>();
    final newPolygons = _createPolygons(matchedFields, isSelected: true);
    newPolygons.forEach((newPolygon) {
      polygons.removeWhere((p) => p.polygonId == newPolygon.polygonId);
      polygons.add(newPolygon);
    });
    // create bounds
    final coordinates = matchedFields.expand(
        (f) => f.coordinates.map((c) => LatLng(c.latitude, c.longitude))).toList();
    final bounds = _createBounds(coordinates);

    _updateMapData(
      polygons: polygons,
    );
    _bounds.add(bounds);
  }

  @override
  void dispose() {
    _mapData.close();
    _bounds.close();
  }

  Future _prepareData() async {
    final fields = await _db.queryFields();
    final polygons = _createPolygons(fields);
    final fountains = await _db.queryFountains();

    final newMarkers = <ModelMarker>[];
    final markers = _mapData.value.markers ?? Set<ModelMarker>();
    newMarkers.addAll(_createFountainsMarkers(fountains));

    newMarkers.forEach((newMarker) {
      if (newMarker.latLng.latitude != 0 && newMarker.latLng.longitude != 0) {
        markers.removeWhere((m) => m.id == newMarker.id);
        markers.add(newMarker);
      }
    });

    _updateMapData(
      markers: markers,
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
          points: points);
      polygons.add(polygon);
    });
    return polygons;
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
}
