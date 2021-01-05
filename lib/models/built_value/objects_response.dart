library objects_response;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/built_value/fountain.dart';
import 'package:mahlmann_app/models/built_value/group.dart';
import 'package:mahlmann_app/models/built_value/serializers.dart';
part 'objects_response.g.dart';


abstract class ObjectsResponse implements Built<ObjectsResponse, ObjectsResponseBuilder> {
	
	@nullable
  BuiltList<Field> get fields;

  @nullable
  BuiltList<Fountain> get fountains;

  @nullable
  BuiltList<Group> get groups;
	
  ObjectsResponse._();
  
  Map<String, dynamic> toMap() {
    return serializers.serializeWith(ObjectsResponse.serializer, this);
  }

  static ObjectsResponse fromMap(Map<String, dynamic> map) {
    return serializers.deserializeWith(ObjectsResponse.serializer, map);
  }
  
  factory ObjectsResponse([updates(ObjectsResponseBuilder b)]) = _$ObjectsResponse;
  static Serializer<ObjectsResponse> get serializer => _$objectsResponseSerializer;
}