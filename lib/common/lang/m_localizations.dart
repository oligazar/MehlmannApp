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

  String get sentenceInbox => "Satz Inbox";

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

  String get name => "Name";

  String get status => "Status";

  String get cabbage => "Kohlfähigkeit";

  String get titleArea => "Fläche";

  String get comments => "Comments";
  
  String get comment => "Comment";

  String get route => "Route";

  String get close => "Schließen";

  String get sendSentence => "Satz versenden";

  String get abort => "Abbrechen";

  String get msgSuccess => "Der Satz wurde erfolgreich erstellt.";

  String get noSets => "No sets.";
	
  static MLocalizations of(BuildContext buildContext) => MLocalizations();
	
}