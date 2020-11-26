import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mahlmann_app/common/extensions.dart';

class MDialog extends StatelessWidget {
  final String title;
  final String message;
  final String btnTitle;
  final Function action;
  final Widget child;
  final _padding = 10.0;

  MDialog({
    this.title,
    this.message,
    this.action,
    this.child,
    this.btnTitle,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.symmetric(vertical: _padding),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            child != null
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: _padding * 2),
                    child: child,
                  )
                : Container(),
            Align(
              alignment: Alignment.center,
              child: DialogButton(
                title: btnTitle,
                action: () {
                  if (this.action != null)
                    this.action();
                  else
                    Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DialogButton extends StatelessWidget {
  final String title;
  final Function action;

  const DialogButton({
    Key key,
    this.title,
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: Text(
        title ?? context.loc.btnOk,
        style: TextStyle(
          color: CupertinoColors.systemBlue,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
      ),
      onPressed: action,
    );
  }
}
