library field;

import 'dart:convert';

import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:mahlmann_app/models/built_value/coordinate.dart';
import 'package:mahlmann_app/models/built_value/serializers.dart';
part 'field.g.dart';


abstract class Field implements Built<Field, FieldBuilder> {

	int get id;
	
	@nullable
	String get name;
	
	@nullable
	String get status;
	
	@nullable
	@BuiltValueField(wireName: 'is_cabbage')
	String get isCabbage;
	
	@nullable
	String get note;
	
	@nullable
	@BuiltValueField(wireName: 'area_size')
	double get areaSize;
	
	@nullable
	BuiltList<Coordinate> get coordinates;
	
	Field._();
	
	factory Field([updates(FieldBuilder b)]) = _$Field;
	
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
}

