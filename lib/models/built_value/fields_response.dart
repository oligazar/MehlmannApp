library fields_response;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/built_value/fountain.dart';
import 'package:mahlmann_app/models/built_value/serializers.dart';
import 'package:mahlmann_app/models/built_value/user.dart';
part 'fields_response.g.dart';

abstract class FieldsResponse implements Built<FieldsResponse, FieldsResponseBuilder> {
  
  @nullable
  BuiltList<Field> get fields;

  @nullable
  BuiltList<User> get users;

  // @nullable
  // @BuiltValueField(wireName: 'group_ids')
  // BuiltList<Coordinate> get groupIds;

  @nullable
  BuiltList<Fountain> get fountains;
  
  FieldsResponse._();
  
  Map<String, dynamic> toMap() {
    return serializers.serializeWith(FieldsResponse.serializer, this);
  }

  static FieldsResponse fromMap(Map<String, dynamic> map) {
    return serializers.deserializeWith(FieldsResponse.serializer, map);
  }
  
  factory FieldsResponse([updates(FieldsResponseBuilder b)]) = _$FieldsResponse;
  static Serializer<FieldsResponse> get serializer => _$fieldsResponseSerializer;
}