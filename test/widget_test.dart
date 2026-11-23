import 'package:customer_app/services/appointment_repository.dart';
import 'package:customer_app/app/portal_app.dart';
import 'package:customer_app/models/submissions.dart';
import 'package:customer_app/services/mock_auth_service.dart';
import 'package:customer_app/services/stay_repository.dart';
import 'package:customer_app/services/submission_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late MockAuthService auth;
  late SubmissionRepository repository;

  Future<void> start(
    WidgetTester tester, {
    bool loggedIn = false,
    Size size = const Size(390, 800),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    auth = MockAuthService();
    repository = SubmissionRepository(auth);
    if (loggedIn) auth.login('01000000000', 'Demo1234');
    await tester.pumpWidget(
      PortalApp(
        auth: auth,
        repository: repository,
        appointments: AppointmentRepository(auth),
        stays: StayRepository(auth),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'mobile login validates, reveals password, authenticates, and logs out',
    (tester) async {
      await start(tester);
      await tap(tester, find.text('Login'));
      expect(find.text('Enter your phone number.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, '01000000001');
      await tester.enterText(fields.last, 'wrong');
      await tap(tester, find.byTooltip('Show password'));
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isFalse,
      );
      await tap(tester, find.text('Login'));
      expect(find.text('Incorrect phone number or password.'), findsOneWidget);
      await tap(tester, find.text('Use Demo Credentials'));
      expect(auth.currentResident, isNull);
      expect(find.text('Incorrect phone number or password.'), findsNothing);
      final inputs = tester.widgetList<TextField>(find.byType(TextField));
      expect(inputs.first.controller!.text, MockAuthService.demoResident.phone);
      expect(inputs.last.controller!.text, MockAuthService.demoPassword);
      await tap(tester, find.text('Login'));
      expect(find.text('Welcome, Demo Resident'), findsOneWidget);
      await tap(tester, find.text('Start Survey'));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Welcome, Demo Resident'), findsOneWidget);
      await tap(tester, find.text('Logout'));
      expect(find.text('Login'), findsOneWidget);
      expect(auth.currentResident, isNull);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
    },
  );

  testWidgets(
    'wide login displays beside the coastal image and opens both service cards',
    (tester) async {
      await start(tester, size: const Size(1280, 800));
      expect(
        tester.getCenter(find.text('Resident Portal')).dx,
        lessThan(tester.getCenter(find.text('Welcome back')).dx),
      );
      await tester.enterText(find.byType(TextFormField).first, '01000000000');
      await tester.enterText(find.byType(TextFormField).last, 'Demo1234');
      await tap(tester, find.text('Login'));
      expect(find.text('Open Form'), findsOneWidget);
      expect(find.text('Start Survey'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('signed-out navigation cannot open resident pages', (
    tester,
  ) async {
    await start(tester);
    for (final route in [
      '/feedback',
      '/survey',
      '/home',
      '/plan-stay',
      '/my-stays',
      '/faq',
      '/appointment',
      '/my-appointments',
    ]) {
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed<void>(route);
      await tester.pumpAndSettle();
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('AI Assistant'), findsNothing);
      expect(find.text('Frequently Asked Questions'), findsNothing);
      expect(find.text('Submit Survey'), findsNothing);
      expect(find.text('Your Message'), findsNothing);
      expect(find.text('Open Form'), findsNothing);
      navigator.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'feedback validates resident fields, saves once, and returns home',
    (tester) async {
      await start(tester, loggedIn: true);
      await tap(tester, find.text('Open Form'));
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[0].controller!.text, 'Demo Resident');
      expect(fields[1].controller!.text, '01000000000');
      expect(fields.take(2).every((field) => field.readOnly), isTrue);
      final submit = find.text('Submit');
      await tap(tester, submit);
      expect(find.text('Choose feedback or complaint.'), findsOneWidget);
      expect(find.text('Enter your message.'), findsOneWidget);
      expect(repository.feedback, isEmpty);
      await tap(tester, find.byType(DropdownButtonFormField<SubmissionType>));
      await tap(tester, find.text('Complaint').last);
      await tester.enterText(
        find.byType(TextFormField).last,
        'The gate needs repair.',
      );
      await tester.ensureVisible(submit);
      final submitPosition = tester.getCenter(submit);
      await tester.tapAt(submitPosition);
      await tester.tapAt(submitPosition);
      await tester.pumpAndSettle();
      expect(
        repository.feedback.single.status,
        SubmissionStatus.pendingFollowUp,
      );
      expect(
        find.text(
          'Thank you for contacting us. Your submission has been received. If you reported a complaint, our team will contact you to follow up.',
        ),
        findsOneWidget,
      );
      await tap(tester, find.text('Back to home'));
      expect(find.text('Welcome, Demo Resident'), findsOneWidget);
    },
  );

  testWidgets(
    'survey requires five answers, permits changing a rating, and confirms',
    (tester) async {
      await start(tester, loggedIn: true);
      await tap(tester, find.text('Start Survey'));
      await tap(tester, find.text('Submit Survey'));
      expect(
        find.text('Select one answer for this question.'),
        findsNWidgets(5),
      );
      expect(repository.surveys, isEmpty);
      for (final question in SurveyQuestion.values) {
        final group = find.byKey(ValueKey(question));
        final choices = find.descendant(
          of: group,
          matching: find.byType(ChoiceChip),
        );
        await tap(tester, choices.at(4));
        if (question == SurveyQuestion.security) {
          await tap(tester, choices.at(2));
        }
        if (question == SurveyQuestion.service) {
          await tap(tester, choices.last);
        }
      }
      await tap(tester, find.text('Submit Survey'));
      expect(repository.surveys.single.flaggedQuestions, {
        SurveyQuestion.security: 3,
      });
      expect(
        repository.surveys.single.answers[SurveyQuestion.service],
        Rating.notApplicable,
      );
      expect(
        find.text(
          'Thank you for your feedback. Your responses will help us improve your experience.',
        ),
        findsOneWidget,
      );
      await tap(tester, find.text('Back to home'));
      expect(find.text('Welcome, Demo Resident'), findsOneWidget);
    },
  );
}
