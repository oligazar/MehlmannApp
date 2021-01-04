import 'package:intl/intl.dart';
import 'package:date_formatter_plugin/date_formatter_plugin.dart';

class DateFormatter {
	
	static const dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ";
	static const standardFormat = "yyyy-MM-dd";
	static const dateFormatNoTimeZone = "yyyy-MM-dd'T'HH:mm:ss";
	
	static Future<String> getTimeStringAsync({DateTime dateTime, String format = dateFormat}) async {
		final date = dateTime ?? DateTime.now();
		try {
			final formattedString = DateFormatterPlugin.getFormattedDate(date.millisecondsSinceEpoch, format);
			print("DateFormatter.getTimeStringAsync, formattedDateString: $formattedString");
			if (formattedString != null) return formattedString;
		} catch (e) {
			print(e);
		}
		return DateFormat(dateFormatNoTimeZone).format(DateTime.now());
	}
	
	// 2020-11-06T14:19:03.426Z
	static DateTime parseTimeString(String dateString, {String format = dateFormat}) {
		if (dateString == null) return null;
		try {
			return DateFormat(format).parse(dateString);
		} catch (e) {
			print(e);
		}
		return DateTime.parse(dateString);
	}
}