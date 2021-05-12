import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mahlmann_app/common/constants.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:mahlmann_app/common/functions.dart';
import 'package:mahlmann_app/common/m_colors.dart';
import 'package:mahlmann_app/screens/preferences/preference.dart';
import 'package:mahlmann_app/screens/preferences/preference_group.dart';
import 'package:mahlmann_app/screens/preferences/preference_switch.dart';

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
                      inverted: true,
                    ),
                    PreferenceSwitch(
                      prefKey: PREF_ROUTE_TRACKING,
                      title: "Activate route tracking",
                    ),
                    PreferenceSwitch(
                      prefKey: PREF_ROUTE_TRACKING,
                      title: "Map mode",
                      subTitle: "Map/Satellite",
                    ),
                    if (Platform.isIOS) Preference(
                      title: "Plist debug",
                      onTap: () async {},
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
}
