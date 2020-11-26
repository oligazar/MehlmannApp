import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';

class MapData {
	Set<ModelMarker> fountains;
	Set<ModelMarker> pins;
	Set<Polygon> polygons;
	Set<Polygon> measurement; // TODO: implement measurement separately
	bool showFountains;
	ModelMarker currentPosition;
	
	MapData({
		this.fountains,
		this.pins,
		this.polygons,
		this.showFountains = true,
		this.currentPosition,
	});
	
	MapData copyWith({
		Set<ModelMarker> fountains,
		Set<ModelMarker> pins,
		Set<Polygon> polygons,
		bool showFountains,
		ModelMarker currentPosition,
	}) {
		return MapData(
			fountains: fountains ?? this.fountains,
			pins: pins ?? this.pins,
			polygons: polygons ?? this.polygons,
			showFountains: showFountains ?? this.showFountains,
			currentPosition: currentPosition ?? this.currentPosition,
		);
	}
	
	
}