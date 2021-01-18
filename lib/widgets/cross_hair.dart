
import 'package:flutter/material.dart';

class CrossHair extends CustomPainter {
	final Color c1;
	final Color c2;
	
	const CrossHair(this.c1, this.c2);
	
	@override
	void paint(Canvas canvas, Size size) {
		final redPaint = Paint()
			..style = PaintingStyle.stroke
			..strokeWidth = 1
			..color = c1;
		
		final greenPaint = Paint()
			..style = PaintingStyle.stroke
			..strokeWidth = 1.5
			..color = c2;
		
		final greenFillPaint = Paint()
			..style = PaintingStyle.fill
			..color = c2;
		
		final w = size.width;
		final h = size.height;
		
		final hw = w / 2;
		final hh = h / 2;
		
		final s1 = w / 3.5;
		final s2 = w / 2.4;
		
		final s3 = w / 2.85;
		
		final s4 = 3.0;
		
		final pathRed = Path()
			..addPolygon([Offset(s1, s1), Offset(s2, s2)], false)..addPolygon(
					[Offset(w - s2, s2), Offset(w - s1, s1)], false)..addPolygon(
					[Offset(s1, h - s1), Offset(s2, h - s2)], false)..addPolygon(
					[Offset(w - s2, h - s2), Offset(w - s1, h - s1)], false)..addPolygon(
					[Offset(hw, 0), Offset(hw, s3)], false)..addPolygon(
					[Offset(w - s3, hh), Offset(w, hw)], false)..addPolygon(
					[Offset(hw, h - s3), Offset(hw, h)], false)..addPolygon(
					[Offset(0, hh), Offset(s3, hh)], false);
		
		final pathGreenOutline = Path()
			..addRect(
				Rect.fromCenter(
						center: Offset(w / 2, h / 2),
						width: w - s1 * 2,
						height: h - s1 * 2),
			);
		
		final greenPath = Path()
			..addRect(_drawRect(Offset(hw, hh - s4), s4, s4))..addRect(
					_drawRect(Offset(hw + s4, hh), s4, s4))..addRect(
					_drawRect(Offset(hw, hh + s4), s4, s4))..addRect(
					_drawRect(Offset(hw - s4, hh), s4, s4));
		
		// draw shadow
		_drawShadow(canvas, greenPath);
		_drawShadow(canvas, pathGreenOutline);
		_drawShadow(canvas, pathRed);
		
		canvas.drawPath(
			pathRed,
			redPaint,
		);
		
		canvas.drawPath(
			greenPath,
			greenFillPaint,
		);
		
		canvas.drawPath(
			pathGreenOutline,
			greenPaint,
		);
	}
	
	@override
	bool shouldRepaint(CustomPainter oldDelegate) => false;
	
	void _drawShadow(Canvas canvas, Path path) {
		canvas.drawPath(
			path.shift(Offset(1.5, 1)),
			Paint()
				..color = Colors.black.withAlpha(60)
				..style = PaintingStyle.stroke
				..strokeWidth = 1.5
				..maskFilter =
				MaskFilter.blur(BlurStyle.normal, _convertRadiusToSigma(0.5)),
		);
	}
	
	Rect _drawRect(Offset center, double width, double height) {
		return Rect.fromCenter(center: center, width: width, height: height);
	}
	
	static double _convertRadiusToSigma(double radius) {
		return radius * 0.57735 + 0.5;
	}
}
