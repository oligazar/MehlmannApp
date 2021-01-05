import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cluster_builder/cluster_builder.dart';

class ModelMarker extends IconizedClusterable {
	final String id;
	final String title;
	final String subTitle;
	final String desc;
	final LatLng latLng;
	final double hue;
	final MarkerColors color;
	BitmapDescriptor icon;

	ModelMarker({
		@required this.id,
		this.title,
		this.subTitle,
		this.desc,
		@required this.latLng,
		this.hue,
		this.color = MarkerColors.green,
		this.icon,
		isCluster = false,
		clusterId,
		pointsSize,
		childMarkerId,
	})  : assert(id != null),
				super(
					markerId: id,
					latitude: latLng.latitude,
					longitude: latLng.longitude,
					isCluster: isCluster,
					clusterId: clusterId,
					pointsSize: pointsSize,
					childMarkerId: childMarkerId,
					equatable: CompositionEquatable([id, title, subTitle, desc]));

	Marker toMarker() => Marker(
		markerId: MarkerId(id),
		position: LatLng(
			latLng.latitude,
			latLng.longitude,
		),
		icon: icon ?? hue != null ? BitmapDescriptor.defaultMarkerWithHue(hue) : BitmapDescriptor.defaultMarker,
	);
	
	Widget toLabelMarker() => LabelMarker(
		title,
		subTitle,
		desc,
		color: Color(0xffaa66cc),
	);
}

class LabelMarker extends StatelessWidget {
	final String name;
	final String area;
	final String desc;
	final Color color;
	final IconData icon;
	
	const LabelMarker(
			this.name,
			this.area,
			this.desc, {
				this.icon,
				this.color,
				Key key,
			}) : super(key: key);
	
	@override
	Widget build(BuildContext context) {
		return ConstrainedBox(
			constraints: BoxConstraints(
				minWidth: 20,
				minHeight: 24,
				maxWidth: 300,
			),
			child: Column(
				mainAxisSize: MainAxisSize.min,
				crossAxisAlignment: CrossAxisAlignment.center,
				children: <Widget>[
					Flexible(
						child: NotNullBuilder(
							value: name,
							builder: (context, title) => Text(
								title,
								style: TextStyle(fontSize: 14, color: Colors.black),
							),
						),
					),
					Flexible(
						child: NotNullBuilder(
							value: name,
							builder: (context, title) => Text(
								"($area h)",
								style: TextStyle(fontSize: 14, color: Colors.black),
							),
						),
					)
				],
			),
		);
	}
}

class NotNullBuilder<T> extends StatelessWidget {
	final T value;
	final Widget Function(BuildContext, T) builder;
	
	const NotNullBuilder({Key key, this.value, this.builder}) : super(key: key);
	
	@override
	Widget build(BuildContext context) {
		return value != null && builder != null
				? builder(context, value)
				: Container(width: 0,);
	}
}

class TrianglePointer extends CustomPainter {
	final Color color;
	
	TrianglePointer(this.color);
	
	@override
	void paint(Canvas canvas, Size size) {
		var paint = Paint()..color = this.color;
		
		var path = Path();
		path.lineTo(7, 0);
		path.lineTo(0, 9);
		path.lineTo(-7, 0);
		canvas.drawPath(path, paint);
	}
	
	@override
	bool shouldRepaint(CustomPainter oldDelegate) {
		return true;
	}
}

enum MarkerColors {
	green,
	orange,
	red,
	settingUp,
	washTime,
	travelTime,
	workTime,
	repairTime,
	waitTime,
	leave,
	otherTime,
	grey,
}