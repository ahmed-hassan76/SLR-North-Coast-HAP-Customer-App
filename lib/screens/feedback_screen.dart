import 'package:material_ui/material_ui.dart';

import '../models/resident.dart';
import '../models/submissions.dart';
import '../services/submission_repository.dart';
import '../theme/portal_theme.dart';
import '../widgets/portal_layout.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({
    super.key,
    required this.resident,
    required this.repository,
  });
  final Resident resident;
  final SubmissionRepository repository;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  final _customCategory = TextEditingController();
  FeedbackCategory? _category;
  SubmissionType? _type;
  bool _submitted = false;

  @override
  void dispose() {
    _message.dispose();
    _customCategory.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitted || !_formKey.currentState!.validate()) return;
    setState(() => _submitted = true);
    widget.repository.submitFeedback(
      _type!,
      _message.text,
      category: _category!,
      customCategory: _customCategory.text,
    );
    await confirmSubmission(
      context,
      'Thank you for contacting us. Your submission has been received. If you reported a complaint, our team will contact you to follow up.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PortalScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeading(
            'Resident Feedback & Complaints',
            'Share your feedback or let us know about an issue.',
          ),
          const SizedBox(height: 24),
          Panel(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    initialValue: widget.resident.name,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      fillColor: canvas,
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    initialValue: widget.resident.phone,
                    readOnly: true,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      fillColor: canvas,
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 22),
                  DropdownButtonFormField<SubmissionType>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Submission Type',
                    ),
                    items: [
                      for (final type in SubmissionType.values)
                        DropdownMenuItem(value: type, child: Text(type.label)),
                    ],
                    onChanged: (type) => _type = type,
                    validator: (value) =>
                        value == null ? 'Choose feedback or complaint.' : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<FeedbackCategory>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    hint: const Text('Select a category'),
                    items: [
                      for (final category in FeedbackCategory.values)
                        DropdownMenuItem(
                          value: category,
                          child: Text(category.label),
                        ),
                    ],
                    onChanged: (category) => setState(() {
                      _category = category;
                      if (category != FeedbackCategory.other) {
                        _customCategory.clear();
                      }
                    }),
                    validator: (value) =>
                        value == null ? 'Choose a category.' : null,
                  ),
                  if (_category == FeedbackCategory.other) ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const ValueKey('customCategory'),
                      controller: _customCategory,
                      maxLength: FeedbackCategory.customMaxLength,
                      decoration: const InputDecoration(
                        labelText: 'Specify Category',
                        hintText: 'Please specify your category',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      validator: FeedbackCategory.other.validateCustomCategory,
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _message,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Your Message',
                      alignLabelWithHint: true,
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hintText: 'Please describe your feedback or complaint.',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your message.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitted ? null : _submit,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
