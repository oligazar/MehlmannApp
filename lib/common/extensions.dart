import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mahlmann_app/common/lang/m_localizations.dart';
import 'package:provider/provider.dart';

extension ContextUtils on BuildContext {
	
	MLocalizations get loc => MLocalizations.of(this);
	
	T provide<T>() => Provider.of<T>(this, listen: false);
	
	void showSnackBar(Widget content,
			{Duration duration = const Duration(milliseconds: 500)}) {
		ScaffoldMessenger.of(this).showSnackBar(SnackBar(
			content: content,
			duration: duration,
		));
	}
}