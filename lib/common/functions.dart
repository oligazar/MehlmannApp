import 'dart:async';

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info/package_info.dart';

Future<LatLng> get currentLocation async {
	LatLng currentLocation;
//   Platform messages may fail, so we use a try/catch PlatformException.
	try {
		final beforeTime = DateTime.now().millisecondsSinceEpoch;
		print("currentLocation, beforeTime: $beforeTime");
		final position = await Geolocator().getLastKnownPosition().timeout(const Duration(seconds: 3)) ??
				await Geolocator().getCurrentPosition().timeout(const Duration(seconds: 3));
//    final position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//    final proprietaryLocation = await location.getLocation().timeout(const Duration(seconds: 4));
		
		currentLocation = LatLng(position.latitude, position.longitude);
		
		final afterTime = DateTime.now().millisecondsSinceEpoch;
		print("currentLocation, afterTime: $afterTime");
		print("currentLocation, currentLocation: $currentLocation");
	} on PlatformException catch (e) {
		print("functions, currentLocation, exception: $e");
		if (e.code == 'PERMISSION_DENIED') {
			print('Permission denied');
		}
		currentLocation = null;
	} on TimeoutException catch (e) {
		print("functions, currentLocation, exception: $e");
		currentLocation = null;
	}
	return currentLocation;
}

Future<String> get buildVersion async =>
		PackageInfo.fromPlatform().then((i) => i.version);