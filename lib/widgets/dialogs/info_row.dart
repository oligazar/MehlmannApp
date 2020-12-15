import 'package:flutter/material.dart';

class InfoRow extends StatelessWidget {
	final String name;
	final String value;
	
	const InfoRow(
			this.name,
			this.value, {
				Key key,
			})  : super(key: key);
	
	@override
	Widget build(BuildContext context) {
		return Row(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Text("${name ?? ""}: ",
						style: const TextStyle(
							color: Colors.black54,
							fontSize: 15,
						)),
				Flexible(child: Text(value ?? "n/a", style: TextStyle(fontSize: 15))),
			],
		);
	}
}