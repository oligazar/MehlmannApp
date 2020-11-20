import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/blocs/bloc_map.dart';
import 'package:mahlmann_app/common/functions.dart';
import 'package:mahlmann_app/common/lang/m_localizations.dart';
import 'package:mahlmann_app/common/map_opener.dart';
import 'package:mahlmann_app/models/built_value/btns_mode.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/map/map_data.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';
import 'package:mahlmann_app/widgets/button_mahlmann.dart';
import 'package:mahlmann_app/widgets/mahlmann_dialog.dart';
import 'package:mahlmann_app/widgets/search_box.dart';
import 'package:provider/provider.dart';
import 'package:mahlmann_app/common/extensions.dart';

class ScreenMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<BlocMap>(
      create: (context) => BlocMap(),
      dispose: (context, value) => value.dispose(),
      child: ViewMap(),
      lazy: false,
    );
  }
}

class ViewMap extends StatefulWidget {
  final bool isLoading;
  final bool hasError;

  const ViewMap({
    Key key,
    this.isLoading,
    this.hasError,
  }) : super(key: key);

  @override
  State<ViewMap> createState() => ViewMapState();
}

class ViewMapState extends State<ViewMap> {
  Completer<GoogleMapController> _controller = Completer();
  StreamSubscription _mapDataSubscription;
  BitmapDescriptor iconDrop;
  StreamSubscription<Field> _fieldInfoSubscription;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  BlocMap get bloc => context.provide<BlocMap>();

  MLocalizations get loc => context.loc;

  @override
  void initState() {
    BitmapDescriptor.fromAssetImage(
            ImageConfiguration(devicePixelRatio: 2.5), 'assets/images/drop.png')
        .then((bitmap) {
      iconDrop = bitmap;
    });
    _fieldInfoSubscription = bloc.fieldInfo.listen((field) {
      if (field != null) {
        _showInfoDialog(field);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<MapData>(
          stream: bloc.mapData,
          builder: (context, snapshot) {
            final mapData = snapshot?.data;
            return Stack(
              children: [
                GoogleMap(
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  polygons: mapData?.polygons,
                  markers: _buildAllMarkers(mapData?.fountains, mapData?.pins,
                      mapData?.showFountains),
                  initialCameraPosition: _kGooglePlex,
                  onMapCreated: _onMapCreated,
                  onTap: bloc.onMapTap,
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: StreamBuilder<BtnsMode>(
                      stream: bloc.mode,
                      builder: (context, snapshot) {
                        final mode = snapshot.data;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 44),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ButtonMahlmann(
                                    onPressed: bloc.onMeasurementClick,
                                    text: mode == BtnsMode.measurement
                                        ? loc.stopMeasurement
                                        : loc.startMeasurement,
                                  ),
                                  ButtonMahlmann(
                                    onPressed: bloc.onSelectSentenceClick,
                                    text: mode == BtnsMode.selectSentence
                                        ? loc.selectSentence
                                        : loc.createSentence,
                                  ),
                                  ButtonMahlmann(
                                    onPressed: bloc.onSearchFieldClick,
                                    text: loc.searchField,
                                  ),
                                  ButtonMahlmann(
                                    onPressed: () {},
                                    text: loc.setInbox,
                                  ),
                                  ButtonMahlmann(
                                    onPressed: () {},
                                    text: loc.logOut,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: mode == BtnsMode.search
                                  ? SearchBox(onChanged: (query) {
                                      bloc.onFieldsQuery(query);
                                    })
                                  : Container(),
                            ),
                          ],
                        );
                      }),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ButtonMahlmann(
                          onPressed: _goToCurrentPosition,
                          text: loc.currentPosition,
                        ),
                        ButtonMahlmann(
                          onPressed: bloc.onFountainsBtnClicked,
                          text: mapData?.showFountains != false
                              ? loc.fountainOff
                              : loc.fountainOn,
                        ),
                        StreamBuilder<double>(
                            stream: bloc.area,
                            builder: (context, snapshot) {
                              final area = snapshot.data;
                              return area != null
                                  ? ButtonMahlmann(
                                      onPressed: () {},
                                      text: "${area.toStringAsFixed(2)} ha",
                                    )
                                  : Container(height: 0);
                            }),
                        mapData?.pins?.isNotEmpty == true
                            ? ButtonMahlmann(
                                onPressed: bloc.onBackBtnClick,
                                text: loc.back,
                              )
                            : Container(height: 0),
                      ],
                    ),
                  ),
                )
              ],
            );
          }),
    );
  }

  @override
  dispose() async {
    super.dispose();
    _mapDataSubscription?.cancel();
    _fieldInfoSubscription?.cancel();
  }

  _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
    _mapDataSubscription = bloc.bounds.listen((data) async {
      if (data != null) {
        await _zoomFitBounds(data);
      }
    });
  }

  Future<void> _goToCurrentPosition() async {
    // TODO: handle permissions before trying this !!!
    final GoogleMapController controller = await _controller.future;
    controller
        .animateCamera(CameraUpdate.newLatLngZoom(await currentLocation, 12.8));
    // controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

  Future _zoomFitBounds(LatLngBounds bounds) async {
    await _controller.future.then((controller) {
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    });
  }

  Set<Marker> _buildAllMarkers(Iterable<ModelMarker> fountains,
      Iterable<ModelMarker> pins, bool showFountains) {
    final markers = Set<Marker>();
    if (showFountains != false && fountains?.isNotEmpty == true)
      markers.addAll(_buildMarkers(fountains));
    if (pins?.isNotEmpty == true)
      markers.addAll(_buildMarkers(pins, isFountain: false));
    return markers;
  }

  Set<Marker> _buildMarkers(Iterable<ModelMarker> models,
      {bool isFountain = true}) {
    print("_buildMarkers, models: $models");
    final markers = models?.map((model) {
          return Marker(
            markerId: MarkerId(model.id),
            position: model.latLng,
//                                infoWindow: InfoWindow(
//                                  title: "Hello"
//                                ),
            onTap: () async {
              final lat = model.latLng.latitude;
              final lng = model.latLng.longitude;
              print("Marker ${model.title}, lat: $lat, lng: $lng}");
              // final urls = MapOpener.buildMapUrls(
              //     location: LatLng(lat, lng));
              // if (await MapOpener.canOpen(urls)) {
              //   MapOpener.openMap(urls);
              // }
            },
            icon: isFountain
                ? iconDrop
                : BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
          );
        })?.toSet() ??
        Set<Marker>();
    return markers;
  }

  void _showInfoDialog(Field field) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => MahlmannDialog(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: DialogButton(
                title: loc.titleRoute,
                action: () {
                  final c = field.coordinates.firstOrNull;
                  if (c.latitude != null && c.longitude != null) {
                    final urls = MapOpener.buildMapUrls(location: LatLng(c.latitude, c.longitude));
                    MapOpener.openMap(urls);
                  }
                  Navigator.of(context).pop();
                },
              ),
            ),
            InfoRow(loc.titleName, field.name),
            InfoRow(loc.titleStatus, field.status),
            InfoRow(loc.titleIsCabbage, field.isCabbage),
            InfoRow(loc.titleArea,
                field.areaSize != null ? "${field.areaSize.toStringAsFixed(2)} ha" : null),
            InfoRow(loc.titleComments, field.note),
            const SizedBox(height: 8),
	          TextField(
		          decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
			          border: OutlineInputBorder(),
			          hintText: loc.promptComment,
                hintStyle: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
                isCollapsed: true,
		          ),
	          )
          ],
        ),
        btnTitle: loc.titleClose,
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String name;
  final String value;

  const InfoRow(
    this.name,
    this.value, {
    Key key,
  })  : assert(name != null, "Name shouldn't be null"),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text("$name: ",
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 15,
            )),
        Text(value ?? "n/a", style: TextStyle(fontSize: 15)),
      ],
    );
  }
}
