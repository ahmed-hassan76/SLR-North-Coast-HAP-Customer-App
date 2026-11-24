import 'package:customer_app/models/submissions.dart';
import 'package:customer_app/services/mock_auth_service.dart';
import 'package:customer_app/services/submission_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockAuthService auth;
  late SubmissionRepository repository;

  setUp(() {
    auth = MockAuthService();
    repository = SubmissionRepository(auth);
  });

  tearDown(() => auth.dispose());

  void login() => expect(auth.login('01000000000', 'Demo1234'), isTrue);

  Map<SurveyQuestion, Rating> all(Rating rating) => {
    for (final question in SurveyQuestion.values) question: rating,
  };

  test('only demo credentials establish the session and logout clears it', () {
    expect(auth.login('01000000001', 'Demo1234'), isFalse);
    expect(auth.login('01000000000', 'demo1234'), isFalse);
    expect(auth.currentResident, isNull);
    login();
    expect(auth.currentResident!.id, 'RES001');
    expect(auth.currentResident!.name, 'Demo Resident');
    expect(auth.currentResident!.phone, '01000000000');
    auth.logout();
    expect(auth.currentResident, isNull);
  });

  test('both submissions require an authenticated session', () {
    login();
    auth.logout();
    expect(
      () => repository.submitFeedback(
        SubmissionType.feedback,
        'Test',
        category: FeedbackCategory.beach,
      ),
      throwsStateError,
    );
    expect(() => repository.submitSurvey(all(Rating.good)), throwsStateError);
    expect(repository.feedback, isEmpty);
    expect(repository.surveys, isEmpty);
  });

  test('complaints require follow-up; feedback is received', () {
    login();
    final complaint = repository.submitFeedback(
      SubmissionType.complaint,
      '  Broken gate  ',
      category: FeedbackCategory.maintenance,
      customCategory: 'ignored',
    );
    final feedback = repository.submitFeedback(
      SubmissionType.feedback,
      'Lovely gardens',
      category: FeedbackCategory.other,
      customCategory: '  Garden accessibility  ',
    );
    expect(complaint.followUpRequired, isTrue);
    expect(complaint.status.label, 'Pending Follow-up');
    expect(complaint.message, 'Broken gate');
    expect(complaint.category, FeedbackCategory.maintenance);
    expect(complaint.customCategory, isNull);
    expect(feedback.category, FeedbackCategory.other);
    expect(feedback.customCategory, 'Garden accessibility');
    expect(feedback.followUpRequired, isFalse);
    expect(feedback.status.label, 'Received');
    expect(complaint.id, isNot(feedback.id));
    expect(complaint.resident, auth.currentResident);
    expect(complaint.submittedAt.isUtc, isTrue);
    expect(repository.feedback, [complaint, feedback]);
  });

  test('blank messages and incomplete surveys are rejected before saving', () {
    login();
    expect(
      () => repository.submitFeedback(
        SubmissionType.feedback,
        '   ',
        category: FeedbackCategory.beach,
      ),
      throwsArgumentError,
    );
    expect(
      () => repository.submitSurvey({
        SurveyQuestion.security: Rating.notApplicable,
      }),
      throwsArgumentError,
    );
    expect(repository.feedback, isEmpty);
    expect(repository.surveys, isEmpty);
  });

  test(
    'Other requires a description of at most 100 characters before saving',
    () {
      login();
      for (final description in [null, '', '   ', 'a' * 101]) {
        expect(
          () => repository.submitFeedback(
            SubmissionType.feedback,
            'Message',
            category: FeedbackCategory.other,
            customCategory: description,
          ),
          throwsArgumentError,
        );
      }
      expect(repository.feedback, isEmpty);
      final record = repository.submitFeedback(
        SubmissionType.feedback,
        'Message',
        category: FeedbackCategory.other,
        customCategory: 'a' * 100,
      );
      expect(record.customCategory, hasLength(100));
    },
  );

  test('older feedback records are readable without a category', () {
    final legacy = FeedbackSubmission(
      'FB-1',
      MockAuthService.demoResident,
      DateTime.utc(2025),
      type: SubmissionType.complaint,
      message: 'Broken gate',
    );
    expect(legacy.message, 'Broken gate');
    expect(legacy.status, SubmissionStatus.pendingFollowUp);
    expect(legacy.category, isNull);
    expect(legacy.customCategory, isNull);
  });

  test('all low ratings retain their questions and scores in a snapshot', () {
    login();
    final answers = all(Rating.excellent)
      ..[SurveyQuestion.cleanliness] = Rating.veryPoor
      ..[SurveyQuestion.security] = Rating.poor
      ..[SurveyQuestion.service] = Rating.average
      ..[SurveyQuestion.maintenance] = Rating.notApplicable;
    final result = repository.submitSurvey(answers);
    answers.clear();
    expect(result.answers, hasLength(5));
    expect(result.answers[SurveyQuestion.maintenance], Rating.notApplicable);
    expect(result.flaggedQuestions, {
      SurveyQuestion.cleanliness: 1,
      SurveyQuestion.security: 2,
      SurveyQuestion.service: 3,
    });
    expect(result.followUpRequired, isTrue);
    expect(result.status, SubmissionStatus.pendingFollowUp);
    expect(result.resident, auth.currentResident);
    expect(repository.surveys.single, result);
  });

  test('ratings of 4, 5 and not applicable are received without follow-up', () {
    login();
    final mixed = repository.submitSurvey(
      all(Rating.good)
        ..[SurveyQuestion.overall] = Rating.excellent
        ..[SurveyQuestion.service] = Rating.notApplicable,
    );
    final unused = repository.submitSurvey(all(Rating.notApplicable));
    for (final survey in [mixed, unused]) {
      expect(survey.status, SubmissionStatus.received);
      expect(survey.followUpRequired, isFalse);
      expect(survey.flaggedQuestions, isEmpty);
    }
    expect(mixed.id, isNot(unused.id));
  });
}
