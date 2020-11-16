library user;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:mahlmann_app/models/built_value/serializers.dart';
part 'user.g.dart';

abstract class User implements Built<User, UserBuilder> {
  int get id;
  String get email;
  
  User._();

  Map<String, dynamic> toMap() {
    return serializers.serializeWith(User.serializer, this);
  }

  static User fromMap(Map<String, dynamic> map) {
    return serializers.deserializeWith(User.serializer, map);
  }
  
  factory User([updates(UserBuilder b)]) = _$User;
  static Serializer<User> get serializer => _$userSerializer;
}


