import 'package:flutter/widgets.dart';

class MLocalizations {

  String get promptEmail => "Email";

  String get hintEmail => "Enter your email";

  String get errorInvalidEmail => "This email address is invalid";

  String get errorInvalidPassword => "This password is too short";

  String get promptPassword => "Password";

  String get hintPassword => "Enter your password";

  String get errorIncorrectPassword => "The password is incorrect";
	
  static MLocalizations of(BuildContext buildContext) => MLocalizations();
	
}