import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mahlmann_app/screens/screen_login.dart';
import 'package:mahlmann_app/screens/screen_map.dart';
import 'package:mahlmann_app/screens/screen_preloader.dart';

class _AppMahlmann extends InheritedWidget {
  final _AppMahlmannState state;

  _AppMahlmann({Key key, this.state, Widget child})
      : super(key: key, child: child);

  @override
  bool updateShouldNotify(_AppMahlmann old) => true;
}

class AppMahlmann extends StatefulWidget {
  static _AppMahlmannState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppMahlmann>().state;
  }

  @override
  _AppMahlmannState createState() => _AppMahlmannState();
}

class _AppMahlmannState extends State<AppMahlmann> {
  bool _isAuthorized;
  bool _showPreloader = true;

  void setIsAuthorized(bool isAuthorized) {
    setState(() {
      if (!isAuthorized) _showPreloader = true;
      _isAuthorized = isAuthorized;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          return MaterialApp(
            title: 'Flutter Demo',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: _buildHomeScreen(
                isLoading: snapshot.connectionState != ConnectionState.done,
                hasError: snapshot.hasError),
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              const Locale('en', ''), // English, no country code
              const Locale('de', ''), // German, no country code
            ],
          );
        });
  }

  Widget _buildHomeScreen({bool isLoading, bool hasError}) {
    return _AppMahlmann(
      state: this,
      child: _isAuthorized == null
          ? ScreenPreloader()
          : _isAuthorized
              ? _showPreloader
                  ? ScreenPreloader(onFetched: () {
                      setState(() => _showPreloader = false);
                    })
                  : ScreenMap()
              : ScreenLogin(),
    );
  }
}
