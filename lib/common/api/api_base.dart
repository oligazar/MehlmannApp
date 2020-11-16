import 'package:dio/dio.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/prefs.dart';
import 'package:uuid/uuid.dart';

class TokenExpiredException implements Exception {
  String message;

  TokenExpiredException([this.message]);
}

Future<dynamic> getToken() async => Future.value({});

String baseAuthority = AUTHORITY_PRODUCTION;

class ApiBase {
  final client = Dio();
  final uuid = Uuid();

  Future<dynamic> get headers async {
    final data = await Prefs.getLoginResponse();
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (data != null) {
      headers['uid'] = data.email;
      headers['client'] = data.token;
      headers['expiry'] = data.expiry?.toString();
    }

    return headers;
  }

  Uri buildUri(
    String method, [
    Map<String, String> queryParameters,
    String authority,
  ]) {
    Uri uri;
    final auth = authority ?? baseAuthority;
    
    if (queryParameters != null) {
      uri = Uri.https(auth, method, queryParameters);
    } else {
      uri = Uri.https(auth, method);
    }
    print("uri: $uri");
    return uri;
  }

  /// Clean unused code

// 	Future<String> get appVersion async {
// 		final packageInfo = await PackageInfo.fromPlatform();
// 		return packageInfo.version;
// 	}
//
// //  Future<Map<String, String>> getDefaultParams() async => defaultGetParams;
//
// 	Future<Map<String, String>> get defaultGetParams async => defaultPostParams
// 		..then((p) => p..["request_id"] = uuid.v4());
//
// 	Future<Map<String, String>> get defaultPostParams async {
// 		final version = await appVersion;
//
// 		print("app_version: $version");
//
// 		return {
// 			"app_version": version,
// 			"app_platform": Platform.isIOS ? 'iOS' : 'Android',
// 		};
// 	}
//
//
// 	Map<String, String> get postHeaders =>
// 			{'Content-Type': 'application/json', 'accept': 'application/json'};
//
// 	Future<Map<String, String>> get v4Headers async => {};
// 			// PrefHelper.getLoginResponse().then((resp) => postHeaders
// 			// 	..addAll({
// 			// 		"Authorization": "Token ${resp.token}",
// 			// 	}));
//

//
// 	dynamic responseToJson(Response resp) {
// 		final body = resp.data;
// 		print("body: $body}");
// 		if (body == null || body.isEmpty) return;
//
// 		final jsonBody = json.decode(body);
// 		print("jsonBody: $jsonBody");
// 		final jsonBodyNoError = _handleErrorJson(jsonBody);
// 		print("jsonBodyNoError: $jsonBodyNoError");
// 		return jsonBodyNoError;
// 	}
//
// 	Future<dio.Response<T>> put<T>(
// 			Uri url, {
// 				Map<String, String> headers,
// 				String body,
// 				int receiveTimeout = RECEIVE_TIMEOUT,
// 				int sendTimeout = SEND_TIMEOUT,
// 			}) {
// 		final options = dio.Options(
// 			headers: headers,
// 			receiveTimeout: receiveTimeout,
// 			sendTimeout: sendTimeout,
// 		);
// 		return dioClient.putUri<T>(url, data: body, options: options);
// 	}
//
// 	dynamic _handleErrorJson(json) {
// 		dynamic error;
// 		try {
// 			error = json["error"];
// 		} catch (e) {
// 			print(e);
// 			return json;
// 		}
// 		if (error != null) {
// 			print("error: $error");
// 			if (error == "Der Anmelde-Token ist ungültig.") {
// 				throw TokenExpiredException(error);
// 			}
// 			throw Exception(error);
// 		}
// 		return json;
// 	}
}
