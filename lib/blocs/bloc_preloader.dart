import 'package:mahlmann_app/common/api/api_client.dart';
import 'package:mahlmann_app/common/date_formatter.dart';
import 'package:mahlmann_app/common/interfaces/disposable.dart';
import 'package:mahlmann_app/common/interfaces/exception_handleable.dart';
import 'package:mahlmann_app/common/prefs.dart';
import 'package:mahlmann_app/common/sqlite/db_client.dart';
import 'package:rxdart/rxdart.dart' as rx;

class BlocPreloader extends ExceptionHandleable implements Disposable {
	final _api = ApiClient();
	final _db = DbClient();
	final Function _onFetched;
	
	
	final _exception = rx.BehaviorSubject<Exception>();
	@override
	Stream<Exception> get exception => _exception.stream;
	
  BlocPreloader(this._onFetched) {
	  print("BlocPreloader");
	  _startFetching();
  }
	
	Future<void> _fetchAndSaveFields() async {
		final response = await _api.fetchObjects(from: await Prefs.lastUpdate).catchError(_exception.add);
  	await Prefs.saveLastUpdate(await DateFormatter.getTimeStringAsync());
		
		await _db.insertFountains(response.fountains.toList(), shouldClearTable: false);
		await _db.insertFields(response.fields.toList(), shouldClearTable: false);
		await _db.insertGroups(response.groups.toList(), shouldClearTable: false);
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
	  _exception.close();
  }
	
}