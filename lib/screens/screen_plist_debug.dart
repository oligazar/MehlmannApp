import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahlmann_app/common/extensions.dart';

class ScreenPlistDebug extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: _getPlistValues(),
        builder: (context, snapshot) {
          final text = snapshot.data ?? "";

          return Scaffold(
            appBar: AppBar(
              title: Text(context.loc.plistDebug),
            ),
            body: Container(
              padding: const EdgeInsets.all(16),
              child: Text(text),
            ),
          );
        });
  }

  Future<String> _getPlistValues() async {
    final prefs = await SharedPreferences.getInstance();

    final result = prefs.getKeys().map((key) => "$key: ${prefs.get(key)}").join("\n");

    return result;
  }
}
