import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';

class MapData {
	Set<ModelMarker> markers;
	Set<Polygon> polygons;
	bool isZoomed;
	
	MapData({
		this.markers,
		this.polygons,
		this.isZoomed,
	});
	
	MapData copyWith({
		Set<ModelMarker> markers,
		Set<Polygon> polygons,
		bool isZoomed
	}) {
		return MapData(
			markers: markers ?? this.markers,
			polygons: polygons ?? this.polygons,
			isZoomed: isZoomed ?? this.isZoomed,
		);
	}
	
	
}