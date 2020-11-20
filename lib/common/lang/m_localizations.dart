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
  
  String get selectSentence => "Satz auswählen";
  
  String get createSentence => "Satz erzeugen";
  
  String get searchField => "Felder suchen";

  String get setInbox => "Satz Inbox";

  String get logOut => "Ausloggen";

  String get currentPosition => "Aktuelle Position";

  String get fountainOn => "Brunnen an";
  
  String get fountainOff => "Brunnen aus";

  String get promptSearch => "Suche";

  String get errorEmptyField => "Feld darf nicht leer sein";

  String get back => "Zurück";

  String get btnOk => "Ok";

  String get yes => "Ja";
  
  String get no => "Nein";

  String get titleName => "Name";

  String get titleStatus => "Status";

  String get titleIsCabbage => "Kohlfähigkeit";

  String get titleArea => "Fläche";

  String get titleComments => "Comments";
  
  String get promptComment => "Comment";

  String get titleRoute => "Route";

  String get titleClose => "Schließen";
	
  static MLocalizations of(BuildContext buildContext) => MLocalizations();
	
}