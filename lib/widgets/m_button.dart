import 'package:flutter/material.dart';

class MButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final bool isEnabled;

  const MButton({
    Key key,
    this.icon,
    this.onPressed,
    this.isActive = true,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          child: Container(
            height: 48,
            width: 48,
            child: Icon(
              icon ?? Icons.ac_unit,
              color: isActive ? Colors.black.withAlpha(160) : Colors.black38,
            ),
          ),
        ),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 0,
            blurRadius: 2,
            offset: Offset(1, 2), // changes position of shadow
          ),
        ],
      ),
    );
  }
}
