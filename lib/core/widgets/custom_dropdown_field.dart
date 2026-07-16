import 'package:flutter/material.dart';

class CustomDropdownField extends StatelessWidget {
  final String labelText;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;

  const CustomDropdownField({
    super.key,
    required this.labelText,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: labelText),
      initialValue: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}