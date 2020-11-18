import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ModelMarker /*extends IconizedClusterable*/ {
	final String id;
	final String title;
	final String subTitle;
	final String desc;
	final LatLng latLng;
	final double hue;
	// final MarkerColors color;
	BitmapDescriptor icon;

	ModelMarker({
		@required this.id,
		this.title,
		this.subTitle,
		this.desc,
		@required this.latLng,
		this.hue,
		// this.color = MarkerColors.green,
		this.icon,
		isCluster = false,
		clusterId,
		pointsSize,
		childMarkerId,
	})  : assert(id != null)/*,
				super(
					markerId: id,
					latitude: latLng.latitude,
					longitude: latLng.longitude,
					isCluster: isCluster,
					clusterId: clusterId,
					pointsSize: pointsSize,
					childMarkerId: childMarkerId,
					equatable: CompositionEquatable([title, subTitle, desc]))*/;

	Marker toMarker() => Marker(
		markerId: MarkerId(id),
		position: LatLng(
			latLng.latitude,
			latLng.longitude,
		),
		icon: icon ?? BitmapDescriptor.defaultMarker,
	);

	// Widget toTrackerMarker() => TrackerMarker(
	// 	title,
	// 	subTitle,
	// 	desc,
	// 	color: colorForMarkerColors(color),
	// );
}