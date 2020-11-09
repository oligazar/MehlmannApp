
import 'package:mahlmann_app/common/interfaces/disposable.dart';
import 'package:mahlmann_app/models/login_response.dart';

class BlocLogin extends Disposable {
  String email;
  String pass;

  var userLogin;

	@override
	void dispose() {
		// TODO: implement dispose
	}

  Future<LoginResponse> auth() async {
		return Future.value(LoginResponse());
  }
}