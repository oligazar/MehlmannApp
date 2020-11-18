extension FieldValidator on String {
	
	String ifEmpty(String text) => text?.isNotEmpty == true ? null : this;
	
	String ifInvalidEmail(String text) {
		if (text == null) return this;
		Pattern pattern =
				r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
		RegExp regex = new RegExp(pattern);
		return !regex.hasMatch(text) ? this : null;
	}
	
	String ifLessThan(String text, {int length = 5}) => (text?.length ?? 0) < length ? this : null;

// String ifNotNumber(String text) {
// 	if (text == null) return this;
// 	final normalizedString = text.dotify();
// 	return Decimal.tryParse(normalizedString) == null ? this : null;
// }
}