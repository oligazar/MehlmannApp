import 'package:flutter/material.dart';
import 'package:mahlmann_app/blocs/bloc_map.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:mahlmann_app/models/built_value/field.dart';
import 'package:mahlmann_app/screens/screen_map.dart';

class SearchBox extends StatefulWidget {
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final String hintText;
  final String initialText;
  final Widget child;

  const SearchBox({
    Key key,
    this.icon,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.initialText,
    this.child,
  }) : super(key: key);

  @override
  _SearchBoxState createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  BlocMap get _bloc => context.provide<BlocMap>();

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
          Flexible(
            child: StreamBuilder<List<Field>>(
              stream: _bloc.searchedFieldSuggestions,
              builder: (context, snapshot) {
                final fields = snapshot.data ?? [];
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (Field field in fields)
                        SearchSuggestionItem(
                          field: field,
                          onSelected: _bloc.onSuggestionFieldClick,
                        )
                    ],
                  ),
                );
              },
            ),
          )
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
