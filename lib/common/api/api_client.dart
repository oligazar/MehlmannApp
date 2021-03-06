import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mahlmann_app/common/api/api_base.dart';
import 'package:mahlmann_app/models/built_value/comment.dart';
import 'package:mahlmann_app/models/built_value/objects_response.dart';
import 'package:mahlmann_app/models/login_response.dart';
import 'package:mahlmann_app/common/extensions.dart';

class ApiClient extends ApiBase {
  
  Future<LoginResponse> logIn(String email, String password) async {
    print('logIn');
    final url = buildUri("/api/v1/auth/sign_in");
    final data = {"email": email, "password": password};

    final response = await client.postUri(url,
        data: json.encode(data), options: Options(headers: await headers));
    final map = response.headers.map;

    print("done!");
    return LoginResponse(
      token: map['client'].firstOrNull,
      email: map['uid'].firstOrNull,
      expiry: map['expiry'].firstOrNull?.toIntOrNull,
      admin: map['admin'].firstOrNull?.toBoolOrNull,
      version: response.data["data"]["version"],
    );
  }

  Future<ObjectsResponse> fetchObjects({String from}) async {
    print('fetchObjects');
    final query = from != null ? {
      "from": from
    } : null;
    final url = buildUri("/api/v1/objects", query);
    final h = await headers;
    print("headers: $h");
  
    final response = await client.getUri(url, options: Options(headers: h));
    // final list = response.data["fields"]?.map((f) => Field.fromMap(f))?.toList() ?? [];
    // final fields = List<Field>.from(list);
  
    // print("Example how to parse fields: $fields");
  
    return ObjectsResponse.fromMap(response.data);
  }

  Future<List<Comment>> fetchComments(int fieldId) async {
    print('fetchComments');
    final url = buildUri("/api/v1/fields/$fieldId/comments");
    final h = await headers;

    final response = await client.getUri(url, options: Options(headers: h));
    final list = response.data["comments"]?.map((f) => Comment.fromMap(f))?.toList() ?? [];

    final comments = List<Comment>.from(list);

    return comments;
  }

  Future<Comment> createComment(int fieldId, String text) async {
    print('createComment');
    final url = buildUri("/api/v1/fields/$fieldId/comments");
    final data = {"text": text};

    final response = await client.postUri(url,
        data: json.encode(data), options: Options(headers: await headers));
    // print("response: $response");
    if (response.data["status"] == "success") {
      return Comment.fromMap(response.data["body"]);
    } else {
      return null;
    }
  }

  // Future<List<Group>> fetchGroups() async {
  //   print('fetchGroups');
  //   final url = buildUri("/api/v1/groups");
  //
  //   final response =
  //       await client.getUri(url, options: Options(headers: await headers));
  //
  //   return List<Group>.from(
  //       response.data["groups"]?.map((f) => Group.fromMap(f))?.toList() ?? []);
  // }

  Future createGroup(String name, List<int> fieldIds) async {
    print('createGroup');
    final url = buildUri("/api/v1/groups");
    final data = {"name": name, "fieldIds": fieldIds};
  
    final response = await client.postUri(url,
        data: json.encode(data), options: Options(headers: await headers));
    print("response: $response");
  }

}
