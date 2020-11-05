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
    return SizedBox(
      child: FlatButton(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        onPressed: () => {},
        child: Container(
          child: Align(
            alignment: Alignment.topCenter,
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 12
              ),
            ),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white.withAlpha(160),
      ),
      width: 50,
      height: 86,
    );
  }
}
