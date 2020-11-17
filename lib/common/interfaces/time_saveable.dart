import 'package:mahlmann_app/common/interfaces/db_saveable.dart';

abstract class TimeSaveable extends DBSaveable {
	
	int get saveTime;
	
}

extension TimeSaveableExt on TimeSaveable {
	
	bool shouldFetch({int intervalMinutes = 30}) {
		final difference = DateTime.now().millisecondsSinceEpoch - saveTime;
		final threshold = intervalMinutes * 60 * 1000;
		final shouldFetch = difference > threshold;
		return shouldFetch;
	}
}