import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';

class MapData {
	Set<ModelMarker> fountains;
	Set<ModelMarker> pins;
	Set<Polygon> polygons;
	Set<Polygon> measurement;
	Set<Polyline> polylines;
	bool showFountains;
	bool isSatelliteView;
	ModelMarker currentPosition;
	
	MapData({
		this.fountains,
		this.pins,
		this.polygons,
		this.measurement,
		this.polylines,
		this.showFountains = true,
		this.isSatelliteView = false,
		this.currentPosition,
	});
	
	MapData copyWith({
		Set<ModelMarker> fountains,
		Set<ModelMarker> pins,
		Set<Polygon> polygons,
		Set<Polygon> measurement,
		Set<Polyline> polylines,
		bool showFountains,
		bool isSatelliteView,
		ModelMarker currentPosition,
	}) {
		return MapData(
			fountains: fountains ?? this.fountains,
			pins: pins ?? this.pins,
			polygons: polygons ?? this.polygons,
			measurement: measurement ?? this.measurement,
			polylines: polylines ?? this.polylines,
			showFountains: showFountains ?? this.showFountains,
			isSatelliteView: isSatelliteView ?? this.isSatelliteView,
			currentPosition: currentPosition ?? this.currentPosition,
		);
	}
	
	
}