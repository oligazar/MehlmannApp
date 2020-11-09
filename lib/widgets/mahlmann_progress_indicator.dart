import 'package:flutter/material.dart';

class MahlmannProgressIndicator extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Container(
			height: 4,
			child: LinearProgressIndicator(),
		);
	}
}