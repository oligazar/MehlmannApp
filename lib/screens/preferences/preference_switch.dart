import 'package:flutter/material.dart';
import 'package:mahlmann_app/common/m_colors.dart';
import 'package:mahlmann_app/screens/preferences/preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceSwitch extends StatefulWidget {
  final String title;
  final String Function(bool) subTitleBuilder;
  final String prefKey;
  final Function(bool) onSwitched;
  final IconData icon;
  final bool inverted;

  const PreferenceSwitch({
    Key key,
    this.title = "",
    this.subTitleBuilder,
    @required this.prefKey,
    this.onSwitched,
    this.icon,
    this.inverted = false,
  })  : assert(prefKey != null),
        super(key: key);

  @override
  _PreferenceSwitchState createState() => _PreferenceSwitchState();
}

class _PreferenceSwitchState extends State<PreferenceSwitch> {
  bool _isChecked;

  @override
  void initState() {
    _prepareState();
    super.initState();
    _isChecked = widget.inverted;
  }

  @override
  Widget build(BuildContext context) {
    return Preference(
      title: widget.title,
      onTap: () => _onChecked(!_isChecked),
      subTitle: widget.subTitleBuilder != null ? widget.subTitleBuilder(_isChecked) : "",
      icon: widget.icon,
      child: Switch(
        activeColor: MColors.primaryDark,
        value: _isChecked,
        onChanged: _onChecked,
      ),
    );
  }

  void _onChecked(bool isChecked) async {
    setState(() {
      _isChecked = isChecked;
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(widget.prefKey, isChecked);
    if (widget.onSwitched != null) widget.onSwitched(isChecked);
  }

  void _prepareState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(widget.prefKey) && widget.inverted) {
      await prefs.setBool(widget.prefKey, true);
    }
    final defaultValue = prefs.getBool(widget.prefKey) ?? widget.inverted;
    setState(() {
      _isChecked = defaultValue;
    });
  }
}
