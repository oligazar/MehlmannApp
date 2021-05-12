import 'package:flutter/material.dart';
import 'package:mahlmann_app/common/m_colors.dart';
import 'package:mahlmann_app/screens/preferences/preference.dart';

class PreferenceGroup extends StatelessWidget {
	final IconData icon;
	final String title;
	final List<Widget> children;
	final bool showBorder;
	
	const PreferenceGroup({
		Key key,
		this.icon,
		this.title,
		this.children = const [],
		this.showBorder = true,
	}) : super(key: key);
	
	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: showBorder
					? BoxDecoration(
					border: Border(bottom: BorderSide(width: 1, color: MColors.lightGrey)))
					: null,
			child: Column(
				children: <Widget>[
					const SizedBox(
						height: 16,
					),
					Row(
						children: <Widget>[
							SizedBox(
								width: leftSpace,
								child: Icon(
									icon,
									color: Colors.green,
								),
							),
							Text(
								title,
								style: TextStyle(
										color: Colors.green, fontWeight: FontWeight.bold),
							),
							const SizedBox(
								height: 16,
							),
						],
					),
				]..addAll(children),
			),
		);
	}
}