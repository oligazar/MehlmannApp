import 'package:flutter/material.dart';

class MColors {
	MColors._();
	
	static Color primary = Color(0xffffda28).withRed(240).withGreen(210);
	static const Color primaryDark = const Color(0xffd5b621);
	static const Color white = Colors.white;
	static const Color black = Colors.black;
	static Color lightGrey = Colors.grey[300];
	static Color darkGrey = Colors.grey[500];
	static Color bgLightGrey = Colors.grey[200];
	static Color btnSend = primaryDark;
	
	static const Color settingUp = const Color(0xffaa66cc);
	static const Color washTime = const Color(0xffe42692);
	static const Color travelTime = const Color(0xff33b5e5);
	static const Color workTime = const Color(0xff99cc00);
	static const Color map = const Color(0xff348B1B);
	static const Color repairTime = const Color(0xffff4444);
	static const Color waitTime = const Color(0xffffbb33);
	static const Color refuelTime = const Color(0xffffbb33);
	static const Color otherTime = const Color(0xffff99ff);
	static const Color grey = const Color(0xffd0d0d0);
	static const Color breakTime = grey;
	static const Color stop = grey;
	static const Color leave = const Color(0xffff7043);
	
	static const Color driverInput = grey;
	static const Color mapFooterBg = const Color(0xbeffffff);
	static const Color mapFooterBgPressed = const Color(0xffffffff);
	static const Color colorFieldBorder = const Color(0xffff8800);
	static const Color colorField = const Color(0x2dff8929);
	static const double hueOrange = 45;
	static const double hueGreen = 105;
	static const double hueRed = 15;
}