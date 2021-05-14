import 'package:flutter/material.dart';

const leftSpace = 36.0;

class Preference extends StatelessWidget {
  final String title;
  final String subTitle;
  final Widget child;
  final Function onTap;
  final IconData icon;

  const Preference(
      {Key key,
      this.title = "",
      this.subTitle,
      this.child,
      this.onTap,
      this.icon})
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
                width: leftSpace,
                child: Center(
                  child: icon != null ? Icon(icon) : Container(),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
              SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }
}
