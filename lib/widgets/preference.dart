import 'package:flutter/material.dart';

class Preference extends StatelessWidget {
	final String title;
	final String subTitle;
	final Widget child;
	final Function onTap;
	final IconData icon;
	
	const Preference({Key key, this.title = "", this.subTitle, this.child, this.onTap, this.icon})
			: super(key: key);
	
	@override
	Widget build(BuildContext context) {
		return Material(
			color: Colors.transparent,
			child: InkWell(
				onTap: onTap,
				child: Padding(
					padding: const EdgeInsets.symmetric(vertical: 16.0),
					child: Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: <Widget>[
							SizedBox(
								width: 72.0,
								child: Center(
									child: icon != null ? Icon(
											icon
									) : Container(),
								),
							),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: <Widget>[
										Text(
											title ?? "",
										),
										subTitle != null
												? Text(subTitle,
												style: TextStyle(color: Colors.black54))
												: Container(),
									],
								),
							),
							child ?? Container(),
						],
					),
				),
			),
		);
	}
}