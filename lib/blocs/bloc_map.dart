import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/common/api/api_client.dart';
import 'package:mahlmann_app/common/date_formatter.dart';
import 'package:mahlmann_app/common/interfaces/disposable.dart';
import 'package:mahlmann_app/common/interfaces/exception_handleable.dart';
import 'package:mahlmann_app/common/location/location_helper.dart';
import 'package:mahlmann_app/common/prefs.dart';
import 'package:mahlmann_app/common/sqlite/db_client.dart';
import 'package:mahlmann_app/models/built_value/btns_mode.dart';
import 'package:mahlmann_app/models/built_value/comment.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/built_value/fountain.dart';
import 'package:mahlmann_app/models/built_value/group.dart';
import 'package:mahlmann_app/models/built_value/measurements.dart';
import 'package:mahlmann_app/models/map/map_data.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;
import 'package:rxdart/rxdart.dart' as rx;

class BlocMap extends ExceptionHandleable implements Disposable {
	// Try GetIt sometimes for this things!
	final _db = DbClient();
	final _api = ApiClient();
	final _mapData = rx.BehaviorSubject<MapData>.seeded(MapData());
	final _isLoading = rx.BehaviorSubject<bool>.seeded(false);
	final _bounds = rx.BehaviorSubject<LatLngBounds>();
	final _currentPosition = rx.BehaviorSubject<LatLng>();
	
	final _measurement = rx.BehaviorSubject<Measurements>();
	final ValueNotifier<bool> isTrackingNotifier = ValueNotifier(false);
	final ValueNotifier<bool> shouldShowPath = ValueNotifier(false);
	
	final _mode = rx.BehaviorSubject<BtnsMode>.seeded(BtnsMode.none);
	final _fieldInfo = rx.BehaviorSubject<Field>();
	final _fountainInfo = rx.BehaviorSubject<Fountain>();
	final _searchedFieldSuggestions =
	rx.BehaviorSubject<List<Field>>.seeded([]); // orange
	final _fieldComments = rx.BehaviorSubject<List<Comment>>();
	final _inboxGroups = rx.BehaviorSubject<List<Group>>(); // purple
	
	final _fountains = Set<Fountain>(); // green
	final _fields = Set<Field>(); // green
	final _searchedFields = Set<Field>(); // orange
	final _fieldsGroup = Set<Field>(); // red
	final _inboxFields = Set<Field>(); // red
	
	final _exception = rx.BehaviorSubject<Exception>();
	
	bool get hasSearchedFields => _searchedFields.isNotEmpty;
	
	@override
	Stream<Exception> get exception => _exception.stream;
	
	Stream<MapData> get mapData =>
			_mapData.stream
					.debounce((_) => rx.TimerStream(true, Duration(milliseconds: 400)));
	
	Stream<bool> get isLoading => _isLoading.stream;
	
	Stream<LatLngBounds> get bounds => _bounds.stream;
	Stream<LatLng> get currentPosition => _currentPosition.stream;
	
	Stream<Measurements> get measurements => _measurement.stream;
	
	Stream<BtnsMode> get mode => _mode.stream;
	
	Stream<List<Comment>> get fieldComments => _fieldComments.stream;
	
	Stream<List<Group>> get inboxGroups => _inboxGroups.stream;
	
	Stream<Field> get fieldInfo => _fieldInfo.stream;
	
	Stream<Fountain> get fountainInfo => _fountainInfo.stream;
	
	Stream<List<Field>> get searchedFieldSuggestions =>
			_searchedFieldSuggestions.stream;
	
	bool get hasFieldInfo => _fieldInfo.hasValue;
	
	final List<LatLng> _pins = <LatLng>[];
	final List<LatLng> _points = <LatLng>[];
	
	BtnsMode get currentMode => _mode.value;
	
	BlocMap() {
		_prepareData();
	}
	
	@override
	void dispose() {
		_mapData.close();
		_bounds.close();
		_currentPosition.close();
		_measurement.close();
		_mode.close();
		_fieldInfo.close();
		_fountainInfo.close();
		_fieldComments.close();
		_inboxGroups.close();
		_searchedFieldSuggestions.close();
		_isLoading.close();
		_exception.close();
	}
	
	void clearInboxFields() {
		_inboxFields.clear();
		final polygons = _createPolygons();
		_updateMapData(polygons: polygons);
	}
	
	void onFieldsQuerySubmitted(String query) async {
		_mode.add(BtnsMode.none);
		print("query: $query");
		
		final searchedFields = await _db.queryFields(query: query);
		_inboxFields.clear();
		_searchedFields.clear();
		_searchedFieldSuggestions.add(null);
		_searchedFields.addAll(searchedFields ?? []);
		
		final polygons = _createPolygons();
		_updateMapData(polygons: polygons);
		
		_updateBounds(searchedFields);
	}
	
	void onSuggestionFieldClick(Field field) async {
		_mode.add(BtnsMode.none);
		_searchedFieldSuggestions.add(null);
		_inboxFields.clear();
		_searchedFields.clear();
		_searchedFields.addAll([field]);
		
		final polygons = _createPolygons();
		_updateMapData(polygons: polygons);
		
		_updateBounds([field]);
	}
	
	void deselectSearchFields() {
		_mode.add(BtnsMode.none);
		_searchedFields.clear();
		
		final polygons = _createPolygons();
		_updateMapData(polygons: polygons);
		
		_updateBounds(_fields);
	}
	
	void onFieldsQueryChanged(String query) async {
		// update suggestions
		if (query.length > 1) {
			final searchedFields = await _db.queryFields(query: query);
			_searchedFieldSuggestions.add(searchedFields ?? []);
		} else {
			_searchedFieldSuggestions.add([]);
		}
	}
	
	// Click handlers
	
	void onAddPin(LatLng latLng) {
		if (_mode.value == BtnsMode.measureArea ||
				_mode.value == BtnsMode.measureDistance ||
				_mode.value == BtnsMode.searchDistance ||
				_mode.value == BtnsMode.searchArea) {
			_pins.add(latLng);
			
			_measurement.add(_calculateMeasurement());
			
			_updateMapData(
				pins: _createPins(),
				polygons: _createPolygons(),
				polylines: _createPolylines(),
			);
		}
	}
	
	Set<ModelMarker> _createPins() {
		final points = currentMode == BtnsMode.measureDistance && _pins.length > 2
				? <LatLng>[_pins.first, _pins.last]
				: _pins;
		final pins = points.map((point) {
			final lat = point.latitude;
			final lng = point.longitude;
			return ModelMarker(
				id: "markerId-pin-${_pins.length}-$lat-$lng",
				latLng: LatLng(lat, lng),
				hue: BitmapDescriptor.hueRed,
				// color: f.name,
			);
		});
		final set = pins.toSet();
		print("points: $points, pins: $pins, set: $set");
		return set;
	}
	
	void onMeasurementClick() {
		BtnsMode newMode = BtnsMode.measureArea;
		switch (_mode.value) {
			case BtnsMode.measureArea:
				newMode = BtnsMode.measureDistance;
				break;
			case BtnsMode.searchArea:
				newMode = BtnsMode.searchDistance;
				break;
			case BtnsMode.measureDistance:
				newMode = BtnsMode.none;
				_pins.clear();
				break;
			case BtnsMode.searchDistance:
				newMode = BtnsMode.search;
				_pins.clear();
				break;
		}
		_mode.add(newMode);
		
		if (newMode == BtnsMode.none) {
			_measurement.add(null);
			_updateMapData(
				pins: Set<ModelMarker>(),
				polygons: _createPolygons(),
				polylines: _createPolylines(),
			);
		} else {
			_measurement.add(_calculateMeasurement());
			_updateMapData(
				pins: _createPins(),
				polygons: _createPolygons(),
				polylines: _createPolylines(),
			);
		}
	}
	
	void onSelectSentenceClick() {
		final newMode = _mode.value == BtnsMode.createSentence
				? BtnsMode.selectSentence
				: BtnsMode.createSentence;
		_mode.add(newMode);
	}
	
	void onSearchFieldBtnClick() {
		final newMode = _figureOutMode();
		
		_mode.add(newMode);
		_searchedFieldSuggestions.add(null);
	}
	
	void onFountainsBtnClicked() {
		final shouldShowFountains = !_mapData.value.showFountains;
		_updateMapData(
			labels: _createLabelsMarkers(
					_fields.toList(), shouldShowFountains ? _fountains.toList() : []),
			showFountains: shouldShowFountains,
		);
	}
	
	void onLabelsBtnClicked() {
		_updateMapData(showLabels: !_mapData.value.showLabels);
	}
	
	void onBackBtnClick() {
		_pins.removeLast();
		_measurement.add(_calculateMeasurement());
		_updateMapData(
			pins: _createPins(),
			polygons: _createPolygons(),
			polylines: _createPolylines(),
		);
	}
	
	void onSubmitComment(int fieldId, String text) async {
		final comment =
		await _api.createComment(fieldId, text).catchError((e) { _exception.add(e); });
		if (comment != null) {
			final comments = _fieldComments.value ?? [];
			_fieldComments.add(comments..add(comment));
		}
	}
	
	void onSentenceInboxClick() async {
		final groups = await _db.queryGroups();
		final filtered =
		groups.where((group) => group.name?.isNotEmpty == true).toList();
		_inboxGroups.add(filtered);
	}
	
	void handleSentence(List<int> fieldIds) async {
		final db = DbClient();
		_inboxFields.clear();
		final inboxFields = await db.queryFieldsIn(ids: fieldIds.toList()) ?? [];
		_inboxFields.addAll(inboxFields);
		
		final polygons = _createPolygons();
		_updateMapData(polygons: polygons);
		
		_updateBounds(_inboxFields);
	}
	
	Future onSendSentence(String sentenceName) async {
		final fieldIds = _fieldsGroup.map((fg) => fg.id).toList();
		await _api.createGroup(sentenceName, fieldIds).catchError((e) { _exception.add(e); });
		_fieldsGroup.clear();
		
		_updateMapData(
			polygons: _createPolygons(),
		);
		
		await getLastUpdates();
	}
	
	onDeselectSentence() {
		_fieldsGroup.clear();
		_updateMapData(
			polygons: _createPolygons(),
		);
	}
	
	void markCurrentPosition(LatLng latLng) {
		final marker = _createModelMarker(latLng);
		_updateMapData(
			currentPosition: marker,
		);
	}
	
	ModelMarker _createModelMarker(LatLng latLng) => ModelMarker(
		id: "markerId-currentPosition",
		latLng: latLng,
		hue: BitmapDescriptor.hueRed,
		// color: f.name,
	);
	
	// private functions
	
	// calculates area in ha or distance in meters depending on the mode
	Measurements _calculateMeasurement() {
		final m = _measurement.value ?? Measurements();
		return m.rebuild((b) =>
		b
			..area = _calculateArea()
			..distance = _calculateDistance()
			..lastSegment = _calculateLastSegmentMeasurement());
	}
	
	double _calculateDistance() {
		if (_pins.length > 1) {
			final pins = List.of(_pins);
			if (currentMode == BtnsMode.measureArea && pins.length > 2) {
				pins.add(pins[0]);
			}
			final distanceMeters = mt.SphericalUtil.computeLength(
					pins.map((c) => mt.LatLng(c.latitude, c.longitude)).toList());
			return distanceMeters;
		}
		return null;
	}
	
	double _calculateArea() {
		if (currentMode == BtnsMode.measureArea && _pins.length > 2) {
			final areaSquareMeters = mt.SphericalUtil.computeArea(
					_pins.map((c) => mt.LatLng(c.latitude, c.longitude)).toList());
			final areaHa = areaSquareMeters / 10000;
			return areaHa;
		}
		return null;
	}
	
	double _calculateLastSegmentMeasurement() {
		if (_pins.length > 1) {
			final distanceMeters = mt.SphericalUtil.computeLength(_pins
					.getRange(_pins.length - 2, _pins.length)
					.map((c) => mt.LatLng(c.latitude, c.longitude))
					.toList());
			print("distanceMeters: $distanceMeters");
			return distanceMeters;
		}
		return null;
	}
	
	Set<Polyline> _createPolylines() {
		final polylines = Set<Polyline>();
		final optionA = (currentMode == BtnsMode.measureDistance ||
				currentMode == BtnsMode.searchDistance) &&
				_pins.length > 1;
		final optionB = (currentMode == BtnsMode.measureArea ||
				currentMode == BtnsMode.searchArea) &&
				_pins.length > 1 &&
				_pins.length <= 2;
		if (optionA || optionB) {
			final polyline = Polyline(
				polylineId: PolylineId("measurement"),
				width: 2,
				color: Colors.blue,
				points: _pins,
			);
			polylines.add(polyline);
		}
		if (_points.isNotEmpty) {
			final path = Polyline(
				polylineId: PolylineId("path"),
				width: 2,
				color: Colors.red,
				points: _points,
			);
			polylines.add(path);
		}
		return polylines;
	}
	
	void _updateMapData({
		Set<ModelMarker> fountains,
		Set<ModelMarker> pins,
		Set<ModelMarker> labels,
		Set<Polygon> polygons,
		Set<Polyline> polylines,
		bool showFountains,
		bool showLabels,
		bool isSatelliteView,
		ModelMarker currentPosition,
	}) {
		final MapData mapData = _mapData.value;
		final newData = mapData != null
				? mapData.copyWith(
			fountains: fountains ?? mapData.fountains,
			pins: pins ?? mapData.pins,
			labels: labels ?? mapData.labels,
			polygons: polygons ?? mapData.polygons,
			polylines: polylines ?? mapData.polylines,
			showFountains: showFountains ?? mapData.showFountains,
			showLabels: showLabels ?? mapData.showLabels,
			isSatelliteView: isSatelliteView ?? mapData.isSatelliteView,
			currentPosition: currentPosition ?? mapData.currentPosition,
		)
				: MapData(
			fountains: fountains,
			pins: pins,
			labels: labels,
			polygons: polygons,
			polylines: polylines,
			showFountains: showFountains,
			showLabels: showLabels,
			isSatelliteView: isSatelliteView,
			currentPosition: currentPosition,
		);
		_mapData.add(newData);
	}
	
	Iterable<ModelMarker> _createFountainsMarkers(List<Fountain> fountains, {
		String id,
	}) {
		return fountains.map((fountain) {
			final lat = fountain.lat;
			final lng = fountain.lng;
			return ModelMarker(
				id: id ?? "markerId-$lat-$lng",
				title: fountain.name,
				latLng: LatLng(lat, lng),
				hue: BitmapDescriptor.hueBlue,
				onTap: () => _onFountainClick(fountain)
				// color: f.name,
			);
		});
	}
	
	Iterable<ModelMarker> _createLabelsMarkers(List<Field> fields,
			List<Fountain> fountains, {
				String id,
			}) {
		return [
			for (Field field in fields)
				if (field.centroid != null)
					ModelMarker(
							id: id ??
									"labelFieldId-${field.centroid.lat}-${field.centroid.lng}",
							title: field.name,
							subTitle: "${field.areaSize}",
							latLng: LatLng(field.centroid.lat, field.centroid.lng),
							hue: BitmapDescriptor.hueBlue,
							onTap: () => _onFieldClick(field)
						// color: f.name,
					),
			for (Fountain fountain in fountains)
				if (fountain.lat != null && fountain.lng != null)
					ModelMarker(
						id: id ?? "labelFountainId-${fountain.lat}-${fountain.lng}",
						title: fountain.name,
						// subTitle: "${fountain.color}",
						latLng: LatLng(fountain.lat, fountain.lng),
						hue: BitmapDescriptor.hueBlue,
						onTap: () => _onFountainClick(fountain)
						// color: f.name,
					),
		].toSet();
	}
	
	LatLngBounds _createBounds(List<LatLng> points) {
		if (points?.isEmpty == true) return null;
		final southwestLat = points.map((p) => p.latitude).reduce(
						(value, element) => value < element ? value : element); // smallest
		final southwestLon = points.map((p) => p.longitude).reduce(
						(value, element) => value < element ? value : element); // smallest
		final northeastLat = points.map((p) => p.latitude).reduce(
						(value, element) => value > element ? value : element); // biggest
		final northeastLon = points.map((p) => p.longitude).reduce(
						(value, element) => value > element ? value : element); // biggest
		return LatLngBounds(
				southwest: LatLng(southwestLat, southwestLon),
				northeast: LatLng(northeastLat, northeastLon));
	}
	
	Future _prepareData({bool forceRefresh = false}) async {
		if (forceRefresh) { 
			_fields.clear(); 
		  _fountains.clear();
		}
		final fields = await _db.queryFields();
		_fields.addAll(fields ?? []);
		final polygons = _createPolygons();
		final fountains = await _db.queryFountains();
		_fountains.addAll(fountains ?? []);
		final labels = _createLabelsMarkers(fields, fountains);
		
		final markers = _mapData.value.fountains ?? Set<ModelMarker>();
		markers.addAll(_createFountainsMarkers(fountains));
		
		_updateMapData(
			fountains: markers,
			polygons: polygons,
			labels: labels,
		);
		_updateBounds(_fields);
		
		await _initPositionsTracking();
		await _applyPreferences();
	}
	
	Future _applyPreferences() async {
		// 1. position tracking
		final shouldTrackPosition = await Prefs.shouldTrackPosition;
		onTrackingPressed(shouldTrackPosition == true);
		// 2. route tracking
		final showPath = await Prefs.shouldTrackRoute;
		onPathSwitchPressed(showPath == true);
	}
	
	Set<Polygon> _createPolygons() {
		final polygons = Set<Polygon>();
		final fields = _inboxFields.isNotEmpty ? _inboxFields : _fields;
		fields.forEach((field) {
			final points = <LatLng>[];
			field.coordinates?.forEach((c) {
				if (c.lat != null && c.lng != null) {
					points.add(LatLng(c.lat, c.lng));
				}
			});
			final color = _getColorFor(field);
			final polygon = Polygon(
				strokeWidth: 2,
				polygonId: PolygonId(field.id.toString()),
				fillColor: color.withAlpha(150),
				strokeColor: color,
				points: points,
				consumeTapEvents: currentMode != BtnsMode.measureArea &&
						currentMode != BtnsMode.measureDistance,
				onTap: () => _onFieldClick(field),
			);
			polygons.add(polygon);
		});
		
		// handle measurement polygon
		if (_pins.length > 2 && currentMode == BtnsMode.measureArea) {
			final polygon = Polygon(
				strokeWidth: 1,
				polygonId: PolygonId("measurement"),
				fillColor: Colors.redAccent.withAlpha(160),
				strokeColor: Colors.black,
				points: _pins,
			);
			polygons.updateWhere(
					Set.of([polygon]), (o, n) => o.polygonId == n.polygonId);
		} else {
			polygons.removeWhere((p) => p.polygonId.value == "measurement");
		}
		
		return polygons;
	}
	
	void _updateBounds(Iterable<Field> fields) {
		final coordinates = fields
				.expand((f) => f.coordinates.map((c) => LatLng(c.lat, c.lng)))
				.toList();
		final bounds = _createBounds(coordinates);
		// update bounds
		_bounds.add(bounds);
	}
	
	// onPolygonPress
	Future _onFieldClick(Field field) async {
		if (currentMode != BtnsMode.measureArea &&
				currentMode != BtnsMode.measureDistance &&
				currentMode != BtnsMode.searchArea &&
				currentMode != BtnsMode.searchDistance) {
			
			_fieldComments.add([]);
			
			void _updateFields() {
				final polygons = _createPolygons();
				_updateMapData(polygons: polygons);
			}
			
			if (currentMode != BtnsMode.createSentence) {
				_fieldInfo.add(field);
				// _updateFields();
				
				final comments =
				await _api.fetchComments(field.id).catchError((e) { _exception.add(e); });
				_fieldComments.add(comments);
			} else {
				_fieldInfo.add(null);
				// grouping == true
				if (_fieldsGroup.contains(field)) {
					_fieldsGroup.remove(field);
				} else {
					_fieldsGroup.add(field);
				}
				_updateFields();
			}
		}
	}
	
	Future _onFountainClick(Fountain fountain) async {
		if (currentMode != BtnsMode.measureArea &&
				currentMode != BtnsMode.measureDistance &&
				currentMode != BtnsMode.searchArea &&
				currentMode != BtnsMode.searchDistance
		) {
			if (currentMode != BtnsMode.createSentence) {
				_fountainInfo.add(fountain);
			} else {
				_fountainInfo.add(null);
			}
		}
	}
	
	Color _getColorFor(field) {
		Color color = Colors.green;
		if (_searchedFields.contains(field)) {
			color = Colors.orange;
		}
		if (_inboxFields.contains(field) == true) {
			color = Colors.purple;
		}
		if (_fieldsGroup.contains(field)) {
			color = Colors.orange;
		}
		
		return color;
	}
	
	void switchMapType(bool isSatelliteMode) {
		_updateMapData(isSatelliteView: isSatelliteMode);
	}
	
	Future onRefreshBtnClicked() async {
		_isLoading.add(true);
		
		try {
			final response = await _api.fetchObjects();
			await Prefs.saveLastUpdate(await DateFormatter.getTimeStringAsync());
			
			await _db.insertFountains(response.fountains.toList());
			await _db.insertFields(response.fields.toList());
			await _db.insertGroups(response.groups.toList());
			
			await _prepareData(forceRefresh: true);
		} catch (e) {
			print("onRefreshBtnClicked: $e");
			_exception.add(e);
		} finally {
			_isLoading.add(false);
		}
	}
	
	Future<void> getLastUpdates() async {
		_isLoading.add(true);
		try {
			final response = await _api.fetchObjects(from: await Prefs.lastUpdate);
			await Prefs.saveLastUpdate(await DateFormatter.getTimeStringAsync());
			
			await _db.insertFountains(response.fountains.toList(),
					shouldClearTable: false);
			await _db.insertFields(response.fields.toList(), shouldClearTable: false);
			await _db.insertGroups(response.groups.toList(), shouldClearTable: false);
			
			await _prepareData();
		} catch (e) {
			print("getLastUpdates: $e");
			_exception.add(e);
		} finally {
			_isLoading.add(false);
		}
	}
	
	BtnsMode _figureOutMode() {
		final cm = _mode.value;
		print("cm: $cm");
		if (cm == BtnsMode.searchArea) return BtnsMode.measureArea;
		if (cm == BtnsMode.searchDistance) return BtnsMode.measureDistance;
		if (cm == BtnsMode.search) return BtnsMode.none;
		
		if (cm == BtnsMode.measureArea) return BtnsMode.searchArea;
		if (cm == BtnsMode.measureDistance) return BtnsMode.searchDistance;
		
		return BtnsMode.search;
	}
	
	
	Future onPathSwitchPressed(bool shouldShowPath) async {
		print("onPathSwitchPressed: $shouldShowPath");
		this.shouldShowPath.value = shouldShowPath;
		if (!shouldShowPath) {
			_points.clear();
			_updateMapData(
				polylines: _createPolylines(),
			);
			await DbClient().clearPathPoints();
		}
	}


  Future onTrackingPressed(bool shouldTrackPosition) async {
		print("shouldTrackPosition: $shouldTrackPosition");
		if (shouldTrackPosition) {
			startTracking();
		} else {
			stopTracking();
		}
  }
  
  startTracking() {
	  isTrackingNotifier.value = true;
	  LocationHelper().startListeningLocation();
	  LocationHelper().locationData.removeListener(_positionChanged);
	  LocationHelper().locationData.addListener(_positionChanged);
  }
  
  Future stopTracking() async {
	  isTrackingNotifier.value = false;
	  LocationHelper().stopListeningLocation();
	  LocationHelper().locationData.removeListener(_positionChanged);
  }

  Future _initPositionsTracking() async {
	  await LocationHelper().init();
	  final isTracking = await LocationHelper().isTrackingLocation;
	  isTrackingNotifier.value = isTracking;
	  if (isTracking) {
	  	final points = await DbClient().queryPathPoints();
	  	_points.clear();
	  	_points.addAll(points.map((p) => LatLng(p.lat, p.lng)));
			LocationHelper().locationData.addListener(_positionChanged);
	  }
  }
  
	void _positionChanged() {
		final position = LocationHelper().locationData.value;
		print("New position: $position");
		if (position?.lat != null && position?.lng != null) {
			final latLng = LatLng(position.lat, position.lng);
			_points.add(latLng);
			_currentPosition.add(latLng);
			_updateMapData(
				currentPosition: _createModelMarker(latLng),
				polylines: shouldShowPath.value == true ? _createPolylines() : null,
			);
		}
	}
	
}
