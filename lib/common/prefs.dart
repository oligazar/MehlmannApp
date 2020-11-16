import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/models/login_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
	
	static Future<SharedPreferences> get sp async => await SharedPreferences.getInstance();
	
  static Future<String> get token async => sp.then((sp) => sp.getString(PREF_TOKEN));
  
  static Future<bool> get isAuthorized async => token.then((token) => token != null);

  static Future<void> saveLoginResponse(LoginResponse resp) async {
	  final SharedPreferences pref = await sp;
	  pref.setString(PREF_TOKEN, resp.token);
	  pref.setString(PREF_EMAIL, resp.email);
	  pref.setInt(PREF_EXPIRY, resp.expiry);
	  pref.setBool(PREF_ADMIN, resp.admin);
  }
	
	static Future<LoginResponse> getLoginResponse() async {
		final SharedPreferences pref = await sp;
		return LoginResponse(
			token: pref.getString(PREF_TOKEN),
			email: pref.getString(PREF_EMAIL),
			expiry: pref.getInt(PREF_EXPIRY),
			admin: pref.getBool(PREF_ADMIN),
		);
	}
	
	static logout() async {
		final SharedPreferences pref = await sp;
		pref.remove(PREF_TOKEN);
		pref.remove(PREF_EMAIL);
		pref.remove(PREF_EXPIRY);
		pref.remove(PREF_ADMIN);
	}
}