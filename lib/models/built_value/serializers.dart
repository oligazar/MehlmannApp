import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:mahlmann_app/models/built_value/comment.dart';
import 'package:mahlmann_app/models/built_value/coordinate.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/built_value/fountain.dart';
import 'package:mahlmann_app/models/built_value/group.dart';
import 'package:mahlmann_app/models/built_value/measurements.dart';
import 'package:mahlmann_app/models/built_value/objects_response.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mahlmann_app/models/built_value/path_point.dart';

part 'serializers.g.dart';

@SerializersFor(const [
  Field,
	Coordinate,
	Fountain,
	Comment,
	Group,
	ObjectsResponse,
	Measurements,
	// PathPoint,
])
final Serializers serializers =
      (_$serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();