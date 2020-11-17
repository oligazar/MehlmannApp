library field;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/interfaces/time_saveable.dart';
import 'package:mahlmann_app/models/built_value/coordinate.dart';
import 'package:mahlmann_app/models/built_value/serializers.dart';

part 'field.g.dart';

abstract class Field implements Built<Field, FieldBuilder>, TimeSaveable {
  @nullable
  int get id;

  @nullable
  String get name;

  @nullable
  String get status;

  @nullable
  @BuiltValueField(wireName: COL_IS_CABBAGE)
  String get isCabbage;

  @nullable
  String get note;

  @nullable
  @BuiltValueField(wireName: COL_AREA_SIZE)
  double get areaSize;

  @nullable
  BuiltList<Coordinate> get coordinates;

  @nullable
  @BuiltValueField(wireName: COL_SAVE_TIME)
  int get saveTime;

  Field._();

  factory Field([updates(FieldBuilder b)]) = _$Field;

  static List<String> get queryColumns => Field().toMap().keys.toList();

  Map<String, dynamic> toDb() {
    final map = this.toMap();
    return map..[COL_COORDINATES] = json.encode(map[COL_COORDINATES]);
  }

  static Field fromDb(Map<String, dynamic> map) =>
      fromMap(Map<String, dynamic>.from(map)
        ..[COL_COORDINATES] = json.decode(map[COL_COORDINATES]));

  Map<String, dynamic> toMap() {
    return serializers.serializeWith(Field.serializer, this);
  }

  static Field fromMap(Map<String, dynamic> map) {
    return serializers.deserializeWith(Field.serializer, map);
  }

  String toJson() {
    return json.encode(serializers.serializeWith(Field.serializer, this));
  }

  static Field fromJson(String jsonString) {
    return serializers.serializeWith(Field.serializer, json.decode(jsonString));
  }

  static Serializer<Field> get serializer => _$fieldSerializer;

  static String tableCreator = '''
              CREATE TABLE $TABLE_FIELDS (
                $COL_ID INTEGER PRIMARY KEY,
                $COL_NAME TEXT,
                $COL_STATUS TEXT,
                $COL_IS_CABBAGE TEXT,
                $COL_NOTE TEXT,
                $COL_AREA_SIZE REAL,
                $COL_COORDINATES TEXT,
                $COL_SAVE_TIME INTEGER
              )
              ''';
}
