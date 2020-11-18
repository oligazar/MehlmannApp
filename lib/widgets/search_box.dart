import 'package:flutter/material.dart';
import 'package:mahlmann_app/common/extensions.dart';

class SearchBox extends StatefulWidget {
	final ValueChanged<String> onChanged;
	final IconData icon;
	final String hintText;
	final String initialText;
	
	const SearchBox({
		Key key,
		this.onChanged,
		this.icon,
		this.hintText,
		this.initialText,
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
	
	@override
	Widget build(BuildContext context) {
		return Container(
			padding: EdgeInsets.symmetric(horizontal: 12),
			decoration: BoxDecoration(
					color: Colors.white.withAlpha(200),
					borderRadius: BorderRadius.all(Radius.circular(16))
			),
		  child: TextField(
		  	controller: _controller,
		  	onSubmitted: (query) {
		  		widget.onChanged(query);
		  	},
		  	textCapitalization: TextCapitalization.sentences,
		  	decoration: InputDecoration(
				  border: InputBorder.none,
		  		hintText: widget.hintText ?? context.loc.promptSearch,
		  	),
		  ),
		);
	}
	
	@override
	void dispose() {
		super.dispose();
		_controller.dispose();
	}
}