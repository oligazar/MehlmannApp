import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/blocs/bloc_map.dart';
import 'package:mahlmann_app/common/functions.dart';
import 'package:mahlmann_app/common/lang/m_localizations.dart';
import 'package:mahlmann_app/models/map/map_data.dart';
import 'package:mahlmann_app/widgets/button_mahlmann.dart';
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

  var _searchBoxUpdater = ValueNotifier<bool>(false);

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static final CameraPosition _kLake = CameraPosition(
      // bearing: 192.8334901395799,
      target: LatLng(37.43296265331129, -122.08832357078792),
      // tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  BlocMap get bloc => context.provide<BlocMap>();

  MLocalizations get loc => context.loc;

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
                    initialCameraPosition: _kGooglePlex,
                    onMapCreated: _onMapCreated),
                Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTopButtons(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: ValueListenableBuilder<bool>(
                            valueListenable: _searchBoxUpdater,
                            builder: (context, showSearchBar, child) {
                              return showSearchBar
                                  ? SearchBox(onChanged: (query) {
                                      bloc.onFieldsQuery(query);
                                      _searchBoxUpdater.value = false;
                                    })
                                  : Container();
                            }),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildBottomButtons(),
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

  Widget _buildTopButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 44),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ButtonMahlmann(
            onPressed: () => {},
            text: loc.startMeasurement,
          ),
          const SizedBox(width: 8),
          ButtonMahlmann(
            onPressed: () {
              _searchBoxUpdater.value = !_searchBoxUpdater.value;
            },
            text: loc.searchField,
          ),
          const SizedBox(width: 8),
          ButtonMahlmann(
            onPressed: () => {},
            text: loc.setInbox,
          ),
          const SizedBox(width: 8),
          ButtonMahlmann(
            onPressed: () => {},
            text: loc.logOut,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ButtonMahlmann(
            onPressed: _goToCurrentPosition,
            text: loc.currentPosition,
          ),
          const SizedBox(width: 8),
          ButtonMahlmann(
            onPressed: () => {},
            text: loc.fountain,
          ),
        ],
      ),
    );
  }
}
