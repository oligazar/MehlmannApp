import 'package:flutter/material.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:mahlmann_app/common/lang/m_localizations.dart';
import 'package:mahlmann_app/widgets/dialogs/one_action_dialog.dart';
import 'package:mahlmann_app/widgets/preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferenceRadioList<T> extends StatefulWidget {
	final String title;
	final String subTitle;
	final String dialogTitle;
	final String prefKey;
	final ValueChanged<PrefRadioItem<T>> onSelected;
	final List<PrefRadioItem<T>> items;
	final bool isVisible;
	final bool dismissible;
	final IconData icon;
	
	final TextStyle style;
	
	const PreferenceRadioList({
		Key key,
		@required this.title,
		@required this.subTitle,
		@required this.dialogTitle,
		this.onSelected,
		this.items,
		this.style,
		this.prefKey,
		this.icon,
		this.isVisible = true,
		this.dismissible = true,
	}) : super(key: key);
	
	@override
	_PreferenceRadioListState<T> createState() => _PreferenceRadioListState<T>();
}

typedef TitleMaker = String Function();

class _PreferenceRadioListState<T> extends State<PreferenceRadioList<T>> {
	TitleMaker _subtitleMaker;
	T _value;
	
	@override
	void initState() {
		prepareState();
		super.initState();
	}
	
	@override
	Widget build(BuildContext context) {
		return widget.isVisible
				? Preference(
			title: widget.title,
			subTitle: _subtitleMaker != null ? _subtitleMaker() ?? widget.subTitle : widget.subTitle,
			icon: widget.icon,
			onTap: () async {
				// show dialog here
				final item = await _showDialog();
				if (item != null) _onSelected(item);
			},
		)
				: Container();
	}
	
	Future<PrefRadioItem<T>> _showDialog() async {
		return await showDialog(
			context: context,
			barrierDismissible: widget.dismissible,
			builder: (BuildContext context) => RadioListDialog(
				dialogTitle: widget.dialogTitle,
				items: widget.items,
				initialValue: _value,
			),
		);
	}
	
	void _onSelected(PrefRadioItem<T> item) async {
		setState(() {
			_subtitleMaker = item.titleMaker;
			_value = item.value;
		});
		final SharedPreferences prefs = await SharedPreferences.getInstance();
		if (T == int) {
			prefs.setInt(widget.prefKey, item.value as int);
		} else if (T == String) {
			prefs.setString(widget.prefKey, item.value as String);
		} else if (T == double) {
			prefs.setDouble(widget.prefKey, item.value as double);
		} else {
			throw Exception('Unsupported type: $T');
		}
		if (widget.onSelected != null) widget.onSelected(item);
	}
	
	void prepareState() async {
		final SharedPreferences prefs = await SharedPreferences.getInstance();
		T value;
		if (T == int) {
			value = prefs.getInt(widget.prefKey) as T;
		} else if (T == String) {
			value = prefs.getString(widget.prefKey) as T;
		} else if (T == double) {
			value = prefs.getDouble(widget.prefKey) as T;
		}  else {
			throw Exception('Unsupported type: $T');
		}
		print('initial radio value: $value');
		TitleMaker subtitleMaker = widget.items.firstWhere((i) => i.value == value, orElse: () => null)?.titleMaker ?? () => widget.subTitle;
		
		setState(() {
			_value = value;
			_subtitleMaker = subtitleMaker;
		});
	}
}

class RadioListDialog<T> extends StatefulWidget {
	final String dialogTitle;
	final List<PrefRadioItem<T>> items;
	final T initialValue;
	
	RadioListDialog({
		this.dialogTitle,
		this.items,
		this.initialValue,
	});
	
	@override
	_RadioListDialogState<T> createState() => _RadioListDialogState<T>();
}

class _RadioListDialogState<T> extends State<RadioListDialog<T>> {
	MLocalizations get _loc => context.loc;
	T _groupValue;
	
	@override
	void initState() {
		_groupValue = widget.initialValue;
		super.initState();
	}
	
	@override
	Widget build(BuildContext context) {
		return OneActionDialog(
			title: widget.dialogTitle ?? "",
			btnTitle: _loc.btnCancel,
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: widget.items
						.map((item) => _buildRadioListItem(item, _groupValue, (selectedItem) {
					setState(() => _groupValue = selectedItem.value);
					Navigator.of(context).pop(selectedItem);
				}))
						.toList(),
			),
			action: () => Navigator.of(context).pop(),
		);
	}
	
	Widget _buildRadioListItem(
			PrefRadioItem model, T groupValue, Function(PrefRadioItem<T>) onChecked) {
		return InkWell(
			onTap: () => onChecked(model),
			child: Container(
				child: Row(
					children: <Widget>[
						Radio(
							value: model.value,
							groupValue: groupValue,
							onChanged: (_) => onChecked(model),
						),
						Expanded(
							child: Text(
								model.titleMaker(),
							),
						)
					],
				),
			),
		);
	}
}

class PrefRadioItem<T> {
	final TitleMaker titleMaker;
	final T value;
	
	PrefRadioItem({
		this.titleMaker,
		this.value,
	});
}