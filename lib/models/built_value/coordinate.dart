library coordinate;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
part 'coordinate.g.dart';

abstract class Coordinate implements Built<Coordinate, CoordinateBuilder> {
  
  @nullable
  double get latitude;
  
  @nullable
  double get longitude;
  
  Coordinate._();
  
  factory Coordinate([updates(CoordinateBuilder b)]) = _$Coordinate;
  static Serializer<Coordinate> get serializer => _$coordinateSerializer;
}