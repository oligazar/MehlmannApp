import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:mahlmann_app/common/functions.dart';
import 'package:mahlmann_app/common/m_colors.dart';
import 'package:mahlmann_app/common/prefs.dart';
import 'package:mahlmann_app/common/sqlite/db_client.dart';
import 'package:mahlmann_app/screens/preferences/preference.dart';
import 'package:mahlmann_app/screens/preferences/preference_group.dart';
import 'package:mahlmann_app/screens/preferences/preference_switch.dart';
import 'package:mahlmann_app/widgets/dialogs/two_actions_dialog.dart';

import '../app_mahlmann.dart';

class ScreenPreferences extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.titlePreferences),
      ),
      body: Container(
          // color: MColors.bgLightGrey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                PreferenceGroup(
                  title: "",
                  children: <Widget>[
                    PreferenceSwitch(
                      prefKey: PREF_POSITION_TRACKING,
                      title: "Activate position tracking",
                      // inverted: true,
                    ),
                    PreferenceSwitch(
                      prefKey: PREF_ROUTE_TRACKING,
                      title: "Activate route tracking",
                    ),
                    PreferenceSwitch(
                      prefKey: PREF_ROUTE_TRACKING,
                      title: loc.mapMode,
                      subTitle: "Map/Satellite",
                    ),
                    if (Platform.isIOS) Preference(
                      title: "Plist debug",
                      onTap: () async {},
                    ),
                    Preference(
                      title: loc.logOut,
                      onTap: () async {
                        // _logOut(context);
                      },
                    ),
                    FutureBuilder<String>(
                        future: buildVersion,
                        builder: (context, snap) {
                          return Preference(
                            title: loc.buildVersion,
                            subTitle: 'v ${snap.data}',
                          );
                        }),
                  ],
                )
              ],
            ),
          )),
    );
  }
  
  Future _logOut(BuildContext context, {bool shouldShowDialog = true}) async {
    bool shouldLogout;
    if (shouldShowDialog) {
      shouldLogout = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => TwoActionsDialog(
          title: context.loc?.dialogTitleConfirmLogout,
          btnCancelTitle: context.loc.btnCancel,
          cancelAction: () => Navigator.of(context).pop(false),
          btnOkTitle: context.loc.btnOk,
          okAction: () => Navigator.of(context).pop(true),
        ),
      );
    }
    if (shouldLogout) {
      await DbClient().clearAllTables();
      Prefs.logout();
      AppMahlmann.of(context).setIsAuthorized(false);
    }
  }
}
