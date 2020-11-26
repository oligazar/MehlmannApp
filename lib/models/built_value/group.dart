library group;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mahlmann_app/models/built_value/serializers.dart';
part 'group.g.dart';

abstract class Group implements Built<Group, GroupBuilder> {
	
	@nullable
	int get id;
	
	@nullable
	String get name;
	
  @nullable
  BuiltList<int> get fieldIds;
  
  Group._();
  
  Map<String, dynamic> toMap() {
    return serializers.serializeWith(Group.serializer, this);
  }

  static Group fromMap(Map<String, dynamic> map) {
    return serializers.deserializeWith(Group.serializer, map);
  }
  
  factory Group([updates(GroupBuilder b)]) = _$Group;
  static Serializer<Group> get serializer => _$groupSerializer;
}