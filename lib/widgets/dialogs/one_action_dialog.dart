import 'package:flutter/material.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:mahlmann_app/widgets/dialogs/m_dialog.dart';

class OneActionDialog extends StatelessWidget {
	final String title;
	final String message;
	final String btnTitle;
	final Function action;
	final Widget child;
	final _padding = 20.0;
	
	OneActionDialog({
		this.title,
		this.message,
		this.action,
		this.child,
		this.btnTitle,
	});
	
	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			contentPadding: EdgeInsets.only(top: _padding),
			content: SingleChildScrollView(
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: <Widget>[
						Align(
							alignment: Alignment.topCenter,
						  child: Padding(
						  	padding: EdgeInsets.symmetric(horizontal: _padding),
						  	child: Text(
						  		this.title,
						  		style: TextStyle(
						  			color: Colors.black,
						  			fontSize: 22,
						  			fontWeight: FontWeight.w600,
						  		),
						  		textAlign: TextAlign.center,
						  	),
						  ),
						),
						Container(height: 6,),
						message != null ? Padding(
							padding: EdgeInsets.symmetric(horizontal: _padding),
							child: Text(
								this.message,
								style: TextStyle(
										color: Colors.black
								),
								textAlign: TextAlign.center,
							),
						) : Container(),
						Container(height: 20,),
						child != null ? Padding(
							padding: EdgeInsets.symmetric(horizontal: _padding),
							child: child,
						) : Container(),
						Align(
							alignment: Alignment.centerRight,
							child: DialogButton(
								title: btnTitle ?? context.loc.btnOk,
								action: () {
									if (this.action != null) this.action();
									else Navigator.of(context).pop();
								},
							),
						)
					],
				),
			),
		);
	}
}