import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapOpener {
	
	static List<String> buildMapUrlsXxx({String address, LatLng location}) {
		// https://developers.google.com/maps/documentation/urls/ios-urlscheme
		final googleMapsQuery = _makeCombinedQuery(address, location, aPrefix: 'q', lPrefix: 'center');
		// https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/MapLinks/MapLinks.html#//apple_ref/doc/uid/TP40007899-CH5-SW1
		final appleQuery = _makeCombinedQuery(address, location, aPrefix: 'q', lPrefix: 'll');
		// https://stackoverflow.com/a/24778057/4656400
		final googleQuery = _makeCombinedQuery(address, location, aPrefix: 'q', lPrefix: 'near'); /*_makeLocationQuery(location, prefix: 'q') ?? *//*_makeAddressQuery(address) ??*/ /*"";*/
		return [
			'comgooglemaps://?$googleMapsQuery&dirflg=w,',
			'https://maps.apple.com/?$appleQuery&dirflg=w',
			'http://maps.google.com/maps?$googleQuery&dirflg=w,',
		];
	}
	
	static List<String> buildMapUrls({String address, LatLng location}) {
		// https://developers.google.com/maps/documentation/urls/ios-urlscheme
		final googleMapsQuery = _makeCombinedQuery(address, location, aPrefix: 'q', lPrefix: 'center');
		// https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/´´MapLinks/MapLinks.html#//apple_ref/doc/uid/TP40007899-CH5-SW1
		final appleQuery = _makeCombinedQuery(address, location, aPrefix: 'q', lPrefix: 'll');
		// https://stackoverflow.com/a/24778057/4656400
		final googleQuery = _makeCombinedQuery(address, location, aPrefix: 'q', lPrefix: 'near'); /*_makeLocationQuery(location, prefix: 'q') ?? *//*_makeAddressQuery(address) ??*/ /*"";*/
		return [
			'comgooglemaps://?$googleMapsQuery&dirflg=w,',
			'https://maps.apple.com/?$appleQuery&dirflg=w',
			'maps://?$appleQuery&dirflg=w',
			'http://maps.google.com/maps?$googleQuery&dirflg=w,',
		];
	}
	
	static String _makeCombinedQuery(String address, LatLng location, {String aPrefix = 'q', String lPrefix = 'center'}) {
		final addressQuery = _makeAddressQuery(address, prefix: aPrefix);
		final locationQuery = _makeLocationQuery(location, prefix: address != null ? lPrefix : aPrefix);
		final queries = [];
		if (addressQuery != null) queries.add(addressQuery);
		if (locationQuery != null) queries.add(locationQuery);
		return queries.join('&');
	}
	
	static Future<bool> canOpen(List<String> urls) async {
		bool canOpen = false;
		await Future.forEach(urls, (url) async {
			if (await canLaunch(url)) canOpen = true;
		});
		return canOpen;
	}
	
	static openMap(List<String> urls) async {
		final iterator = urls.iterator;
		Future.doWhile (() async {
			if (!iterator.moveNext()) return false;
			final url = iterator.current;
			if (await canLaunch(url)) {
				print('opening: $url');
				final isSuccessful = await launch(url);
				return !isSuccessful;
			} else {
				print('unable to open: $url');
				return true;
			}
		});
	}
	
	static String _makeLocationQuery(LatLng location, {String prefix = "ll"}) {
		final lat = location?.latitude;
		final lon = location?.longitude;
		return lat != null && lon != null ? '$prefix=$lat,$lon' : null;
	}
	
	static String _makeAddressQuery(String address, {String prefix = "daddr"}) {
		/*"address=Санкт-Петербург,улица+Садовая,13"*/ /*"address=Sankt-Peterburg,ulitsa+Sadovaya,13"*/ /*"address=1,Infinite+Loop,Cupertino,California"*/
		if (address == null || address.isEmpty) return null;
		final basicAddress = address
				.replaceAll('/', ',')
				.replaceAll(', ', ',')
				.replaceAll(' ', '+')
				.replaceAll('\n', '+');
		final addressQuery = "$prefix=$basicAddress";
		// apple cannot handle cyrillic addresses;
		final transliterated = Translit().toTranslit(source: addressQuery);
		final dTransliterated = DeutschTranslit().toTranslit(source: transliterated);
		return dTransliterated;
	}
}

class DeutschTranslit {
	static final DeutschTranslit _translit = DeutschTranslit._internal();
	
	factory DeutschTranslit() {
		return _translit;
	}
	
	DeutschTranslit._internal();
	
	final Map _transliteratedSymbol = {
	};
	
	final Map _complicatedSymbols = {
		'ß': 'ss',
		'Ä': 'Ae',
		'Ü': 'Ue',
		'Ö': 'Oe',
		'ä': 'ae',
		'ü': 'ue',
		'ö': 'oe',
	};
	
	String unTranslit({String source}) {
		if (source == null || source.isEmpty) return source;
		
		var regExp = RegExp(
			r'([a-z]+)',
			caseSensitive: false,
			multiLine: true,
		);
		
		if (!regExp.hasMatch(source)) return source;
		
		var sourceSymbols = [];
		var unTranslit = [];
		var deTransliteratedSymbol = {};
		
		_complicatedSymbols.forEach((key, value) {
			source = source.replaceAll(value, key);
		});
		
		sourceSymbols = source.split('');
		
		_transliteratedSymbol.forEach((key, value) {
			deTransliteratedSymbol[value] = key;
		});
		
		for (final element in sourceSymbols) {
			unTranslit.add(deTransliteratedSymbol.containsKey(element)
					? deTransliteratedSymbol[element]
					: element);
		}
		
		return unTranslit.join();
	}
	
	String toTranslit({String source}) {
		if (source == null || source.isEmpty) return source;
		
		var regExp = RegExp(
			r'([ßüöä]+)',
			caseSensitive: false,
			multiLine: true,
		);
		
		if (!regExp.hasMatch(source)) return source;
		
		var translit = [];
		var sourceSymbols = [];
		
		sourceSymbols = source.split('');
		
		_transliteratedSymbol.addAll(_complicatedSymbols);
		
		for (final element in sourceSymbols) {
			translit.add(_transliteratedSymbol.containsKey(element)
					? _transliteratedSymbol[element]
					: element);
		}
		
		return translit.join();
	}
}

class Translit {
	final Map _transliteratedSymbol = {
		'А': 'A',
		'Б': 'B',
		'В': 'V',
		'Г': 'G',
		'Д': 'D',
		'Е': 'E',
		'З': 'Z',
		'И': 'I',
		'Й': 'J',
		'К': 'K',
		'Л': 'L',
		'М': 'M',
		'Н': 'N',
		'О': 'O',
		'П': 'P',
		'Р': 'R',
		'С': 'S',
		'Т': 'T',
		'У': 'U',
		'Ф': 'F',
		'Х': 'H',
		'Ц': 'C',
		'Ы': 'Y',
		'а': 'a',
		'б': 'b',
		'в': 'v',
		'г': 'g',
		'д': 'd',
		'е': 'e',
		'з': 'z',
		'и': 'i',
		'й': 'j',
		'к': 'k',
		'л': 'l',
		'м': 'm',
		'н': 'n',
		'о': 'o',
		'п': 'p',
		'р': 'r',
		'с': 's',
		'т': 't',
		'у': 'u',
		'ф': 'f',
		'х': 'h',
		'ц': 'c',
		'ы': 'y',
		"'": '',
		'"': '',
	};
	
	final Map _complicatedSymbols = {
		'Ё': 'Yo',
		'Ж': 'Zh',
		'Щ': 'Shhch',
		'Ш': 'Shh',
		'Ч': 'Ch',
		'Э': 'Eh\'',
		'Ю': 'Yu',
		'Я': 'Ya',
		'ё': 'yo',
		'ж': 'zh',
		'щ': 'shhch',
		'ш': 'shh',
		'ч': 'ch',
		'э': 'eh\'',
		'ъ': '"',
		'ь': "'",
		'ю': 'yu',
		'я': 'ya',
	};
	
	/// Method for converting from translit for the [source] value
	String unTranslit({String source}) {
		if (source == null || source.isEmpty) return source;
		
		var regExp = RegExp(
			r'([a-z]+)',
			caseSensitive: false,
			multiLine: true,
		);
		
		if (!regExp.hasMatch(source)) return source;
		
		var sourceSymbols = [];
		var unTranslit = [];
		var deTransliteratedSymbol = {};
		
		_complicatedSymbols.forEach((key, value) {
			source = source.replaceAll(value, key);
		});
		
		sourceSymbols = source.split('');
		
		_transliteratedSymbol.forEach((key, value) {
			deTransliteratedSymbol[value] = key;
		});
		
		for (final element in sourceSymbols) {
			unTranslit.add(deTransliteratedSymbol.containsKey(element)
					? deTransliteratedSymbol[element]
					: element);
		}
		
		return unTranslit.join();
	}
	
	/// Method for converting to translit for the [source] value
	String toTranslit({String source}) {
		if (source == null || source.isEmpty) return source;
		
		var regExp = RegExp(
			r'([а-я]+)',
			caseSensitive: false,
			multiLine: true,
		);
		
		if (!regExp.hasMatch(source)) return source;
		
		var translit = [];
		var sourceSymbols = [];
		
		sourceSymbols = source.split('');
		
		_transliteratedSymbol.addAll(_complicatedSymbols);
		
		for (final element in sourceSymbols) {
			translit.add(_transliteratedSymbol.containsKey(element)
					? _transliteratedSymbol[element]
					: element);
		}
		
		return translit.join();
	}
}