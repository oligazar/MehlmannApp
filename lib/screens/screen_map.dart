import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/app_mahlmann.dart';
import 'package:mahlmann_app/blocs/bloc_map.dart';
import 'package:mahlmann_app/blocs/bloc_markers.dart';
import 'package:mahlmann_app/common/constants.dart';
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
import 'package:mahlmann_app/widgets/dialogs/info_row.dart';
import 'package:mahlmann_app/widgets/dialogs/m_dialog.dart';
import 'package:mahlmann_app/widgets/dialogs/sentence_inbox_dialog.dart';
import 'package:mahlmann_app/widgets/dialogs/two_actions_dialog.dart';
import 'package:mahlmann_app/widgets/m_button.dart';
import 'package:mahlmann_app/widgets/m_progress_indicator.dart';
import 'package:mahlmann_app/widgets/m_text_field.dart';
import 'package:mahlmann_app/widgets/search_box.dart';
import 'package:mahlmann_app/widgets/dialogs/select_sentence_dialog.dart';
import 'package:provider/provider.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:post_frame_image_builder/post_frame_image_builder.dart';
import 'package:cluster_builder/cluster_builder.dart';

// drawing custom marker on the field: https://github.com/flutter/flutter/issues/26109
class ScreenMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<BlocMap>(
          create: (context) => BlocMap(),
          dispose: (context, value) => value.dispose(),
          lazy: false,
        ),
        Provider<BlocMarkers>(
          create: (context) => BlocMarkers(),
          dispose: (context, value) => value.dispose(),
          lazy: false,
        ),
      ],
      child: ViewMap(),
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

  BlocMap get _blocMap => context.provide<BlocMap>();

  BlocMarkers get _blocMarkers => context.provide<BlocMarkers>();

  MLocalizations get _loc => context.loc;

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
    _fieldInfoSubscription = _blocMap.fieldInfo.listen((field) async {
      if (field != null) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => MDialog(
            child: StreamBuilder<List<Comment>>(
                stream: _blocMap.fieldComments,
                builder: (context, snapshot) {
                  final comments = snapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: DialogButton(
                          title: _loc.route,
                          action: () {
                            final c = field.coordinates.firstOrNull;
                            if (c.lat != null && c.lng != null) {
                              final urls = MapOpener.buildMapUrls(
                                  location: LatLng(c.lat, c.lng));
                              MapOpener.openMap(urls);
                            }
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      InfoRow(_loc.name, field.name),
                      InfoRow(_loc.status, field.status),
                      InfoRow(_loc.cabbage, field.isCabbage),
                      InfoRow(
                          _loc.titleArea,
                          field.areaSize != null
                              ? "${field.areaSize.toStringAsFixed(2)} ha"
                              : null),
                      Text(_loc.comments),
                      for (Comment c in comments) InfoRow(c.user, c.text),
                      const SizedBox(height: 8),
                      MTextField(
                        hint: _loc.comment,
                        onSubmitted: (comment) {
                          // clear text field ???
                          _blocMap.onSubmitComment(field.id, comment);
                        },
                      ),
                    ],
                  );
                }),
            btnTitle: _loc.close,
          ),
        );
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<MapData>(
              stream: _blocMap.mapData,
              builder: (context, snapshot) {
                final mapData = snapshot?.data;
                final labelModels = mapData?.labels ?? <ModelMarker>{};
                final fountainModels = mapData?.fountains ?? <ModelMarker>{};
                _blocMarkers.labelModels = labelModels;
                return Stack(
                  children: [
                    PostFrameImageBuilder<ModelMarker>(
                      modelsMap: _mapModels(labelModels),
                      widgetBuilder: (model) => model.toLabelMarker(),
                      builder: (_, bitmaps) {
                        _blocMarkers.bitmaps = bitmaps;
                        return Container();
                      },
                    ),
                    StreamBuilder<double>(
                        stream: _blocMarkers.zoomStream,
                        builder: (context, snap) {
                          final zoom = snap.data ?? BlocMarkers.defaultZoom;
                          print("ms4.zoom: $zoom");
                          return ClusterBuilder<ModelMarker>(
                              zoom: zoom,
                              clusterables: fountainModels?.toList() ?? [],
                              createCluster: (cluster, lng, lat) => ModelMarker(
                                    id: cluster.id.toString(),
                                    latLng: LatLng(lat, lng),
                                    isCluster: cluster.isCluster,
                                    clusterId: cluster.id,
                                    pointsSize: cluster.pointsSize,
                                    childMarkerId: cluster.childMarkerId,
                                  ),
                              builder: (List<ModelMarker> clusters) {
                                _blocMarkers.clusters = clusters;
                                return Container();
                              });
                        }),
                    StreamBuilder<MarkersData>(
                        stream: _blocMarkers.markersData,
                        builder: (context, snapshot) {
                          final labels = snapshot.data?.labels ?? [];
                          final fountains = snapshot.data?.fountains ?? [];
                          return GoogleMap(
                            zoomControlsEnabled: false,
                            myLocationButtonEnabled: false,
                            polygons: mapData?.polygons,
                            polylines: mapData?.polylines,
                            markers:
                                _buildAllMarkers(mapData, labels, fountains),
                            onCameraMove: (position) async {
                              final currentZoom = _blocMarkers.currentZoom ?? BlocMarkers.defaultZoom;
                              if ((position.zoom - currentZoom).abs() > 1 || position.target.isWithinBounds(_blocMarkers.bounds)) {
                                _blocMarkers.bounds = await _controller.future.then((c) => c.getVisibleRegion());
                                _blocMarkers.zoom = position.zoom;
                              }
                            },
                            initialCameraPosition: _kGooglePlex,
                            onMapCreated: _onMapCreated,
                            onTap: _blocMap.onMapTap,
                            mapType: mapData?.isSatelliteView == true
                                ? MapType.satellite
                                : MapType.normal,
                          );
                        }),
                    SafeArea(
                      minimum: EdgeInsets.only(bottom: 20),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StreamBuilder<double>(
                                stream: _blocMap.measurement,
                                builder: (context, snapshot) {
                                  final measurement = snapshot.data;
                                  if (measurement != null) {
                                    final mString = _blocMap.currentMode ==
                                            BtnsMode.measureArea
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
                                  onPressed: _blocMap.switchMapType,
                                  icon: Icons.map,
                                  isActive: mapData?.isSatelliteView == true,
                                ),
                                MButton(
                                  onPressed: _goToCurrentPosition,
                                  icon: Icons.location_on,
                                ),
                                MButton(
                                  onPressed: _blocMap.onFountainsBtnClicked,
                                  isActive: mapData?.showFountains != false,
                                  icon: Icons.invert_colors,
                                ),
                                MButton(
                                  onPressed: _blocMap.onLabelsBtnClicked,
                                  isActive: mapData?.showLabels != false,
                                  icon: Icons.local_offer,
                                ),
                                mapData?.pins?.isNotEmpty == true
                                    ? MButton(
                                        onPressed: _blocMap.onBackBtnClick,
                                        // text: loc.back,
                                        icon: Icons.undo)
                                    : Container(height: 0),
                                StreamBuilder<bool>(
                                    stream: _blocMap.isLoading,
                                    builder: (context, snapshot) {
                                      final isLoading = snapshot.data == true;
                                      return MButton(
                                        onPressed: _blocMap.onRefreshBtnClicked,
                                        isActive: !isLoading,
                                        isEnabled: !isLoading,
                                        icon: Icons.refresh,
                                      );
                                    }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      minimum: EdgeInsets.only(top: 28),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: StreamBuilder<BtnsMode>(
                            stream: _blocMap.mode,
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
                                        onPressed: _blocMap.onMeasurementClick,
                                        icon: mode == BtnsMode.measureDistance
                                            ? Icons.straighten
                                            : Icons.square_foot,
                                        isActive: mode ==
                                                BtnsMode.measureArea ||
                                            mode == BtnsMode.measureDistance,
                                      ),
                                      FutureBuilder<bool>(
                                          future: Prefs.getLoginResponse()
                                              .then((r) => r.admin),
                                          builder: (context, snapshot) {
                                            final isAdmin =
                                                snapshot.data == true;
                                            return isAdmin &&
                                                    _blocMap.hasFieldInfo
                                                ? MButton(
                                                    onPressed:
                                                        _onSentenceBtnClick,
                                                    icon: mode ==
                                                            BtnsMode
                                                                .createSentence
                                                        ? Icons
                                                            .location_searching
                                                        : Icons.edit,
                                                  )
                                                : Container();
                                          }),
                                      MButton(
                                        onPressed:
                                            _blocMap.onSearchFieldBtnClick,
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
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      child: mode == BtnsMode.search
                                          ? SearchBox(
                                              onSubmitted: _blocMap
                                                  .onFieldsQuerySubmitted,
                                              onChanged:
                                                  _blocMap.onFieldsQueryChanged,
                                              child: Flexible(
                                                child:
                                                    StreamBuilder<List<Field>>(
                                                  stream: _blocMap
                                                      .searchedFieldSuggestions,
                                                  builder: (context, snapshot) {
                                                    final fields =
                                                        snapshot.data ?? [];
                                                    return SingleChildScrollView(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          for (Field field
                                                              in fields)
                                                            SearchSuggestionItem(
                                                              field: field,
                                                              onSelected: _blocMap
                                                                  .onSuggestionFieldClick,
                                                            )
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            )
                                          : Container(),
                                    ),
                                  ),
                                ],
                              );
                            }),
                      ),
                    ),
                    StreamBuilder<bool>(
                        stream: _blocMap.isLoading,
                        builder: (context, snapshot) {
                          final isLoading = snapshot.data == true;
                          return isLoading
                              ? Align(
                                  alignment: Alignment.bottomCenter,
                                  child: MProgressIndicator(),
                                )
                              : Container();
                        }),
                    Positioned(
                      right: 24,
                      bottom: 24,
                      child: FutureBuilder(
                        future: _backendReminder(),
                        builder: (c, snapshot) {
                          final isProd = snapshot.data;
                          final style = TextStyle(color: Colors.blueAccent);
                          return isProd == null
                              ? Container()
                              : isProd
                                  ? Text("P", style: style)
                                  : Text("S", style: style);
                        },
                      ),
                    )
                  ],
                );
              }),
        ],
      ),
    );
  }

  Future<bool> _backendReminder() async {
    final email = await Prefs.getLoginResponse().then((r) => r.email ?? "");
    if (email.startsWith(TEST_PREFIX)) {
      return Prefs.isProdPref;
    } else {
      return null;
    }
  }

  @override
  dispose() async {
    super.dispose();
    _mapDataSubscription?.cancel();
    _fieldInfoSubscription?.cancel();
    _fountainInfoSubscription?.cancel();
  }

  _onMapCreated(GoogleMapController controller) async {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
      _blocMarkers.bounds = await controller.getVisibleRegion();
    }
    _mapDataSubscription = _blocMap.bounds.listen((data) async {
      if (data != null) {
        await _zoomFitBounds(data);
      }
    });
  }

  Future<void> _goToCurrentPosition() async {
    final location = await currentLocation;
    if (location != null) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(location, 12.8));
      // controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
      _blocMap.markCurrentPosition(location);
    }
  }

  Future _zoomFitBounds(LatLngBounds bounds) async {
    await _controller.future.then((controller) {
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
      controller.getVisibleRegion();
    });
  }

  Iterable<Marker> _buildMarkers(
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
                            title: _loc.route,
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
                        InfoRow(_loc.name, model.title),
                      ],
                    ),
                    btnTitle: _loc.close,
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
                ? model.isCluster
                    ? model.icon ?? iconDrop
                    : iconDrop
                : model.icon != null
                    ? model.icon
                    : BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed),
          );
        }) ??
        <Marker>[];
    return markers;
  }

  Future _openMap(double lat, double lng, {String title}) async {
    print("Marker $title, lat: $lat, lng: $lng}");
    final urls = MapOpener.buildMapUrls(location: LatLng(lat, lng));
    if (await MapOpener.canOpen(urls)) {
      MapOpener.openMap(urls);
    }
  }

  Future _logOut({bool shouldShowDialog = true}) async {
    bool shouldLogout;
    if (shouldShowDialog) {
      shouldLogout = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => TwoActionsDialog(
          title: _loc.dialogTitleConfirmLogout,
          btnCancelTitle: _loc.btnCancel,
          cancelAction: () => Navigator.of(context).pop(false),
          btnOkTitle: _loc.btnOk,
          okAction: () => Navigator.of(context).pop(true),
        ),
      );
    }
    if (shouldLogout) {
      await DbClient().clearAllTables();
      Prefs.logout();
      AppMahlmann.of(context).setIsAuthorized(false);
    }
  }

  void _onSentenceBtnClick() async {
    if (_blocMap.currentMode == BtnsMode.createSentence) {
      _blocMap.onSelectSentenceClick();
      final sentenceName = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => SelectSentenceDialog(
          title: _loc.sendSentence,
        ),
      );
      // shouldn't be there _fieldsGroup check first?
      if (sentenceName != null) {
        await _blocMap.onSendSentence(sentenceName);
        context.showSnackBar(Text(_loc.msgSuccess));
      }
    } else {
      _blocMap.onSelectSentenceClick();
    }
  }

  void _onSentenceInboxClick() {
    _blocMap.onSentenceInboxClick();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Provider.value(
        value: _blocMap,
        builder: (context, _) => SentenceInboxDialog(),
      ),
    );
  }

  Map<String, ModelMarker> _mapModels(Iterable<ModelMarker> models) {
    if (models == null) return <String, ModelMarker>{};
    print("mrk.MapScreen2._markerWidgets, models: $models");
    final entries = models.map((model) => MapEntry(model.id, model));
    return Map.fromEntries(entries);
  }

  Set<Marker> _buildAllMarkers(MapData mapData, List<ModelMarker> labels,
          List<ModelMarker> fountains) =>
      [
        if (mapData?.showFountains != false && fountains?.isNotEmpty == true)
          ..._buildMarkers(fountains),
        if (mapData?.pins?.isNotEmpty == true)
          ..._buildMarkers(mapData.pins, isFountain: false),
        if (mapData?.currentPosition != null)
          ..._buildMarkers([mapData.currentPosition], isFountain: false),
        if (mapData?.showLabels != false && labels != null)
          ..._buildMarkers(labels, isFountain: false),
      ].toSet();
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
