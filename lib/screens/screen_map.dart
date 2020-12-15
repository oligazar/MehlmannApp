import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/app_mahlmann.dart';
import 'package:mahlmann_app/blocs/bloc_map.dart';
import 'package:mahlmann_app/common/functions.dart';
import 'package:mahlmann_app/common/lang/m_localizations.dart';
import 'package:mahlmann_app/common/map_opener.dart';
import 'package:mahlmann_app/common/prefs.dart';
import 'package:mahlmann_app/common/sqlite/db_client.dart';
import 'package:mahlmann_app/models/built_value/btns_mode.dart';
import 'package:mahlmann_app/models/built_value/comment.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/built_value/fountain.dart';
import 'package:mahlmann_app/models/map/map_data.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';
import 'package:mahlmann_app/widgets/dialogs/m_dialog.dart';
import 'package:mahlmann_app/widgets/dialogs/sentence_inbox_dialog.dart';
import 'package:mahlmann_app/widgets/m_button.dart';
import 'package:mahlmann_app/widgets/dialogs/field_info_dialog.dart';
import 'package:mahlmann_app/widgets/m_text_field.dart';
import 'package:mahlmann_app/widgets/search_box.dart';
import 'package:mahlmann_app/widgets/dialogs/select_sentence_dialog.dart';
import 'package:provider/provider.dart';
import 'package:mahlmann_app/common/extensions.dart';

// drawing custom marker on the field: https://github.com/flutter/flutter/issues/26109
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
  StreamSubscription<Fountain> _fountainInfoSubscription;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  BlocMap get bloc => context.provide<BlocMap>();

  MLocalizations get loc => context.loc;

  @override
  void initState() {
    BitmapDescriptor.fromAssetImage(
      ImageConfiguration(
        // devicePixelRatio: 5,
        size: Size(12, 12),
      ),
      Platform.isIOS ? 'assets/images/drop_ios.png' : 'assets/images/drop.png',
    ).then((bitmap) {
      iconDrop = bitmap;
    });
    _fieldInfoSubscription = bloc.fieldInfo.listen((field) async {
      if (field != null) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => MDialog(
            child: StreamBuilder<List<Comment>>(
                stream: bloc.fieldComments,
                builder: (context, snapshot) {
                  final comments = snapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: DialogButton(
                          title: loc.route,
                          action: () {
                            final c = field.coordinates.firstOrNull;
                            if (c.latitude != null && c.longitude != null) {
                              final urls = MapOpener.buildMapUrls(
                                  location: LatLng(c.latitude, c.longitude));
                              MapOpener.openMap(urls);
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      InfoRow(loc.name, field.name),
                      InfoRow(loc.status, field.status),
                      InfoRow(loc.cabbage, field.isCabbage),
                      InfoRow(
                          loc.titleArea,
                          field.areaSize != null
                              ? "${field.areaSize.toStringAsFixed(2)} ha"
                              : null),
                      Text(loc.comments),
                      for (Comment c in comments) InfoRow(c.user, c.text),
                      const SizedBox(height: 8),
                      MTextField(
                        hint: loc.comment,
                        onSubmitted: (comment) {
                          // clear text field ???
                          bloc.onSubmitComment(field.id, comment);
                        },
                      ),
                    ],
                  );
                }),
            btnTitle: loc.close,
          ),
        );
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // FirebaseCrashlytics.instance.crash();
    return Scaffold(
      body: StreamBuilder<MapData>(
          stream: bloc.mapData,
          builder: (context, snapshot) {
            final mapData = snapshot?.data;
            return Stack(
              children: [
                GoogleMap(
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  polygons: mapData?.polygons,
                  polylines: mapData?.polylines,
                  markers: _buildAllMarkers(mapData),
                  initialCameraPosition: _kGooglePlex,
                  onMapCreated: _onMapCreated,
                  onTap: bloc.onMapTap,
                  mapType: mapData?.isSatelliteView == true
                      ? MapType.satellite
                      : MapType.normal,
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: StreamBuilder<BtnsMode>(
                        stream: bloc.mode,
                        builder: (context, snapshot) {
                          final mode = snapshot.data;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  MButton(
                                    onPressed: bloc.onMeasurementClick,
                                    icon: mode == BtnsMode.measureDistance
                                        ? Icons.straighten
                                        : Icons.square_foot,
                                    isActive: mode == BtnsMode.measureArea ||
                                        mode == BtnsMode.measureDistance,
                                  ),
                                  FutureBuilder<bool>(
                                      future: Prefs.getLoginResponse()
                                          .then((r) => r.admin),
                                      builder: (context, snapshot) {
                                        final isAdmin = snapshot.data == true;
                                        return isAdmin && bloc.hasFieldInfo
                                            ? MButton(
                                                onPressed: _onSentenceBtnClick,
                                                icon: mode ==
                                                        BtnsMode.createSentence
                                                    ? Icons.add
                                                    : Icons.edit,
                                                // ? loc.createSentence
                                                // : loc.selectSentence,
                                              )
                                            : Container();
                                      }),
                                  MButton(
                                    onPressed: bloc.onSearchFieldBtnClick,
                                    icon: Icons.search,
                                    isActive: mode != BtnsMode.search,
                                  ),
                                  MButton(
                                      onPressed: _onSentenceInboxClick,
                                      icon: Icons.move_to_inbox),
                                  MButton(
                                      onPressed: _logOut,
                                      icon: Icons.power_settings_new),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: mode == BtnsMode.search
                                    ? SearchBox(
                                        onSubmitted:
                                            bloc.onFieldsQuerySubmitted,
                                        onChanged: bloc.onFieldsQueryChanged,
                                        child: StreamBuilder<List<Field>>(
                                          stream: bloc.searchedFieldSuggestions,
                                          builder: (context, snapshot) {
                                            final fields = snapshot.data ?? [];
                                            return SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  for (Field field in fields)
                                                    SearchSuggestionItem(
                                                      field: field,
                                                      onSelected: bloc
                                                          .onSuggestionFieldClick,
                                                    )
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Container(),
                              ),
                            ],
                          );
                        }),
                  ),
                ),
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StreamBuilder<double>(
                            stream: bloc.measurement,
                            builder: (context, snapshot) {
                              final measurement = snapshot.data;
                              if (measurement != null) {
                                final mString =
                                    bloc.currentMode == BtnsMode.measureArea
                                        ? "${measurement.toStringAsFixed(2)} ha"
                                        : "${measurement.toStringAsFixed(2)} m";
                                return Text(mString);
                              } else {
                                return Container(height: 0);
                              }
                            }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MButton(
                              onPressed: bloc.switchMapType,
                              icon: Icons.map,
                              isActive: mapData?.isSatelliteView == true,
                            ),
                            MButton(
                              onPressed: _goToCurrentPosition,
                              icon: Icons.location_on,
                            ),
                            MButton(
                              onPressed: bloc.onFountainsBtnClicked,
                              isActive: mapData?.showFountains != false,
                              icon: Icons.invert_colors,
                            ),
                            mapData?.pins?.isNotEmpty == true
                                ? MButton(
                                    onPressed: bloc.onBackBtnClick,
                                    // text: loc.back,
                                    icon: Icons.undo)
                                : Container(height: 0),
                          ],
                        ),
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
    _fountainInfoSubscription?.cancel();
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
    final location = await currentLocation;
    if (location != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(location, 12.8));
      // controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
      bloc.markCurrentPosition(location);
    }
  }

  Future _zoomFitBounds(LatLngBounds bounds) async {
    await _controller.future.then((controller) {
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    });
  }

  Set<Marker> _buildAllMarkers(MapData data) {
    final markers = Set<Marker>();
    if (data?.showFountains != false && data?.fountains?.isNotEmpty == true)
      markers.addAll(_buildMarkers(data.fountains));
    if (data?.pins?.isNotEmpty == true)
      markers.addAll(_buildMarkers(data.pins, isFountain: false));
    if (data?.currentPosition != null)
      markers.addAll(_buildMarkers([data.currentPosition], isFountain: false));
    return markers;
  }

  Set<Marker> _buildMarkers(
    Iterable<ModelMarker> models, {
    bool isFountain = true,
  }) {
    // print("_buildMarkers, models: $models");
    final markers = models?.map((model) {
          return Marker(
            markerId: MarkerId(model.id),
            position: model.latLng,
            onTap: () async {
              if (isFountain && model != null) {
                await showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) => MDialog(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: DialogButton(
                            title: loc.route,
                            action: () {
                              final c = model.latLng;
                              if (c.latitude != null && c.longitude != null) {
                                _openMap(
                                  model.latLng.latitude,
                                  model.latLng.longitude,
                                  title: model.title,
                                );
                              }
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                        InfoRow(loc.name, model.title),
                      ],
                    ),
                    btnTitle: loc.close,
                  ),
                );
                // show dialog first
                // and then open map
              } else {
                _openMap(model.latLng.latitude, model.latLng.longitude,
                    title: model.title);
              }
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

  Future _openMap(double lat, double lng, {String title}) async {
    print("Marker $title, lat: $lat, lng: $lng}");
    final urls = MapOpener.buildMapUrls(location: LatLng(lat, lng));
    if (await MapOpener.canOpen(urls)) {
      MapOpener.openMap(urls);
    }
  }

  Future _logOut() async {
    await DbClient().clearAllTables();
    Prefs.logout();
    AppMahlmann.of(context).setIsAuthorized(false);
  }

  void _onSentenceBtnClick() async {
    if (bloc.currentMode == BtnsMode.createSentence) {
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
    } else {
      bloc.onSelectSentenceClick();
    }
  }

  void _onSentenceInboxClick() {
    bloc.onSentenceInboxClick();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Provider.value(
        value: bloc,
        builder: (context, _) => SentenceInboxDialog(),
      ),
    );
  }
}

class SearchSuggestionItem extends StatelessWidget {
  const SearchSuggestionItem({
    Key key,
    @required this.field,
    @required this.onSelected,
  }) : super(key: key);

  final Field field;
  final Function(Field) onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          field.name,
        ),
      ),
      onTap: () => onSelected(field),
    );
  }
}
