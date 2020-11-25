library comment;

import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:mahlmann_app/models/built_value/serializers.dart';
part 'comment.g.dart';

abstract class Comment implements Built<Comment, CommentBuilder> {
  
  @nullable
  int get id;
  
  @nullable
  String get user;
  
  @nullable
  String get text;
  
  Comment._();
  
  Map<String, dynamic> toMap() {
    return serializers.serializeWith(Comment.serializer, this);
  }

  static Comment fromMap(Map<String, dynamic> map) {
    return serializers.deserializeWith(Comment.serializer, map);
  }
  
  factory Comment([updates(CommentBuilder b)]) = _$Comment;
  static Serializer<Comment> get serializer => _$commentSerializer;
}