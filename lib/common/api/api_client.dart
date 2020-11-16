
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mahlmann_app/common/api/api_base.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/models/built_value/fields_response.dart';
import 'package:mahlmann_app/models/login_response.dart';
import 'package:mahlmann_app/common/extensions.dart';

class ApiClient extends ApiBase {
	
	Future<LoginResponse> logIn(String email, String password) async {
		print('logIn');
		final url = buildUri("/api/v1/auth/sign_in");
		final data = {
			"email": email,
			"password": password
		};
		
		final response = await client
				.postUri(url, data: json.encode(data), options: Options(headers: await headers));
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
		print('fetchFields');
		final url = buildUri("/api/v1/fields");
		final h = await headers;
		
		final response = await client
				.getUri(url, options: Options(headers: h));
		
		final fields = List<Field>.from(response.data["fields"].map((f) => Field.fromMap(f)).toList());
		print("Example how to parse fields: $fields");
		
		return FieldsResponse.fromMap(response.data);
	}
	
// 	export const createComment = async (fieldId, text) => {
// 	return post(`/fields/${fieldId}/comments`, {
// 	text,
// 	})
// 	};
//
// 	export const setField = async (name, fieldIds) => {
// 	return post('/fields/set_fields', {
// 	name, fieldIds,
// 	})
// 	};
//
// 	export const getComments = async (fieldId) => {
// 	return get(`/fields/${fieldId}/comments`);
// 	};
//
// 	export const getGroups = async () => {
// 	return get(`/groups`);
// 	};
//
// export const loginGet = (uid, client, token, expiry) => {
// return get(`/auth/validate_token?uid=${uid}&client=${client}&access-token=${token}&expiry=${expiry}&token-type=Bearer&Content-Type=application/json&Accept=application/json`, true)
// };
//
// export const createAccount = (email, password) => {
// return post('/users', {
// user: { email, password },
// });
// };
}