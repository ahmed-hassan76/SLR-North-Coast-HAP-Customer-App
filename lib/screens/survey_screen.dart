import 'package:material_ui/material_ui.dart';

import '../models/submissions.dart';
import '../services/submission_repository.dart';
import '../theme/portal_theme.dart';
import '../widgets/portal_layout.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key, required this.repository});
  final SubmissionRepository repository;
  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _answers = <SurveyQuestion, Rating>{};
  bool _submitted = false;

  Future<void> _submit() async {
    if (_submitted) return;
    final invalid = _formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      await Scrollable.ensureVisible(
        invalid.first.context,
        duration: const Duration(milliseconds: 220),
      );
      return;
    }
    setState(() => _submitted = true);
    widget.repository.submitSurvey(_answers);
    await confirmSubmission(
      context,
      'Thank you for your feedback. Your responses will help us improve your experience.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PortalScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeading(
              'Resident Satisfaction Survey',
              'Please rate your experience at the compound.',
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final rating in Rating.values.where(
                  (value) => value.score != null,
                ))
                  Text(
                    '${rating.score} = ${rating.label}',
                    style: const TextStyle(
                      color: sea,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            for (final question in SurveyQuestion.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: FormField<Rating>(
                  key: ValueKey(question),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => value == null
                      ? 'Select one answer for this question.'
                      : null,
                  builder: (field) => Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Question ${question.index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: sea,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          question.prompt,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 1.4,
                            color: navy,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final rating in Rating.values)
                              ChoiceChip(
                                label: Text(
                                  rating.score?.toString() ?? rating.label,
                                ),
                                tooltip: rating.label,
                                selected: field.value == rating,
                                selectedColor: mist,
                                showCheckmark: false,
                                side: BorderSide(
                                  color: field.value == rating ? sea : line,
                                ),
                                onSelected: (_) {
                                  field.didChange(rating);
                                  _answers[question] = rating;
                                },
                              ),
                          ],
                        ),
                        if (field.hasError)
                          Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            FilledButton(
              onPressed: _submitted ? null : _submit,
              child: const Text('Submit Survey'),
            ),
          ],
        ),
      ),
    );
  }
}
