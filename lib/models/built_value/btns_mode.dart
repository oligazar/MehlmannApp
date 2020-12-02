library btns_mode;

import 'package:built_value/built_value.dart';
import 'package:built_collection/built_collection.dart';

part 'btns_mode.g.dart';

class BtnsMode extends EnumClass {
	static const BtnsMode none = _$none;
	static const BtnsMode measureArea = _$measureArea;
	static const BtnsMode measureDistance = _$measureDistance;
	
	static const BtnsMode search = _$search;
	static const BtnsMode selectSentence = _$selectSentence;
	static const BtnsMode createSentence = _$createSentence; // grouping
	
	const BtnsMode._(String name): super(name);
	
  static BuiltSet<BtnsMode> get values => _$values;
	static BtnsMode valueOf(String name) => _$valueOf(name);
}