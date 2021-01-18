import 'package:flutter/material.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:mahlmann_app/widgets/dialogs/m_dialog.dart';
import 'package:mahlmann_app/widgets/m_button.dart';

class SearchBoxLatLngs extends StatefulWidget {
  final ValueChanged<String> onSubmitted;
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
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white.withAlpha(220),
          borderRadius: BorderRadius.all(Radius.circular(16))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _placeholder,
          _buildRow(title: "Lat: "),
          _placeholder,
          _buildRow(title: "Lng: "),
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
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54
                      ),
                )),
                Flexible(
                    child: Switch(
                  value: true,
                  onChanged: (value) {},
                )),
              ],
            ),
          ),
          DialogButton(title: context.loc.btnOk, action: widget.onSubmitted),
          if (widget.child != null) widget.child,
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Widget _buildRow({String title}) {
    return Row(
      children: [
        if (title != null) Text(title),
        Expanded(
          child: _buildTextField(hint: context.loc.degrees),
        ),
        _placeholder,
        Expanded(
          child: _buildTextField(hint: context.loc.minutes),
        ),
        _placeholder,
        Expanded(
          child: _buildTextField(hint: context.loc.seconds),
        ),
      ],
    );
  }

  Widget get _placeholder => const SizedBox(width: 10, height: 10,);

  Widget _buildTextField({String hint}) {
    return TextFormField(
      controller: _controller,
      onChanged: widget.onChanged,
      // onSubmitted: widget.onSubmitted,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        isCollapsed: true,
        contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
        border: OutlineInputBorder(
          borderSide: BorderSide(style: BorderStyle.none,),
          borderRadius: BorderRadius.circular(8),
        ),
        hintText: hint ?? context.loc.promptSearch,
      ),
      
    );
  }
}
