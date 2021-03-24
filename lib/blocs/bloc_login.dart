import 'package:flutter/widgets.dart';
import 'package:mahlmann_app/common/api/api_client.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/prefs.dart';
import 'package:mahlmann_app/models/response_wrapper.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:mahlmann_app/common/interfaces/disposable.dart';
import 'package:mahlmann_app/models/login_response.dart';
import 'package:mahlmann_app/common/extensions.dart';

class BlocLogin extends Disposable {
  String _email;
  String pass;
  final _api = ApiClient();
  final _userLogin = rx.BehaviorSubject<ResponseWrapper<LoginResponse>>();
  final _showBackendSettings = rx.BehaviorSubject<bool>.seeded(false);

  Stream<bool> get showBackendSettings => _showBackendSettings.stream;
  Stream<ResponseWrapper<LoginResponse>> get userLogin => _userLogin.stream;

	@override
	void dispose() {
		_userLogin.close();
		_showBackendSettings.close();
	}
	
	set email(String val) {
		_email = val;
		_showBackendSettings.add(val.startsWith(TEST_PREFIX));
	}

  Future<LoginResponse> auth(BuildContext context) async {
	  print("email: $_email, pass: $pass");
	  _userLogin.add(ResponseWrapper.loading());
	
	  return _api.logIn(_email, pass).then((resp) {
		  print("LoginResponse: $resp");
		  // save token to shared prefs
		  if (resp.version == API_VERSION) {
			  Prefs.saveLoginResponse(resp);
			  _userLogin.add(ResponseWrapper.success(resp));
			  return resp;
		  } else {
			  _userLogin.add(ResponseWrapper.error(context.loc.wrongVersion));
			  return null;
		  }
	  }).catchError((error) {
		  print(error);
		  _userLogin.add(ResponseWrapper.error(null));
		  return null;
	  });
  }
}