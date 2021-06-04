import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mahlmann_app/blocs/bloc_login.dart';
import 'package:mahlmann_app/common/api/api_base.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/functions.dart';
import 'package:mahlmann_app/common/lang/m_localizations.dart';
import 'package:mahlmann_app/common/prefs.dart';
import 'package:mahlmann_app/models/response_wrapper.dart';
import 'package:mahlmann_app/models/login_response.dart';
import 'package:mahlmann_app/screens/screen_plist_debug.dart';
import 'package:mahlmann_app/widgets/preference_radio_list.dart';
import 'package:provider/provider.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:mahlmann_app/common/field_validator.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// https://www.miradore.com/blog/mdm-mobile-device-management/

// https://developer.apple.com/forums/thread/118543
// https://www.raywenderlich.com/books/catalyst-by-tutorials/v1.0/chapters/7-preferences-settings-bundle
// https://abhimuralidharan.medium.com/adding-settings-to-your-ios-app-cecef8c5497
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/UserDefaults/Preferences/Preferences.html#//apple_ref/doc/uid/10000059i-CH6-SW5
class ScreenLogin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provider<BlocLogin>(
      create: (context) => BlocLogin(),
      dispose: (context, value) => value.dispose(),
      child: ViewLogin(),
      lazy: false,
    );
  }
}

class ViewLogin extends StatefulWidget {
  @override
  _ViewLoginState createState() => _ViewLoginState();
}

class _ViewLoginState extends State<ViewLogin> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  bool _obscureText = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  BlocLogin get _bloc => context.provide<BlocLogin>();

  MLocalizations get _loc => context.loc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: StreamBuilder<ResponseWrapper<LoginResponse>>(
                stream: _bloc.userLogin,
                builder: (context, snap) {
                  final result = snap.data;
                  return Container(
                    key: Key('streamBuilder'),
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          Form(
                            key: _formKey,
                            autovalidateMode: _autoValidate == true
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            child: _formUI(context),
                          ),
                          StreamBuilder<bool>(
                              stream: _bloc.showBackendSettings,
                              builder: (context, snapshot) {
                                final shouldShow = snapshot.data == true;
                                return shouldShow
                                    ? _backendSetting()
                                    : Container();
                              }),
                          const SizedBox(height: 20),
                          _progressIndication(result),
                          const SizedBox(height: 20),
//                  Spacer(),
                          FutureBuilder<String>(
                              future: buildVersion,
                              builder: (context, snap) {
                                return Text("v ${snap.data}.");
                              }),
                        ],
                      ),
                    ),
                  );
                }),
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: TextButton(
              child: Text(context.loc.plistDebug),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ScreenPlistDebug()),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Future<Map<String, String>> _readLoginValues() async {
    // final SharedPreferences pref = await SharedPreferences.getInstance();
    // await pref.setString("username", "frye-admin@mahlmann.com");
    // await pref.setString("password", "qwerty123");
    return Prefs.autoFill;
  }

  Widget _formUI(BuildContext context) {
    final _bloc = context.provide<BlocLogin>();
    final _loc = context.loc;
    return Column(
      children: <Widget>[
        _buildTypeAheadEmailField(context),
        TextFormField(
          controller: _passwordController,
          autofillHints: [AutofillHints.password],
          decoration: _passwordDecoration,
          keyboardType: TextInputType.text,
          validator: _loc.errorInvalidPassword.ifLessThan,
          obscureText: _obscureText,
          onSaved: (String val) {
            _bloc.pass = val;
          },
        ),
        const SizedBox(
          height: 22.0,
        ),
        Container(
          width: double.infinity,
          child: ElevatedButton(
            key: Key(LOGIN_BTN),
            onPressed: () => _tryLogin(context),
            child: Text('Login'.toUpperCase()),
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  InputDecoration textFieldDecoration(BuildContext context) => InputDecoration(
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
          color: Theme.of(context).accentColor,
          width: 2,
        )),
        labelStyle: TextStyle(
          // fontFamily: 'Roboto Medium',
          // fontSize: 12.0,
          color: Theme.of(context).accentColor,
          letterSpacing: 0.4,
        ),
      );

  Widget _buildTypeAheadEmailField(BuildContext context) {
    return FutureBuilder(
        future: _readLoginValues(),
        builder: (context, snapshot) {
          final map = snapshot.data ?? {};
          final email = map[KEY_USERNAME];
          final password = map[KEY_PASSWORD];
          return TypeAheadFormField(
            validator: _loc.errorInvalidEmail.ifInvalidEmail,
            onSaved: (String val) {
              _bloc.email = val;
            },
            textFieldConfiguration: TextFieldConfiguration(
                controller: _emailController,
                autofocus: true,
                style: DefaultTextStyle.of(context).style,
                decoration: textFieldDecoration(context).copyWith(
                  labelText: _loc.promptEmail,
                  hintText: _loc.hintEmail,
                ),
                onChanged: (String val) {
                  _bloc.email = val;
                }),
            suggestionsCallback: (pattern) async {
              final map = await _readLoginValues() ?? {};
              final email = map[KEY_USERNAME];
              return email != null ? [email] : [];
            },
            itemBuilder: (context, suggestion) {
              return ListTile(
                title: Text(suggestion),
              );
            },
            noItemsFoundBuilder: (context) => null,
            transitionBuilder: (context, box, controller) => box,
            onSuggestionSelected: (suggestion) {
              print("$suggestion selected");
              _emailController.text = email;
              _passwordController.text = password;
            },
          );
        });
  }

  InputDecoration get _passwordDecoration {
    return InputDecoration(
      labelText: _loc.promptPassword,
      hintText: _loc.hintPassword,
      suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            semanticLabel: _obscureText ? 'hide password' : 'show password',
          ),
          onPressed: () {
            setState(() => _obscureText ^= true);
          }),
      labelStyle: TextStyle(
        fontFamily: 'Roboto Medium',
        fontSize: 12.0,
        color: Color(0x99000000),
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _progressIndication(ResponseWrapper result) {
    final errorText = result?.error;
    switch (result?.state) {
      case WrapperState.ERROR:
        return Container(
          child: Text(
            errorText ?? context.loc.errorIncorrectPassword,
            style: TextStyle(color: Colors.red),
          ),
        );
      case WrapperState.LOADING:
        return _buildProgressIndicator();
      default:
        return Container();
    }
  }

  Widget _buildProgressIndicator() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      //  If all data are correct then save data to out variables
      form.save();
      return true;
    } else {
      return false;
    }
  }

  void _tryLogin(BuildContext context) async {
    if (_validateAndSave()) {
      final resp = await _bloc.auth(context);
      context.setIsAuthorized(resp?.token != null);
    } else {
      setState(() {
        _autoValidate = true;
      });
    }
  }

  Widget _backendSetting() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(width: 1, color: Colors.grey),
          bottom: BorderSide(width: 1, color: Colors.grey),
        ),
      ),
      child: PreferenceRadioList<String>(
        title: _loc.titleBackend,
        subTitle: _loc.summBackend,
        icon: Icons.http,
        prefKey: PREF_BACKEND,
        dialogTitle: _loc.summBackend,
        items: [
          PrefRadioItem(value: STAG, titleMaker: () => _loc.staging),
          PrefRadioItem(value: PROD, titleMaker: () => _loc.production),
        ],
        onSelected: (item) {
          print('on Changed: ${item.value}');
          baseAuthority =
              item.value == PROD ? AUTHORITY_PRODUCTION : AUTHORITY_STAGING;
        },
      ),
    );
  }
}
