import 'dart:typed_data';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/common/interfaces/disposable.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:mahlmann_app/common/extensions.dart';

class MarkersData {
	final List<ModelMarker> labels;
	final List<ModelMarker> fountains;
	
	MarkersData({this.labels, this.fountains});
}

class BlocMarkers extends Disposable {
	static const thresholdZoom = 14.0;
	static const defaultZoom = 15.0;
	int _clustersLength = 0;
	LatLngBounds bounds;
	
	// resulting data: labels + fountains/clusters
	final _markersData = rx.BehaviorSubject<MarkersData>.seeded(MarkersData());
	final _labelModels = rx.BehaviorSubject<List<ModelMarker>>.seeded([]);
	final _labels = rx.BehaviorSubject<List<ModelMarker>>.seeded([]);
	// bitmaps for labels
	final _bitmaps = rx.BehaviorSubject<Map<String, Uint8List>>.seeded({});
	final _clusters = rx.BehaviorSubject<List<ModelMarker>>.seeded([]);
	
	final _zoom = rx.BehaviorSubject<double>.seeded(thresholdZoom);
	
	Stream<List<ModelMarker>> get labels => _labels.stream;
	Stream<MarkersData> get markersData => _markersData.stream;
	Stream<double> get zoomStream => _zoom.stream;
	double get currentZoom => _zoom.value;
	
	BlocMarkers() {
		rx.Rx.combineLatest([
			_labelModels,
			_clusters,
			_bitmaps,
			_zoom,
		], (streams) => streams).listen((s) {
			final List<ModelMarker> labelModels = s[0] ?? [];
			final List<ModelMarker> clusters = s[1] ?? [];
			final Map<String, Uint8List> bitmaps = s[2] ?? {};
			final double zoom = s[3] ?? thresholdZoom;
			
			final labels = <ModelMarker>[];
			
			print("zoom: $zoom");
			
			if (zoom > thresholdZoom && bounds != null) {
				labelModels?.forEach((model) {
					final bitmap = bitmaps[model.id];
					model.icon = bitmap != null
							? BitmapDescriptor.fromBytes(bitmap)
							: model.hue != null
							? BitmapDescriptor.defaultMarkerWithHue(model.hue)
							: BitmapDescriptor.defaultMarker;
					if (model.latLng.isWithinBounds(bounds)) {
						labels.add(model);
					}
				});
			}
			
			final data = MarkersData(
				labels: labels,
				fountains: clusters,
			);
			_markersData.add(data);
		});
		
		Geolocator().getCurrentPosition();
	}

	set clusters(List<ModelMarker> clusters) {
		final cl = clusters.length;
		
		final realClusters = clusters.where((c) => c.isCluster);
		print("realClusters: $realClusters");
		
		print("cl: $cl, _clustersLength: $_clustersLength");
		if (cl == 0 || cl == _clustersLength) return;
		_clustersLength = cl;
		
		_clusters.add(clusters);
	}
	
	set zoom(double zoom) {
		_zoom.add(zoom);
	}
	
	set bitmaps(Map<String, Uint8List> bitmaps) {
		if (bitmaps?.isNotEmpty == true) {
		 _bitmaps.add(bitmaps);
		}
	}
	
	set labelModels(Iterable<ModelMarker> models) {
		if (models?.isNotEmpty == true) {
			_labelModels.add(models.toList());
		}
	}
	
	@override
	void dispose() {
		_zoom.close();
		_labelModels.close();
		_labels.close();
		_bitmaps.close();
		_markersData.close();
		_clusters.close();
	}
}