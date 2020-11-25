import 'package:flutter/material.dart';
import 'package:mahlmann_app/widgets/m_dialog.dart';
import 'package:mahlmann_app/widgets/m_text_field.dart';
import 'package:mahlmann_app/common/extensions.dart';
import 'package:mahlmann_app/common/field_validator.dart';


class SelectSentenceDialog extends StatefulWidget {
  final Function action;
  final String title;

  const SelectSentenceDialog({
    Key key,
    this.action,
    this.title,
  }) : super(key: key);

  @override
  _SelectSentenceDialogState createState() => _SelectSentenceDialogState();
}

class _SelectSentenceDialogState extends State<SelectSentenceDialog> {
	
	String _sentenceName;
	final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
	bool _autoValidate = false;
	
  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return MDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Form(
	          key: _formKey,
	          autovalidateMode: _autoValidate == true ? AutovalidateMode.always : AutovalidateMode.disabled,
            child: MTextField(
              hint: loc.name,
	            validator: (s) => context.loc.errorEmptyField.ifEmpty(s),
	            onSaved: (name) => _sentenceName = name,
            ),
          ),
          DialogButton(
            title: widget.title ?? "",
            action: () {
	            if (_formKey.currentState.validate()) {
	            	_formKey.currentState.save();
	              Navigator.of(context).pop(_sentenceName);
	            } else {
		            setState(() => _autoValidate = true);
	            }
            },
          ),
        ],
      ),
      btnTitle: loc.abort,
    );
  }
}
