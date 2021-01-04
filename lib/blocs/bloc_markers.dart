import 'dart:typed_data';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/common/interfaces/disposable.dart';
import 'package:mahlmann_app/models/map/model_marker.dart';
import 'package:rxdart/rxdart.dart' as rx;

class MarkersData {
	final List<ModelMarker> labels;
	final List<ModelMarker> fountains;
	
	MarkersData({this.labels, this.fountains});
}

class BlocMarkers extends Disposable {
	static const thresholdZoom = 12.0;
	static const defaultZoom = 15.0;
	int _clustersLength = 0;
	
	// resulting data: labels + fountains/clusters
	final _markersData = rx.BehaviorSubject<MarkersData>.seeded(MarkersData());
	final _models = rx.BehaviorSubject<List<ModelMarker>>.seeded([]);
	// bitmaps for labels
	final _bitmaps = rx.BehaviorSubject<Map<String, Uint8List>>.seeded({});
	final _labels = rx.BehaviorSubject<List<ModelMarker>>.seeded([]);
	final _zoom = rx.BehaviorSubject<double>.seeded(thresholdZoom);
	final _clusters = rx.BehaviorSubject<List<ModelMarker>>.seeded([]);
	
	Stream<List<ModelMarker>> get labels => _labels.stream;
	Stream<MarkersData> get markersData => _markersData.stream;
	Stream<double> get zoomStream => _zoom.stream;
	
	BlocMarkers() {
		rx.Rx.combineLatest([
			_models,
			_clusters,
			_bitmaps,
			_zoom,
		], (streams) => streams).listen((s) {
			final List<ModelMarker> models = s[0] ?? [];
			final List<ModelMarker> clusters = s[1] ?? [];
			final Map<String, Uint8List> bitmaps = s[2] ?? {};
			final double zoom = s[3] ?? thresholdZoom;
			
			final labels = <ModelMarker>[];
			
			print("zoom: $zoom");
			
			if (zoom > thresholdZoom) {
				models?.forEach((model) {
					final bitmap = bitmaps[model.id];
					model.icon = bitmap != null
							? BitmapDescriptor.fromBytes(bitmap)
							: model.hue != null
							? BitmapDescriptor.defaultMarkerWithHue(model.hue)
							: BitmapDescriptor.defaultMarker;
				});
				
				labels.addAll(models);
			}
			
			final data = MarkersData(
				labels: labels,
				fountains: clusters,
			);
			
			// output is markersData (labels + clusters)
			_markersData.add(data);
		});
	}
	
	set clusters(List<ModelMarker> clusters) {
		final cl = clusters.length;
		
		print("cl: $cl, _clustersLength: $_clustersLength");
		if (cl == _clustersLength) return;
		_clustersLength = cl;
		
		_clusters.add(clusters);
	}
	
	set zoom(double zoom) {
		_zoom.add(zoom);
	}
	
	set bitmaps(Map<String, Uint8List> bitmaps) {
		_bitmaps.add(bitmaps);
	}
	
	set models(Iterable<ModelMarker> models) {
		_models.add(models.toList());
	}
	
	@override
	void dispose() {
		_zoom.close();
		_models.close();
		_labels.close();
		_bitmaps.close();
		_markersData.close();
		_clusters.close();
	}
}