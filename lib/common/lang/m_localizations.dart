import 'package:flutter/widgets.dart';

class MLocalizations {

  String get promptEmail => "Email";

  String get hintEmail => "Enter your email";

  String get errorInvalidEmail => "This email address is invalid";

  String get errorInvalidPassword => "This password is too short";

  String get promptPassword => "Password";

  String get hintPassword => "Enter your password";

  String get errorIncorrectPassword => "The password is incorrect";

  String get startMeasurement => "Messung starten";
  
  String get stopMeasurement => "Messung beenden";
  
  String get searchField => "Search for fields";

  String get setInbox => "Satz Inbox";

  String get logOut => "Ausloggen";

  String get currentPosition => "Aktuelle Position";

  String get fountain => "Brunnen an/aus";

  String get promptSearch => "Suche";

  String get errorEmptyField => "Feld darf nicht leer sein";

  String get back => "Zurück";
	
  static MLocalizations of(BuildContext buildContext) => MLocalizations();
	
}