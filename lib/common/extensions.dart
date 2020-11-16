import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mahlmann_app/common/lang/m_localizations.dart';
import 'package:provider/provider.dart';

extension ContextExt on BuildContext {
	
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

extension IterableExt<E> on Iterable<E> {
	
	E get firstOrNull {
		Iterator<E> it = iterator;
		if (!it.moveNext()) {
			return null;
		}
		return it.current;
	}
}

extension StringExt on String {
	
	int get toIntOrNull {
		try {
			return int.parse(this);
		} on FormatException {
			return null;
		}
	}
	
	bool get toBoolOrNull {
		if (this?.toLowerCase() == "true") return true;
		if (this?.toLowerCase() == "false") return false;
		return null;
	}
}