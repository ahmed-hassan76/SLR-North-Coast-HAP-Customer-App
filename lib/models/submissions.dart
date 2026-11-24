import 'package:flutter/widgets.dart' show StringCharacters;

import 'resident.dart';

enum SubmissionType {
  feedback('Feedback'),
  complaint('Complaint');

  const SubmissionType(this.label);
  final String label;
}

enum FeedbackCategory {
  beach('Beach'),
  cleanliness('Cleanliness'),
  customerService('Customer Service'),
  landscaping('Landscaping'),
  maintenance('Maintenance'),
  noise('Noise'),
  other('Other'),
  parking('Parking'),
  security('Security'),
  swimmingPool('Swimming Pool'),
  utilities('Utilities');

  const FeedbackCategory(this.label);
  final String label;
  static const customMaxLength = 100;

  String? validateCustomCategory(String? value) {
    if (this != other) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your category.';
    if (text.characters.length > customMaxLength) {
      return 'Use $customMaxLength characters or fewer.';
    }
    return null;
  }
}

enum SubmissionStatus {
  received('Received'),
  pendingFollowUp('Pending Follow-up');

  const SubmissionStatus(this.label);
  final String label;
}

enum SurveyQuestion {
  cleanliness(
    'How would you rate the cleanliness of the compound and common areas?',
  ),
  maintenance(
    'How would you rate the maintenance of the compound and its facilities?',
  ),
  security('How would you rate the security service?'),
  service(
    "How would you rate the support provided by the compound's customer service team?",
  ),
  overall('How would you rate your overall experience at the compound?');

  const SurveyQuestion(this.prompt);
  final String prompt;
}

enum Rating {
  veryPoor(1, 'Very Poor'),
  poor(2, 'Poor'),
  average(3, 'Average'),
  good(4, 'Good'),
  excellent(5, 'Excellent'),
  notApplicable(null, 'Not Applicable / Not Used');

  const Rating(this.score, this.label);
  final int? score;
  final String label;
}

abstract class Submission {
  const Submission(this.id, this.resident, this.submittedAt);
  final String id;
  final Resident resident;
  final DateTime submittedAt;

  bool get followUpRequired;
  SubmissionStatus get status => followUpRequired
      ? SubmissionStatus.pendingFollowUp
      : SubmissionStatus.received;
}

class FeedbackSubmission extends Submission {
  const FeedbackSubmission(
    super.id,
    super.resident,
    super.submittedAt, {
    required this.type,
    required this.message,
    this.category,
    this.customCategory,
  });

  final SubmissionType type;
  final String message;
  // Submissions created before categories were introduced have no category.
  final FeedbackCategory? category;
  final String? customCategory;

  @override
  bool get followUpRequired => type == SubmissionType.complaint;
}

class SurveySubmission extends Submission {
  SurveySubmission(
    super.id,
    super.resident,
    super.submittedAt,
    Map<SurveyQuestion, Rating> responses,
  ) : answers = Map.unmodifiable(responses),
      flaggedQuestions = Map.unmodifiable({
        for (final entry in responses.entries)
          if (entry.value.score case final score? when score < 4)
            entry.key: score,
      });

  final Map<SurveyQuestion, Rating> answers;
  final Map<SurveyQuestion, int> flaggedQuestions;

  @override
  bool get followUpRequired => flaggedQuestions.isNotEmpty;
}
