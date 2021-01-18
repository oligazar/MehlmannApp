import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:mahlmann_app/widgets/dialogs/m_dialog.dart';
import 'package:mahlmann_app/common/field_validator.dart';

class SearchBoxLatLngsResult {
  double lat = 0;
  double lng = 0;
  bool shouldAddMarker = false;

  SearchBoxLatLngsResult(this.lat, this.lng, this.shouldAddMarker);
}

class SearchBoxLatLngs extends StatefulWidget {
  final ValueChanged<SearchBoxLatLngsResult> onSubmitted;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final String hintText;
  final String initialText;
  final Widget child;

  const SearchBoxLatLngs({
    Key key,
    this.icon,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.initialText,
    this.child,
  }) : super(key: key);

  @override
  _SearchBoxLatLngsState createState() => _SearchBoxLatLngsState();
}

class _SearchBoxLatLngsState extends State<SearchBoxLatLngs> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  bool _shouldAddMarker = false;
  double _latDegrees = 0;
  double _latMinutes = 0;
  double _latSeconds = 0;

  double _lngDegrees = 0;
  double _lngMinutes = 0;
  double _lngSeconds = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white.withAlpha(220),
          borderRadius: BorderRadius.all(Radius.circular(16))),
      child: Form(
        key: _formKey,
        autovalidateMode: _autoValidate == true
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _placeholder,
            _buildRow(
              title: "Lat:",
              onSavedDegrees: (degrees) => _latDegrees = degrees ?? 0,
              onSavedMinutes: (minutes) => _latMinutes = minutes ?? 0,
              onSavedSeconds: (seconds) => _latSeconds = seconds ?? 0,
            ),
            _placeholder,
            _buildRow(
              title: "Lng:",
              onSavedDegrees: (degrees) => _lngDegrees = degrees ?? 0,
              onSavedMinutes: (minutes) => _lngMinutes = minutes ?? 0,
              onSavedSeconds: (seconds) => _lngSeconds = seconds ?? 0,
            ),
            _placeholder,
            Align(
              alignment: Alignment.center,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                      child: Text(
                    context.loc.placePin,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  )),
                  Flexible(
                      child: Switch(
                    value: _shouldAddMarker,
                    onChanged: (value) {
                      setState(() {
                        _shouldAddMarker = value;
                      });
                    },
                  )),
                ],
              ),
            ),
            DialogButton(
                title: context.loc.btnOk,
                action: () {
                  if (_formKey.currentState.validate()) {
                    _formKey.currentState.save();
                    final latFractional =
                        _toFractional(_latMinutes, _latSeconds);
                    final lat = _latDegrees + latFractional;

                    final lngFractional =
                        _toFractional(_lngMinutes, _lngSeconds);
                    final lng = _lngDegrees + lngFractional;
                    final result =
                        SearchBoxLatLngsResult(lat, lng, _shouldAddMarker);
                    print("LatLng: $lat, $lng");
                    if (widget.onSubmitted != null) {
                      widget.onSubmitted(result);
                    }
                  } else {
                    setState(() => _autoValidate = true);
                  }
                }),
            if (widget.child != null) widget.child,
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    String title,
    FormFieldSetter<double> onSavedDegrees,
    FormFieldSetter<double> onSavedMinutes,
    FormFieldSetter<double> onSavedSeconds,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Container(
            width: 36,
            padding: EdgeInsets.only(top: 5),
            child: Text(title),
          ),
        Expanded(
          child: _buildTextField(
            hint: context.loc.degrees,
            validator: (s) =>
                context.loc.errorEmptyField.ifEmpty(s) ??
                context.loc.errorEmptyField.ifEmpty(s),
            onSaved: onSavedDegrees,
          ),
        ),
        _placeholder,
        Expanded(
          child: _buildTextField(
            hint: context.loc.minutes,
            onSaved: onSavedMinutes,
          ),
        ),
        _placeholder,
        Expanded(
          child: _buildTextField(
            hint: context.loc.seconds,
            onSaved: onSavedSeconds,
          ),
        ),
      ],
    );
  }

  Widget get _placeholder => const SizedBox(
        width: 10,
        height: 10,
      );

  Widget _buildTextField(
      {String hint,
      FormFieldValidator<String> validator,
      FormFieldSetter<double> onSaved}) {
    return TextFormField(
      onChanged: widget.onChanged,
      textCapitalization: TextCapitalization.sentences,
      validator: validator,
      onSaved: (value) {
        if (onSaved == null) return;
        final dotified = value.dotifyIfNumber();
        final doubleValue = double.tryParse(dotified);
        onSaved(doubleValue);
      },
      decoration: InputDecoration(
        isCollapsed: true,
        contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            style: BorderStyle.none,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        hintText: hint ?? context.loc.promptSearch,
      ),
    );
  }

  double _toFractional(double minutes, double seconds) {
    final totalSeconds = minutes * 60 + seconds;
    return totalSeconds / 3600;
  }
}
