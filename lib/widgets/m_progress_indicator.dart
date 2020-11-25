import 'package:flutter/material.dart';

class MProgressIndicator extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Container(
			height: 4,
			child: LinearProgressIndicator(),
		);
	}
}