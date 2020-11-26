import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mahlmann_app/common/api/api_base.dart';
import 'package:mahlmann_app/models/built_value/comment.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/built_value/fields_response.dart';
import 'package:mahlmann_app/models/built_value/group.dart';
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
    );
  }

  Future<FieldsResponse> fetchFieldsResponse() async {
    print('fetchFieldsResponse');
    final url = buildUri("/api/v1/fields");
    final h = await headers;

    final response = await client.getUri(url, options: Options(headers: h));
    final list = response.data["fields"]?.map((f) => Field.fromMap(f))?.toList() ?? [];
    final fields = List<Field>.from(list);
    
    print("Example how to parse fields: $fields");

    return FieldsResponse.fromMap(response.data);
  }

  Future setFields(String name, List<int> fieldIds) async {
    print('setFields');
    final url = buildUri("/api/v1/fields/set_fields");
    final data = {"name": name, "fieldIds": fieldIds};

    final response = await client.postUri(url,
        data: json.encode(data), options: Options(headers: await headers));
    print("response: $response");
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
    print("response: $response");
    if (response.data["status"] == "success") {
      return Comment.fromMap(response.data["body"]);
    } else {
      return null;
    }
  }

  Future<List<Group>> fetchGroups() async {
    print('fetchGroups');
    final url = buildUri("/api/v1/groups");

    final response =
        await client.getUri(url, options: Options(headers: await headers));

    return List<Group>.from(
        response.data["groups"]?.map((f) => Group.fromMap(f))?.toList() ?? []);
  }

// export const loginGet = (uid, client, token, expiry) => {
// return get(`/auth/validate_token?uid=${uid}&client=${client}&access-token=${token}&expiry=${expiry}&token-type=Bearer&Content-Type=application/json&Accept=application/json`, true)
// };
  Future loginGet(String uid, String _client, String token, int expiry) async {
    print('loginGet');
    final params = {
      "uid": uid,
      "client": _client,
      "access-token": token,
      "expiry": expiry,
      "token-type": "Bearer",
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    final url = buildUri("/api/v1/auth/validate_token", params);

    final response =
        await client.getUri(url, options: Options(headers: await headers));

    // som kind of parsing
    final comments = List<Comment>.from(
        response.data.map((f) => Comment.fromMap(f)).toList());

    return comments;
  }
	
// export const createAccount = (email, password) => {
// return post('/users', {
// user: { email, password },
// });
// };
  Future createAccount(String email, String password) async {
    print('createAccount');
    final url = buildUri("/api/v1/users");
    final data = {
      "email": email,
      "password": password,
    };

    final response = await client.postUri(url,
        data: json.encode(data), options: Options(headers: await headers));
    print("response: $response");
  }

}
