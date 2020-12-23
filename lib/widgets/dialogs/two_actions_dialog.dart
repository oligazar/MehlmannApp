import 'package:flutter/material.dart';
import 'package:mahlmann_app/widgets/dialogs/m_dialog.dart';

class TwoActionsDialog extends StatelessWidget {
	final String title;
	final String message;
	final String btnOkTitle;
	final Function okAction;
	final String btnCancelTitle;
	final Function cancelAction;
	final Widget child;
	final _padding = 20.0;
	
	const TwoActionsDialog({
		Key key,
		this.title,
		this.message,
		this.btnOkTitle,
		this.okAction,
		this.btnCancelTitle,
		this.cancelAction, this.child
	}) : super(key: key);
	
	@override
	Widget build(BuildContext context) {
		return AlertDialog(
			contentPadding: EdgeInsets.only(top: _padding),
			content: SingleChildScrollView(
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: <Widget>[
						Padding(
							padding: EdgeInsets.symmetric(horizontal: _padding),
							child: Text(title,
								style: TextStyle(
									color: Colors.black,
									fontSize: 20,
									fontWeight: FontWeight.w600,
								),
								textAlign: TextAlign.center,
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
						Row(
							mainAxisAlignment: MainAxisAlignment.end,
							children: <Widget>[
								DialogButton(
									title: btnCancelTitle,
									action: () {
										if (cancelAction != null) {
											cancelAction();
										} else {
											Navigator.of(context).pop();
//										Navigator.of(context, rootNavigator: true).pop('dialog');
										}
									},
								),
								DialogButton(
									title:btnOkTitle,
									action: () {
										if (okAction != null) {
											okAction();
										} else {
											Navigator.of(context).pop();
										}
									},
								),
							],
						)
					],
				),
			),
		);
	}
}