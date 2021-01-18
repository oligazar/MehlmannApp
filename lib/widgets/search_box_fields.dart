import 'package:flutter/material.dart';
import 'package:mahlmann_app/common/extensions.dart';

class SearchBoxFields extends StatefulWidget {
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final String hintText;
  final String initialText;
  final Widget child;

  const SearchBoxFields({
    Key key,
    this.icon,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.initialText,
    this.child,
  }) : super(key: key);

  @override
  _SearchBoxFieldsState createState() => _SearchBoxFieldsState();
}

class _SearchBoxFieldsState extends State<SearchBoxFields> {
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
          TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hintText ?? context.loc.promptSearch,
            ),
          ),
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
}
