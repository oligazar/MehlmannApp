import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mahlmann_app/common/interfaces/exception_handleable.dart';
import 'package:mahlmann_app/common/extensions.dart';

class ExceptionHandler<T extends ExceptionHandleable> extends StatefulWidget {
	final Function(Exception) onException;
	final Widget child;
	
	const ExceptionHandler({Key key, this.onException, this.child}) : super(key: key);
	
	@override
	ExceptionHandlerState<T> createState() => ExceptionHandlerState<T>();
}

class ExceptionHandlerState<T extends ExceptionHandleable> extends State<ExceptionHandler<T>> {
	StreamSubscription subscription;
	
	@override
	void didChangeDependencies() {
		super.didChangeDependencies();
		Stream stream = context.provide<T>().exception;
		subscription?.cancel();
		subscription = stream.listen((exception) {
			print("handling exception: $exception...");
			if (widget.onException != null) widget.onException(exception);
			else print("Exception catched: $exception");
		});
	}
	
	@override
	void dispose() {
		subscription?.cancel();
		super.dispose();
	}
	
	@override
	Widget build(BuildContext context) {
		return widget.child;
	}
}