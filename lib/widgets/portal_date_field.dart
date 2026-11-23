import 'package:material_ui/material_ui.dart';

class PortalDateField extends StatelessWidget {
  const PortalDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    required this.validator,
  });
  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(value),
      readOnly: true,
      showCursor: false,
      initialValue: value == null
          ? ''
          : MaterialLocalizations.of(context).formatShortDate(value!),
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Select date',
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: IconButton(
          tooltip: 'Select $label',
          icon: const Icon(Icons.calendar_today_outlined),
          onPressed: onTap,
        ),
      ),
    );
  }
}
