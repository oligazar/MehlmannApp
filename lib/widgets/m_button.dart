import 'package:flutter/material.dart';

class MButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const MButton({
    Key key,
    this.text,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        child: FlatButton(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          onPressed: onPressed,
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
          color: Colors.white.withAlpha(200),
        ),
        width: 50,
        height: 86,
      ),
    );
  }
}
