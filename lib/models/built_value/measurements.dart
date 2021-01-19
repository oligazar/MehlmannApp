library measurements;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:mahlmann_app/models/built_value/serializers.dart';
part 'measurements.g.dart';

abstract class Measurements implements Built<Measurements, MeasurementsBuilder> {
 
	@nullable
  double get area;
	
  @nullable
  double get distance;
  
  @nullable
  double get lastSegment;
  
  Measurements._();
  
  Map<String, dynamic> toMap() {
    return serializers.serializeWith(Measurements.serializer, this);
  }

  static Measurements fromMap(Map<String, dynamic> map) {
    return serializers.deserializeWith(Measurements.serializer, map);
  }
  
  factory Measurements([updates(MeasurementsBuilder b)]) = _$Measurements;
  static Serializer<Measurements> get serializer => _$measurementsSerializer;
}