library user;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/interfaces/time_saveable.dart';
import 'package:mahlmann_app/models/built_value/serializers.dart';

part 'user.g.dart';

abstract class User implements Built<User, UserBuilder>, TimeSaveable {
  
  @nullable
  int get id;

  @nullable
  String get email;

  @nullable
  @BuiltValueField(wireName: COL_SAVE_TIME)
  int get saveTime;
  
  User._();

  Map<String, dynamic> toMap() {
    return serializers.serializeWith(User.serializer, this);
  }

  static User fromMap(Map<String, dynamic> map) {
    return serializers.deserializeWith(User.serializer, map);
  }

  static List<String> get  queryColumns => User().toMap().keys.toList();
  
  factory User([updates(UserBuilder b)]) = _$User;
  static Serializer<User> get serializer => _$userSerializer;

  static String tableCreator = '''
              CREATE TABLE $TABLE_USERS (
                $COL_ID INTEGER PRIMARY KEY,
                $COL_EMAIL TEXT,
                $COL_SAVE_TIME INTEGER
              )
              ''';
}


