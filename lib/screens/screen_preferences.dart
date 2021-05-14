import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:mahlmann_app/common/functions.dart';
import 'package:mahlmann_app/common/prefs.dart';
import 'package:mahlmann_app/common/sqlite/db_client.dart';
import 'package:mahlmann_app/screens/preferences/preference.dart';
import 'package:mahlmann_app/screens/preferences/preference_group.dart';
import 'package:mahlmann_app/screens/preferences/preference_switch.dart';
import 'package:mahlmann_app/screens/screen_login.dart';
import 'package:mahlmann_app/screens/screen_plist_debug.dart';
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
        padding: const EdgeInsets.only(top: 24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                PreferenceSwitch(
                  prefKey: PREF_POSITION_TRACKING,
                  title: loc.positionTracking,
                  // inverted: true,
                ),
                PreferenceSwitch(
                  prefKey: PREF_ROUTE_TRACKING,
                  title: loc.routeTracking,
                ),
                PreferenceSwitch(
                  prefKey: PREF_SATELLITE_MODE,
                  title: loc.mapMode,
                  subTitleBuilder: (isSatellite) {
                    return isSatellite ? loc.satellite : loc.map;
                  },
                ),
                if (Platform.isIOS) Preference(
                  title: loc.plistDebug,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ScreenPlistDebug()),
                    );
                  },
                ),
                Preference(
                  title: loc.logOut,
                  onTap: () async {
                    _logOut(context);
                  },
                ),
                FutureBuilder<String>(
                    future: buildVersion,
                    builder: (context, snap) {
                      return Preference(
                        title: loc.buildVersion,
                        subTitle: 'v ${snap.data}',
                      );
                    })
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
      context.setIsAuthorized(false);
    }
  }
}
