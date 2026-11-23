import 'package:customer_app/services/appointment_repository.dart';

import 'dart:async';

import 'package:customer_app/app/portal_app.dart';
import 'package:customer_app/services/mock_auth_service.dart';
import 'package:customer_app/services/stay_repository.dart';
import 'package:customer_app/services/submission_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const channel = MethodChannel('hap/stay_storage');
  final records = <String, String>{};
  late DateTime today;
  late MockAuthService auth;
  var failSave = false;
  Completer<void>? pendingWrite;

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    auth = MockAuthService()..login('01000000000', 'Demo1234');
    today = DateTime(2028, 5, 10);
    records.clear();
    failSave = false;
    pendingWrite = null;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'get') return records[call.arguments as String];
      if (call.method == 'replace') {
        if (failSave) throw PlatformException(code: 'save_failed');
        final key = call.arguments['key'] as String;
        if (records[key] != call.arguments['expected']) return false;
        records[key] = call.arguments['value'] as String;
        return true;
      }
      if (call.method == 'save') {
        if (failSave) throw PlatformException(code: 'save_failed');
        if (pendingWrite != null) await pendingWrite!.future;
        records[call.arguments['key']] = call.arguments['value'];
        return null;
      }
      return records.values.toList();
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(
      PortalApp(
        auth: auth,
        repository: SubmissionRepository(auth),
        appointments: AppointmentRepository(auth),
        stays: StayRepository(auth, clock: () => today),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> date(WidgetTester tester, String field, int day) async {
    await tap(tester, find.byTooltip('Select $field'));
    await tap(
      tester,
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('$day'),
      ),
    );
    await tap(tester, find.text('OK'));
  }

  Future<void> fill(WidgetTester tester) async {
    await tap(tester, find.byType(DropdownButtonFormField<int>));
    await tap(tester, find.text('Parcel 2').last);
    await date(tester, 'Arrival Date', 12);
    await date(tester, 'Departure Date', 15);
  }

  testWidgets(
    'home card opens the planner and My Stays refreshes after departure day',
    (tester) async {
      await start(tester);
      await tap(tester, find.text('Plan Your Stay'));
      await fill(tester);
      await tap(tester, find.text('Confirm My Stay'));
      await tap(tester, find.text('OK'));
      today = DateTime(2028, 5, 15, 23, 59);
      await tap(tester, find.text('My Stays'));
      expect(find.text('Scheduled'), findsOneWidget);
      today = DateTime(2028, 5, 16);
      await tap(tester, find.byTooltip('Refresh stays'));
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Scheduled'), findsNothing);
    },
  );

  testWidgets(
    'keep, failed save, successful cancellation and expiry during confirmation',
    (tester) async {
      await start(tester);
      final repository = tester.widget<PortalApp>(find.byType(PortalApp)).stays;
      for (final parcel in [1, 2]) {
        await repository.schedule(
          parcel: parcel,
          arrival: DateTime(2028, 5, 12),
          departure: DateTime(2028, 5, 15),
        );
      }
      await tap(tester, find.text('My Stays'));
      final cancel = find.text('Cancel Stay');
      final yes = find.text('Yes, Cancel Stay');
      final success = find.text('Your stay has been cancelled successfully.');
      await tap(tester, cancel.first);
      expect(find.text('Cancel Your Stay?'), findsOneWidget);
      await tap(tester, find.text('Keep My Stay'));
      expect(find.text('Scheduled'), findsNWidgets(2));
      failSave = true;
      await tap(tester, cancel.first);
      await tap(tester, yes);
      expect(find.textContaining('could not be saved'), findsOneWidget);
      expect(success, findsNothing);
      expect(cancel, findsNWidgets(2));
      failSave = false;
      await tap(tester, cancel.first);
      await tap(tester, yes);
      expect(success, findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(cancel, findsOneWidget);
      await tap(tester, cancel);
      today = DateTime(2028, 5, 12);
      await tap(tester, yes);
      expect(cancel, findsNothing);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
    },
  );

  testWidgets(
    'empty list opens form, parcel and dates are required, changing arrival clears invalid departure',
    (tester) async {
      await start(tester);
      await tap(tester, find.text('My Stays'));
      expect(find.text("You haven't planned any stays yet."), findsOneWidget);
      await tap(tester, find.text('Plan Your First Stay'));
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[0].readOnly && fields[1].readOnly, isTrue);
      expect(fields[0].controller!.text, 'Demo Resident');
      expect(fields[1].controller!.text, '01000000000');
      final dropdown = tester.widget<DropdownButtonFormField<int>>(
        find.byType(DropdownButtonFormField<int>),
      );
      expect(dropdown.initialValue, isNull);
      await tap(tester, find.text('Confirm My Stay'));
      for (final message in [
        'Select your parcel.',
        'Select your arrival date.',
        'Select your departure date.',
      ]) {
        expect(find.text(message), findsOneWidget);
      }
      await tap(tester, find.byType(DropdownButtonFormField<int>));
      final items = tester.widgetList<DropdownMenuItem<int>>(
        find.byType(DropdownMenuItem<int>, skipOffstage: false),
      );
      expect(items.map((item) => (item.child as Text).data).toSet(), {
        for (var i = 1; i <= 15; i++) 'Parcel $i',
      });
      await tap(tester, find.text('Parcel 2').last);
      await date(tester, 'Departure Date', 15);
      await date(tester, 'Arrival Date', 12);
      expect(find.text('Stay Duration: 3 Nights'), findsOneWidget);
      await date(tester, 'Arrival Date', 15);
      expect(find.text('Stay Duration: 3 Nights'), findsNothing);
      await tap(tester, find.text('Confirm My Stay'));
      expect(find.text('Select your departure date.'), findsOneWidget);
      expect(records, isEmpty);
    },
  );

  testWidgets(
    'save failure preserves form; successful retry saves once, confirms, returns home and lists stay',
    (tester) async {
      await start(tester);
      await tap(tester, find.text('My Stays'));
      await tap(tester, find.text('Plan Your First Stay'));
      await fill(tester);
      failSave = true;
      await tap(tester, find.text('Confirm My Stay'));
      expect(find.textContaining('could not be saved'), findsOneWidget);
      expect(find.text('Request Submitted!'), findsNothing);
      failSave = false;
      pendingWrite = Completer<void>();
      final submit = find.text('Confirm My Stay');
      await tester.ensureVisible(submit);
      final position = tester.getCenter(submit);
      await tester.tapAt(position);
      await tester.tapAt(position);
      await tester.pump();
      expect(find.text('Request Submitted!'), findsNothing);
      pendingWrite!.complete();
      await tester.pumpAndSettle();
      expect(records, hasLength(1));
      expect(find.text('Request Submitted!'), findsOneWidget);
      expect(find.text('Services Scheduled for Activation.'), findsOneWidget);
      await tap(tester, find.text('OK'));
      expect(find.text('Welcome, Demo Resident'), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
      await tap(tester, find.text('My Stays'));
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Parcel 2'), findsOneWidget);
      expect(find.text('Stay Duration: 3 Nights'), findsOneWidget);
      await tap(tester, find.text('Plan Another Stay'));
      expect(find.text('Confirm My Stay'), findsOneWidget);
    },
  );
}
