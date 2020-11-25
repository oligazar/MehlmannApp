import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/app_mahlmann.dart';
import 'package:mahlmann_app/blocs/bloc_map.dart';
import 'package:mahlmann_app/common/functions.dart';
import 'package:mahlmann_app/common/lang/m_localizations.dart';
import 'package:mahlmann_app/common/prefs.dart';
import 'package:mahlmann_app/common/sqlite/db_client.dart';
import 'package:mahlmann_app/models/built_value/btns_mode.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/map/map_data.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';
import 'package:mahlmann_app/widgets/m_button.dart';
import 'package:mahlmann_app/widgets/field_info_dialog.dart';
import 'package:mahlmann_app/widgets/search_box.dart';
import 'package:mahlmann_app/widgets/select_sentence_dialog.dart';
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
    _fieldInfoSubscription = bloc.fieldInfo.listen((field) async {
      if (field != null) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => Provider.value(
            value: bloc,
            builder: (context, _) => FieldInfoDialog(field),
          ),
        );
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
                                  MButton(
                                    onPressed: bloc.onMeasurementClick,
                                    text: mode == BtnsMode.measurement
                                        ? loc.stopMeasurement
                                        : loc.startMeasurement,
                                  ),
                                  // TODO: selectedRegion && admin
                                  MButton(
                                    onPressed: _onSentenceBtnClick,
                                    text: mode == BtnsMode.createSentence
                                        ? loc.createSentence
                                        : loc.selectSentence,
                                  ),
                                  MButton(
                                    onPressed: bloc.onSearchFieldClick,
                                    text: loc.searchField,
                                  ),
                                  MButton(
                                    onPressed: () {},
                                    text: loc.setInbox,
                                  ),
                                  MButton(
                                    onPressed: _logOut,
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
                        MButton(
                          onPressed: _goToCurrentPosition,
                          text: loc.currentPosition,
                        ),
                        MButton(
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
                                  ? MButton(
                                      onPressed: () {},
                                      text: "${area.toStringAsFixed(2)} ha",
                                    )
                                  : Container(height: 0);
                            }),
                        mapData?.pins?.isNotEmpty == true
                            ? MButton(
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

  Future _logOut() async {
    await DbClient().clearAllTables();
    Prefs.logout();
    AppMahlmann.of(context).setIsAuthorized(false);
  }

  void _onSentenceBtnClick() async {
    // if (bloc.currentMode == BtnsMode.selectSentence) {
    // TODO: check what modes should exchange here
    bloc.onSelectSentenceClick();
    final sentenceName = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => SelectSentenceDialog(
        title: loc.sendSentence,
      ),
    );
    // shouldn't be there _fieldsGroup check first?
    if (sentenceName != null) {
      await bloc.onSendSentence(sentenceName);
      context.showSnackBar(Text(loc.msgSuccess));
    }
    // }
  }
}
