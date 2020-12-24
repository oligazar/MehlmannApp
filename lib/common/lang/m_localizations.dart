import 'package:flutter/widgets.dart';

class MLocalizations {

  String get promptEmail => "E-Mail";

  String get hintEmail => "Geben Sie Ihre E-Mail ein";

  String get errorInvalidEmail => "Die E-Mail-Adresse ist ungültig";

  String get errorInvalidPassword => "Das Passwort ist zu kurz";

  String get promptPassword => "Passwort";

  String get hintPassword => "Geben Sie Ihr Passwort ein";

  String get errorIncorrectPassword => "E-Mail oder Passwort ungültig";

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

  String get name => "Name";
  
  String get type => "Type";

  String get status => "Status";

  String get cabbage => "Kohlfähigkeit";

  String get titleArea => "Fläche";

  String get comments => "Kommentare";
  
  String get comment => "Kommentar";

  String get route => "Route";

  String get close => "Schließen";

  String get sendSentence => "Satz versenden";

  String get abort => "Abbrechen";

  String get msgSuccess => "Der Satz wurde erfolgreich erstellt.";

  String get noSets => "No sets.";

  String get deselect => "Deaktivieren";

  String get dialogTitleConfirmLogout => "Wollen Sie sich wirklich abmelden?";

  String get btnOk => "Ja";
  
  String get btnCancel => "Nein";

  String get titleBackend => "Server";

  String get summBackend => "Server auswählen.";

  String get staging => "Staging";

  String get production => "Herstellung";
	
  static MLocalizations of(BuildContext buildContext) => MLocalizations();
	
}
