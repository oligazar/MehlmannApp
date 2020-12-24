import 'package:flutter/material.dart';
import 'package:mahlmann_app/app_mahlmann.dart';
import 'package:mahlmann_app/blocs/bloc_login.dart';
import 'package:mahlmann_app/common/api/api_base.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/functions.dart';
import 'package:mahlmann_app/common/lang/m_localizations.dart';
import 'package:mahlmann_app/models/response_wrapper.dart';
import 'package:mahlmann_app/models/login_response.dart';
import 'package:mahlmann_app/widgets/preference_radio_list.dart';
import 'package:provider/provider.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:mahlmann_app/common/field_validator.dart';

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
                        }
                      ),
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
    return Column(
      children: <Widget>[
        TextFormField(
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
        TextFormField(
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
          child: RaisedButton(
            key: Key(LOGIN_BTN),
            color: Colors.grey,
            onPressed: _tryLogin,
            child: Text('Login'.toUpperCase()),
          ),
        ),
        const SizedBox(height: 22),
      ],
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
    switch (result?.state) {
      case WrapperState.ERROR:
        return Container(
          child: Text(context.loc.errorIncorrectPassword),
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
      final resp = await _bloc.auth();
      AppMahlmann.of(context).setIsAuthorized(resp?.token != null);
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
          PrefRadioItem(
              value: PROD, titleMaker: () => _loc.production),
        ],
        onSelected: (item) {
          print('on Changed: ${item.value}');
          baseAuthority = item.value == PROD
              ? AUTHORITY_PRODUCTION
              : AUTHORITY_STAGING;
        },
      ),
    );
  }
}
