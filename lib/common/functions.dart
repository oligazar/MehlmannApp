import 'dart:async';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info/package_info.dart';
import 'package:location_permissions/location_permissions.dart';

Future<LatLng> get currentLocation async {
	Future<LatLng> getLocation() async {
		LatLng latLng;
		try {
			print("currentLocation, beforeTime: $millis");
			final position = await Geolocator.getCurrentPosition() ??
					await Geolocator.getLastKnownPosition();
			
			latLng = LatLng(position.latitude, position.longitude);
			
			print("currentLocation, afterTime: $millis, latLng: $latLng");
			// }
		} on PlatformException catch (e) {
			print("functions, currentLocation, exception: $e");
			if (e.code == 'PERMISSION_DENIED') {
				print('Permission denied');
			}
		} on TimeoutException catch (e) {
			print("functions, currentLocation, exception: $e");
		}
		return latLng;
	}
	LatLng location = await getLocation();
	final status = await Geolocator.checkPermission();
	if (location == null && status == LocationPermission.always) {
		location = await getLocation();
	}
	
	return location;
}

Future<String> get buildVersion async =>
		PackageInfo.fromPlatform().then((i) => i.version);

int get millis => DateTime.now().millisecondsSinceEpoch;

Future<bool> get isLocationEnabled async {
	final access = await LocationPermissions().checkPermissionStatus(level: LocationPermissionLevel.locationAlways);
	bool isAccessGranted = false;
	switch (access) {
		case PermissionStatus.unknown:
		case PermissionStatus.denied:
		case PermissionStatus.restricted:
			try {
				// here prominent disclosure should be shown
				final permission = await LocationPermissions().requestPermissions(
					permissionLevel: LocationPermissionLevel.locationAlways,
				);
				if (permission == PermissionStatus.granted) {
					isAccessGranted = true;
				}
			} catch (e) {
				// ERROR_ALREADY_REQUESTING_PERMISSION
				isAccessGranted = false;
			}
			break;
		case PermissionStatus.granted:
			isAccessGranted = true;
			break;
	}
	return isAccessGranted;
}