import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mahlmann_app/app_mahlmann.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/foundation.dart' show kDebugMode;

void main() async {
	WidgetsFlutterBinding.ensureInitialized();
	
  await Firebase.initializeApp();
  // if (kDebugMode) {
  //   await FirebaseCrashlytics.instance
  //       .setCrashlyticsCollectionEnabled(false);
  // }
	runZonedGuarded<Future<void>>(() async {
    runApp(AppMahlmann());
	}, FirebaseCrashlytics.instance.recordError);
}