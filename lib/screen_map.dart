import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/widgets/button_mahlmann.dart';

class ScreenMap extends StatefulWidget {
  @override
  State<ScreenMap> createState() => ScreenMapState();
}

class ScreenMapState extends State<ScreenMap> {
  Completer<GoogleMapController> _controller = Completer();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static final CameraPosition _kLake = CameraPosition(
      // bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      // tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
              zoomControlsEnabled: false,
              mapType: MapType.normal,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              }),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 44),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ButtonMahlmann(
                    onPressed: () => {},
                    text: "Messung starten",
                  ),
                  const SizedBox(width: 8),
                  ButtonMahlmann(
                    onPressed: () => {},
                    text: "Felder suchen",
                  ),
                  const SizedBox(width: 8),
                  ButtonMahlmann(
                    onPressed: () => {},
                    text: "Satz Inbox",
                  ),
                  const SizedBox(width: 8),
                  ButtonMahlmann(
                    onPressed: () => {},
                    text: "Ausloggen",
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ButtonMahlmann(
                    onPressed: () => {},
                    text: "Aktuelle Position",
                  ),
                  const SizedBox(width: 8),
                  ButtonMahlmann(
                    onPressed: () => {},
                    text: "Brunnen an/aus",
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _goToTheLake,
      //   label: Text('To the lake!'),
      //   icon: Icon(Icons.directions_boat),
      // ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}
