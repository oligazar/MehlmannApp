library fountain;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:mahlmann_app/models/built_value/serializers.dart';
part 'fountain.g.dart';

abstract class Fountain implements Built<Fountain, FountainBuilder> {
  
  @nullable
  int get id;
  
  @nullable
  String get name;
  
  @nullable
  double get latitude;
  
  @nullable
  double get longitude;
  
  @nullable
  String get color;
  
  
  Fountain._();

  Map<String, dynamic> toMap() {
    return serializers.serializeWith(Fountain.serializer, this);
  }

  static Fountain fromMap(Map<String, dynamic> map) {
    return serializers.deserializeWith(Fountain.serializer, map);
  }
  
  factory Fountain([updates(FountainBuilder b)]) = _$Fountain;
  static Serializer<Fountain> get serializer => _$fountainSerializer;
}