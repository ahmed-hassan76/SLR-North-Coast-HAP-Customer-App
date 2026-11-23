import 'package:customer_app/services/appointment_repository.dart';
import 'package:customer_app/app/portal_app.dart';
import 'package:customer_app/config/customer_support_config.dart';
import 'package:customer_app/config/app_feature_registry.dart';
import 'package:customer_app/services/chatbot_service.dart';
import 'package:customer_app/services/mock_auth_service.dart';
import 'package:customer_app/services/stay_repository.dart';
import 'package:customer_app/services/submission_repository.dart';
import 'package:customer_app/widgets/customer_assistant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<MockAuthService> start(
    WidgetTester tester, {
    Size size = const Size(390, 800),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final auth = MockAuthService()..login('01000000000', 'Demo1234');
    await tester.pumpWidget(
      PortalApp(
        auth: auth,
        appointments: AppointmentRepository(auth),
        stays: StayRepository(auth),
        repository: SubmissionRepository(auth),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'FAQ opens once, expands and collapses, and displays shared contacts',
    (tester) async {
      await start(tester);
      await tap(tester, find.text('FAQ'));
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.textContaining('Demonstration'), findsNothing);
      expect(find.text('FAQ'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNWidgets(13));
      expect(
        faqItems
            .singleWhere(
              (item) =>
                  item.question == 'Can I cancel my scheduled appointment?',
            )
            .answer,
        'Yes. Open My Appointments and select Cancel Appointment. Cancellation is available only before the appointment date.',
      );
      for (final item in faqItems) {
        expect(find.text(item.question), findsOneWidget);
        await tap(tester, find.text(item.question));
        expect(find.text(item.answer), findsOneWidget);
        await tap(tester, find.text(item.question));
        expect(find.text(item.answer), findsNothing);
      }
      for (final contact in SupportContact.values) {
        expect(find.text(contact.value), findsOneWidget);
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Welcome, Demo Resident'), findsOneWidget);
    },
  );

  testWidgets(
    'chat preserves form and conversation across pages and clears on logout',
    (tester) async {
      final auth = await start(tester);
      await tap(tester, find.text('Open Form'));
      final message = find.byType(TextFormField).last;
      await tester.enterText(message, 'Draft feedback');
      await tap(tester, find.text('AI Assistant'));
      expect(find.byType(CustomerAssistant), findsOneWidget);
      expect(
        find.text(
          "Hello! I'm your HAP Customer Assistant. What can I help you with today?",
        ),
        findsOneWidget,
      );
      expect(find.text('How can I help you?'), findsNothing);
      final input = find.descendant(
        of: find.byType(CustomerAssistant),
        matching: find.byType(TextField),
      );
      await tester.enterText(input, '   ');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(
        find.text(ChatbotService.answer(ChatIntent.unknown)),
        findsNothing,
      );
      await tester.enterText(input, 'What is your email?');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(
        find.text(ChatbotService.answer(ChatIntent.support)),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(input).controller!.text, isEmpty);
      expect(find.textContaining('Demonstration'), findsNothing);
      await tester.enterText(input, 'Hi');
      await tester.pump();
      await tap(tester, find.byTooltip('Send'));
      expect(
        find.text(ChatbotService.answer(ChatIntent.greeting)),
        findsOneWidget,
      );
      await tap(tester, find.byTooltip('Close assistant'));
      expect(find.text('Draft feedback'), findsOneWidget);
      await tap(tester, find.text('FAQ'));
      await tap(tester, find.text('AI Assistant'));
      expect(
        find.text(ChatbotService.answer(ChatIntent.greeting)),
        findsOneWidget,
      );
      await tap(tester, find.byTooltip('Close assistant'));
      auth.logout();
      await tester.pumpAndSettle();
      expect(find.text('FAQ'), findsNothing);
      expect(find.text('AI Assistant'), findsNothing);
      auth.login('01000000000', 'Demo1234');
      await tester.pumpAndSettle();
      await tap(tester, find.text('AI Assistant'));
      expect(
        find.text(ChatbotService.answer(ChatIntent.greeting)),
        findsNothing,
      );
      expect(find.text(ChatbotService.welcome), findsOneWidget);
    },
  );

  for (final size in [const Size(390, 800), const Size(1280, 800)]) {
    testWidgets('help controls and chat fit the available space at $size', (
      tester,
    ) async {
      await start(tester, size: size);
      await tap(tester, find.text('Open Form'));
      final submit = find.widgetWithText(FilledButton, 'Submit');
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      final button = tester.getRect(submit);
      final faq = tester.getRect(find.widgetWithText(FilledButton, 'FAQ'));
      final assistant = tester.getRect(
        find.widgetWithText(FilledButton, 'AI Assistant'),
      );
      expect(faq.bottom, lessThanOrEqualTo(assistant.top));
      expect(button.overlaps(faq) || button.overlaps(assistant), isFalse);
      await tap(tester, find.text('AI Assistant'));
      if (size.width > 700) {
        expect(
          tester.getCenter(find.byType(Dialog).first).dx,
          greaterThanOrEqualTo(size.width / 2),
        );
      }
      tester.view.viewInsets = const FakeViewPadding(bottom: 290);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.byTooltip('Send')).dy,
        lessThanOrEqualTo(size.height - 290),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
