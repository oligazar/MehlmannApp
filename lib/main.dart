import 'package:flutter/material.dart';
import 'package:mahlmann_app/app_mahlmann.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:mahlmann_app/screens/screen_map.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/foundation.dart' show kDebugMode;

void main() async {
  
  // if (kDebugMode) {
  //   await FirebaseCrashlytics.instance
  //       .setCrashlyticsCollectionEnabled(false);
  // }
	// runZonedGuarded<Future<void>>(() async {
  //   runApp(MyApp());
	// }, FirebaseCrashlytics.instance.recordError);
  
  runApp(AppMahlmann());
}