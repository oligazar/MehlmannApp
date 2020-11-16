import 'package:mahlmann_app/common/api/api_client.dart';
import 'package:mahlmann_app/common/interfaces/disposable.dart';

class BlocPreloader extends Disposable {
	final _api = ApiClient();
	final Function _onFetched;
	
  BlocPreloader(this._onFetched) {
	  print("BlocPreloader");
	  _startFetching();
  }
	
	Future<void> _fetchAndSaveFields() async {
		final response = await _api.fetchFieldsResponse();
		// TODO:
		// await _db.insertFields(response.fields, shouldClearTable: true);
		// await _db.insertUsers(response.users, shouldClearTable: true);
		// await _db.insertFountains(response.fountains, shouldClearTable: true);
		print("articles updated successfully, size: $response");
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