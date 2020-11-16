import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:mahlmann_app/models/built_value/coordinate.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/built_value/fields_response.dart';
import 'package:mahlmann_app/models/built_value/fountain.dart';
import 'package:mahlmann_app/models/built_value/user.dart';
import 'package:built_collection/built_collection.dart';

part 'serializers.g.dart';

@SerializersFor(const [
  Field,
	Coordinate,
	User,
	Fountain,
	FieldsResponse
])
final Serializers serializers =
      (_$serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();