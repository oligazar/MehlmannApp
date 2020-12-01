import 'package:mahlmann_app/common/api/api_client.dart';
import 'package:mahlmann_app/common/interfaces/disposable.dart';
import 'package:mahlmann_app/common/sqlite/db_client.dart';

class BlocPreloader extends Disposable {
	final _api = ApiClient();
	final _db = DbClient();
	final Function _onFetched;
	
  BlocPreloader(this._onFetched) {
	  print("BlocPreloader");
	  _startFetching();
  }
	
	Future<void> _fetchAndSaveFields() async {
		final response = await _api.fetchFieldsResponse();
		
		await _db.insertUsers(response.users.toList());
		await _db.insertFountains(response.fountains.toList());
		await _db.insertFields(response.fields.toList());
		
		// final users = await _db.queryUsers();
		// final fountains = await _db.queryFountains();
		// final fields = await _db.queryFields();
		
		// print("users: $users");
		// print("fountains: $fountains");
		// print("fields: $fields");
		// print("articles updated successfully, size: $response");
	}
	
	_startFetching() async {
		print("startFetching");
		final fetchers = [
			_fetchAndSaveFields().catchError(print),
		];
		await Future.wait(fetchers);
		print("endFetching");
		_onFetched();
	}
	
  @override
  void dispose() {
    // NOOP
  }
	
}