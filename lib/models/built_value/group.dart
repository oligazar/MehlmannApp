library group;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/interfaces/time_saveable.dart';
import 'package:mahlmann_app/models/built_value/serializers.dart';

part 'group.g.dart';

abstract class Group implements Built<Group, GroupBuilder>, TimeSaveable {
  @nullable
  int get id;

  @nullable
  String get name;

  @nullable
  BuiltList<int> get fieldIds;

  @nullable
  @BuiltValueField(wireName: COL_SAVE_TIME)
  int get saveTime;

  Group._();

  static List<String> get queryColumns => Group().toMap().keys.toList();

  Map<String, dynamic> toDb() {
    final map = this.toMap();
    return map..[COL_FIELD_IDS] = json.encode(map[COL_FIELD_IDS]);
  }

  static Group fromDb(Map<String, dynamic> map) =>
      fromMap(Map<String, dynamic>.from(map)
        ..[COL_FIELD_IDS] = json.decode(map[COL_FIELD_IDS]));

  Map<String, dynamic> toMap() {
    return serializers.serializeWith(Group.serializer, this);
  }

  static Group fromMap(Map<String, dynamic> map) {
    return serializers.deserializeWith(Group.serializer, map);
  }

  factory Group([updates(GroupBuilder b)]) = _$Group;

  static Serializer<Group> get serializer => _$groupSerializer;

  static String tableCreator = '''
              CREATE TABLE $TABLE_GROUPS (
                $COL_ID INTEGER PRIMARY KEY,
                $COL_NAME TEXT,
                $COL_FIELD_IDS TEXT,
                $COL_SAVE_TIME INTEGER
              )
              ''';
}
