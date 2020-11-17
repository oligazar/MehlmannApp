library fountain;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/interfaces/time_saveable.dart';
import 'package:mahlmann_app/models/built_value/serializers.dart';
part 'fountain.g.dart';

abstract class Fountain implements Built<Fountain, FountainBuilder>, TimeSaveable {
  
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

  @nullable
  @BuiltValueField(wireName: COL_SAVE_TIME)
  int get saveTime;
  
  Fountain._();

  Map<String, dynamic> toMap() {
    return serializers.serializeWith(Fountain.serializer, this);
  }

  static Fountain fromMap(Map<String, dynamic> map) {
    return serializers.deserializeWith(Fountain.serializer, map);
  }

  static List<String> get  queryColumns => Fountain().toMap().keys.toList();
  
  factory Fountain([updates(FountainBuilder b)]) = _$Fountain;
  static Serializer<Fountain> get serializer => _$fountainSerializer;

  static String tableCreator = '''
              CREATE TABLE $TABLE_FOUNTAINS (
                $COL_ID INTEGER PRIMARY KEY,
                $COL_NAME TEXT,
                $COL_LATITUDE REAL,
                $COL_LONGITUDE REAL,
                $COL_COLOR TEXT,
                $COL_SAVE_TIME INTEGER
              )
              ''';
}