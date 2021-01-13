import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkerGenerator {
  final _markerSize;
  double _circleStrokeWidth;
  double _circleOffset;
  double _outlineCircleWidth;
  double _fillCircleWidth;
  double _iconSize;
  double _iconOffset;

  // xxx() async {
  //   final iconData = Icons.whatshot;
  //   final pictureRecorder = PictureRecorder();
  //   final canvas = Canvas(pictureRecorder);
  //
  //   final textPainter = TextPainter(textDirection: TextDirection.ltr);
  //   final iconStr = String.fromCharCode(iconData.codePoint);
  //   textPainter.text = TextSpan(
  //       text: iconStr,
  //       style: TextStyle(
  //         letterSpacing: 0.0,
  //         fontSize: 48.0,
  //         fontFamily: iconData.fontFamily,
  //         color: Colors.red,
  //       ));
  //   textPainter.layout();
  //   textPainter.paint(canvas, Offset(0.0, 0.0));
  //
  //   final picture = pictureRecorder.endRecording();
  //   final image = await picture.toImage(48, 48);
  //   final bytes = await image.toByteData(format: ImageByteFormat.png);
  //
  //   final bitmapDescriptor =
  //       BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  //
  //   final marker = Marker(
  //     markerId: MarkerId("my_marker_id"),
  //     position: LatLng(52.5, 13.5),
  //     icon: bitmapDescriptor,
  //   );
  // }

  MarkerGenerator(this._markerSize) {
    // calculate marker dimensions
    _circleStrokeWidth = _markerSize / 10.0;
    _circleOffset = _markerSize / 2;
    _outlineCircleWidth = _circleOffset - (_circleStrokeWidth / 2);
    _fillCircleWidth = _markerSize / 2;
    final outlineCircleInnerWidth = _markerSize - (2 * _circleStrokeWidth);
    _iconSize = sqrt(pow(outlineCircleInnerWidth, 2) / 2);
    final rectDiagonal = sqrt(2 * pow(_markerSize, 2));
    final circleDistanceToCorners =
        (rectDiagonal - outlineCircleInnerWidth) / 2;
    _iconOffset = sqrt(pow(circleDistanceToCorners, 2) / 2);
  }

  /// Creates a BitmapDescriptor from an IconData
  Future<BitmapDescriptor> createBitmapDescriptorFromIconData(
    IconData iconData,
    Color iconColor,
    Color circleColor,
    Color backgroundColor,
  ) async {
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    _paintCircleFill(canvas, backgroundColor);
    _paintCircleStroke(canvas, circleColor);
    _paintIcon(canvas, iconColor, iconData);

    final picture = pictureRecorder.endRecording();
    final image =
        await picture.toImage(_markerSize.round(), _markerSize.round());
    final bytes = await image.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }

  /// Paints the icon background
  void _paintCircleFill(Canvas canvas, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawCircle(
        Offset(_circleOffset, _circleOffset), _fillCircleWidth, paint);
  }

  /// Paints a circle around the icon
  void _paintCircleStroke(Canvas canvas, Color color) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = _circleStrokeWidth;
    canvas.drawCircle(
        Offset(_circleOffset, _circleOffset), _outlineCircleWidth, paint);
  }

  /// Paints the icon
  void _paintIcon(Canvas canvas, Color color, IconData iconData) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          letterSpacing: 0.0,
          fontSize: _iconSize,
          fontFamily: iconData.fontFamily,
          color: color,
        ));
    textPainter.layout();
    textPainter.paint(canvas, Offset(_iconOffset, _iconOffset));
  }
}
