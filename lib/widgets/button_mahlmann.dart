import 'package:flutter/material.dart';

class ButtonMahlmann extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const ButtonMahlmann({
    Key key,
    this.text,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: () => {},
      child: Text("Aktuelle Position"),
    );
  }
}
