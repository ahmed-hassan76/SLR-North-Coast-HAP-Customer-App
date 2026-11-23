import 'package:material_ui/material_ui.dart';

import '../models/resident.dart';
import '../theme/portal_theme.dart';
import 'portal_layout.dart';

class ResidentInformation extends StatelessWidget {
  const ResidentInformation(
    this.resident, {
    super.key,
    this.title = 'Resident Information',
  });
  final Resident resident;
  final String title;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: heading(24)),
        const SizedBox(height: 18),
        TextFormField(
          initialValue: resident.name,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Customer Name',
            fillColor: canvas,
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: resident.phone,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            fillColor: canvas,
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
      ],
    ),
  );
}
