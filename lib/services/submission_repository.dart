import '../models/resident.dart';
import '../models/submissions.dart';
import 'mock_auth_service.dart';

/// One instance per running app. Refreshing the page or restarting clears it.
class SubmissionRepository {
  SubmissionRepository(this.auth);

  final MockAuthService auth;
  final _feedback = <FeedbackSubmission>[];
  final _surveys = <SurveySubmission>[];
  int _nextId = 1;

  List<FeedbackSubmission> get feedback => List.unmodifiable(_feedback);
  List<SurveySubmission> get surveys => List.unmodifiable(_surveys);

  Resident get _resident =>
      auth.currentResident ?? (throw StateError('Please log in to submit.'));

  FeedbackSubmission submitFeedback(
    SubmissionType type,
    String message, {
    required FeedbackCategory category,
    String? customCategory,
  }) {
    final resident = _resident;
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Please enter a message.');
    }
    final error = category.validateCustomCategory(customCategory);
    if (error != null) throw ArgumentError(error);
    final submission = FeedbackSubmission(
      'FB-${_nextId++}',
      resident,
      DateTime.now().toUtc(),
      type: type,
      message: trimmed,
      category: category,
      customCategory: category == FeedbackCategory.other
          ? customCategory!.trim()
          : null,
    );
    _feedback.add(submission);
    return submission;
  }

  SurveySubmission submitSurvey(Map<SurveyQuestion, Rating> answers) {
    final resident = _resident;
    if (!SurveyQuestion.values.every(answers.containsKey)) {
      throw ArgumentError('Please answer every question.');
    }
    final submission = SurveySubmission(
      'SV-${_nextId++}',
      resident,
      DateTime.now().toUtc(),
      answers,
    );
    _surveys.add(submission);
    return submission;
  }
}
