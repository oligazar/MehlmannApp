import 'dart:async';

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info/package_info.dart';

Future<LatLng> get currentLocation async {
	LatLng currentLocation;
	try {
		print("currentLocation, beforeTime: $millis");
		final position = await Geolocator().getLastKnownPosition().timeout(const Duration(seconds: 3)) ??
				await Geolocator().getCurrentPosition().timeout(const Duration(seconds: 3));
		
		currentLocation = LatLng(position.latitude, position.longitude);
		
		print("currentLocation, afterTime: $millis, currentLocation: $currentLocation");
	} on PlatformException catch (e) {
		print("functions, currentLocation, exception: $e");
		if (e.code == 'PERMISSION_DENIED') {
			print('Permission denied');
		}
	} on TimeoutException catch (e) {
		print("functions, currentLocation, exception: $e");
	}
	return currentLocation;
}

Future<String> get buildVersion async =>
		PackageInfo.fromPlatform().then((i) => i.version);

int get millis => DateTime.now().millisecondsSinceEpoch;