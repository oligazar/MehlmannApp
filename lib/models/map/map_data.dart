import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';

class MapData {
	Set<ModelMarker> fountains;
	Set<Polygon> polygons;
	bool showFountains;
	
	MapData({
		this.fountains,
		this.polygons,
		this.showFountains = true,
	});
	
	MapData copyWith({
		Set<ModelMarker> markers,
		Set<Polygon> polygons,
		bool showFountains
	}) {
		return MapData(
			fountains: markers ?? this.fountains,
			polygons: polygons ?? this.polygons,
			showFountains: showFountains ?? this.showFountains,
		);
	}
	
	
}