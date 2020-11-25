import 'package:flutter/material.dart';

class MTextField extends StatelessWidget {
  final String hint;
  final FormFieldValidator<String> validator;
  final FormFieldSetter<String> onSaved;
  final ValueChanged<String> onSubmitted;

  const MTextField({
    @required this.hint,
    Key key,
    this.validator,
    this.onSaved,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onFieldSubmitted: onSubmitted,
      validator: validator,
      onSaved: onSaved,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        border: OutlineInputBorder(),
        hintText: this.hint ?? "",
        hintStyle: const TextStyle(
          color: Colors.black54,
          fontSize: 15,
        ),
        isCollapsed: true,
      ),
    );
  }
}
