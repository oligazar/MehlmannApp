import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mahlmann_app/app_mahlmann.dart';
import 'package:mahlmann_app/blocs/bloc_login.dart';
import 'package:mahlmann_app/common/api/api_base.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/functions.dart';
import 'package:mahlmann_app/common/lang/m_localizations.dart';
import 'package:mahlmann_app/common/prefs.dart';
import 'package:mahlmann_app/models/response_wrapper.dart';
import 'package:mahlmann_app/models/login_response.dart';
import 'package:mahlmann_app/widgets/preference_radio_list.dart';
import 'package:provider/provider.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:mahlmann_app/common/field_validator.dart';

// https://www.miradore.com/blog/mdm-mobile-device-management/
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
  final TextEditingController _typeAheadController = TextEditingController();

  BlocLogin get _bloc => context.provide<BlocLogin>();

  MLocalizations get _loc => context.loc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
                        child: _formUI(),
                      ),
                      StreamBuilder<bool>(
                          stream: _bloc.showBackendSettings,
                          builder: (context, snapshot) {
                            final shouldShow = snapshot.data == true;
                            return shouldShow ? _backendSetting() : Container();
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
    );
  }

  Widget _formUI() {
    final _bloc = context.provide<BlocLogin>();
    final _loc = context.loc;
    return FutureBuilder(
      future: Prefs.autoFill,
      builder: (context, snapshot) {
        // final map = snapshot.data ?? {};
        // final email = map["email"];
        // final pass = map["password"];
        return AutofillGroup(
          child: Column(
            children: <Widget>[
              TextFormField(
                autofillHints: [ AutofillHints.email ],
                decoration: InputDecoration(
                  labelText: _loc.promptEmail,
                  hintText: _loc.hintEmail,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _loc.errorInvalidEmail.ifInvalidEmail,
                onChanged: (String val) {
                  _bloc.email = val;
                },
                onSaved: (String val) {
                  _bloc.email = val;
                },
              ),
              // _buildTypeAheadField(),
              TextFormField(
                autofillHints: [ AutofillHints.password ],
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
                  onPressed: _tryLogin,
                  child: Text('Login'.toUpperCase()),
                ),
              ),
              const SizedBox(height: 22),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTypeAheadField() {
    return TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
        controller: _typeAheadController,
        autofocus: true,
        style: DefaultTextStyle.of(context).style,
        decoration: InputDecoration(
          labelText: _loc.promptEmail,
          hintText: _loc.hintEmail,
        ),
      ),
      suggestionsCallback: (pattern) async {
        final string = "frye-admin@mahlmann.com";
        if (pattern.length > 2 && string.contains(pattern)) {
          return ["frye-admin@mahlmann.com"];
        }
        return [];
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
        _typeAheadController.text = suggestion;
      },
    );
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

  void _tryLogin() async {
    if (_validateAndSave()) {
      final resp = await _bloc.auth(context);
      AppMahlmann.of(context).setIsAuthorized(resp?.token != null);
      // AppMahlmann.of(context).setIsAuthorized(true);
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
