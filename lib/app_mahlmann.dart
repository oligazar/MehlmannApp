// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mahlmann_app/common/api/api_base.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/prefs.dart';
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
  @override
  void initState() {
    super.initState();
    _initAsync();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _buildHomeScreen(),
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
  }

  Widget _buildHomeScreen() {
    return _AppMahlmann(
      state: this,
      child: FutureBuilder<bool>(
        future: Prefs.isAuthorized,
        builder: (context, snap) {
          final isAuthorized = snap.data == true;
          return isAuthorized ? ScreenData() : ScreenLogin();
        },
      ),
    );
  }

  Future<void> _initAsync() async {
    final isProd = await Prefs.isProdPref;
    baseAuthority = isProd ? AUTHORITY_PRODUCTION : AUTHORITY_STAGING;
  }
}

class ScreenData extends StatefulWidget {
  @override
  _ScreenDataState createState() => _ScreenDataState();
}

class _ScreenDataState extends State<ScreenData> {
  bool _showPreloader = true;

  @override
  Widget build(BuildContext context) {
    return _showPreloader
        ? ScreenPreloader(() {
            setState(() => _showPreloader = false);
          })
        : ScreenMap();
  }
}
