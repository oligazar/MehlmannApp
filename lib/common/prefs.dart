import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/models/login_response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
	
  static Future<String> get lastUpdate async {
	  final pref = await sp;
	  return pref.getString(PREF_LAST_UPDATE);
  }
  
  static Future saveLastUpdate(String timeString) async {
	  final pref = await sp;
	  return pref.setString(PREF_LAST_UPDATE, timeString);
  }
  
	static Future<bool> get isProdPref async {
		final pref = await sp;
		final backend = pref.getString(PREF_BACKEND);
		
		if (backend != null) {
			return backend == PROD;
		} else {
			pref.setString(PREF_BACKEND, PROD);
			return true;
		}
	}
	
	static Future<SharedPreferences> get sp async => await SharedPreferences.getInstance();
	
  static Future<String> get token async => sp.then((sp) => sp.getString(PREF_TOKEN));
  
  static Future<bool> get isAuthorized async => token.then((token) => token != null);

  static Future<Map<String, String>> get autoFill async {
	  final SharedPreferences pref = await sp;
	  // Managed configuration keys: 'username' & 'password"
	  return  {
	  	"email": pref.getString("username"),
	  	"password": pref.getString("password"),
	  };
  }

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
		pref.remove(PREF_LAST_UPDATE);
	}
}