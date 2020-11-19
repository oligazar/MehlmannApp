import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/blocs/bloc_map.dart';
import 'package:mahlmann_app/common/functions.dart';
import 'package:mahlmann_app/common/lang/m_localizations.dart';
import 'package:mahlmann_app/models/built_value/btns_mode.dart';
import 'package:mahlmann_app/models/map/map_data.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';
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
	
	// var _searchBoxUpdater = ValueNotifier<bool>(false);
	
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
									markers: mapData?.showFountains != false ? _buildMarkers(mapData?.fountains) : null,
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
																		text: mode == BtnsMode.measurement ? loc.stopMeasurement : loc.startMeasurement,
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
													text: mapData?.showFountains != false ? loc.fountainOff : loc.fountainOn,
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
												ButtonMahlmann(
													onPressed: bloc.onBackBtnClick,
													text: loc.back,
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
	
	Set<Marker> _buildMarkers(Iterable<ModelMarker> models) {
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
				icon: model.icon ?? model.hue != null
						? BitmapDescriptor.defaultMarkerWithHue(model.hue)
						: BitmapDescriptor.defaultMarker,
			);
		})?.toSet() ??
				Set<Marker>();
		return markers;
	}
}
