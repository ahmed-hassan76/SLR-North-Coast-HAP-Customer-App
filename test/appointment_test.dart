import 'dart:async';
import 'dart:convert';

import 'package:customer_app/app/portal_app.dart';
import 'package:customer_app/config/appointment_config.dart';
import 'package:customer_app/models/appointment.dart';
import 'package:customer_app/models/booking_status.dart';
import 'package:customer_app/models/resident.dart';
import 'package:customer_app/services/appointment_repository.dart';
import 'package:customer_app/services/mock_auth_service.dart';
import 'package:customer_app/services/stay_repository.dart';
import 'package:customer_app/services/submission_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _Session extends MockAuthService {
  @override
  Resident? currentResident = MockAuthService.demoResident;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('hap/stay_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final today = DateTime(2028, 5, 10);
  final tomorrow = DateTime(2028, 5, 11);
  late DateTime now;
  late _Session auth;
  late AppointmentRepository repo;
  late Map<String, String> disk;
  bool fail = false;
  Completer<void>? writing;

  setUp(() {
    disk = {};
    fail = false;
    writing = null;
    now = DateTime(2028, 5, 10, 10);
    auth = _Session();
    repo = AppointmentRepository(auth, clock: () => now);
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'get') return disk[call.arguments as String];
      if (call.method == 'read') {
        return [
          for (final e in disk.entries)
            if (e.key.startsWith(call.arguments as String)) e.value,
        ];
      }
      expect(call.method, 'replace');
      if (fail) throw PlatformException(code: 'save_failed');
      if (writing != null) await writing!.future;
      final key = call.arguments['key'] as String;
      if (disk[key] != call.arguments['expected']) return false;
      disk[key] = call.arguments['value'] as String;
      return true;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    auth.dispose();
  });

  test(
    'five department IDs, eight hourly slots and exact same-day cutoff',
    () async {
      expect(AppointmentConfig.departments.map((d) => d.name), [
        for (var i = 1; i <= 5; i++) 'Department $i',
      ]);
      expect(
        AppointmentConfig.departments.map((d) => d.id).toSet(),
        hasLength(5),
      );
      final slots = await repo.slots(today, 'dept-1');
      expect(slots.keys, [540, 600, 660, 720, 780, 840, 900, 960]);
      expect(slots[540], SlotStatus.elapsed);
      expect(slots[600], SlotStatus.elapsed);
      expect(slots[660], SlotStatus.available);
      now = DateTime(2028, 5, 10, 17);
      expect(
        (await repo.slots(today, 'dept-1')).values,
        everyElement(SlotStatus.elapsed),
      );
      expect(
        (await repo.slots(tomorrow, 'dept-1')).values,
        everyElement(SlotStatus.available),
      );
    },
  );

  test('invalid date, invalid department, unavailable time, and signed-out booking are rejected', () async {
    await expectLater(
      repo.book(DateTime(2028, 5, 9), 'dept-1', 660),
      throwsStateError,
    );
    await expectLater(repo.book(today, 'missing', 660), throwsStateError);
    await expectLater(repo.book(today, 'dept-1', 600), throwsStateError);
    await expectLater(repo.book(today, 'dept-1', 690), throwsStateError);
    auth.currentResident = null;
    await expectLater(repo.book(today, 'dept-1', 660), throwsStateError);
    await expectLater(repo.myAppointments(), throwsStateError);
    expect(disk, isEmpty);
  });

  test('exclusive bookings persist, filter by resident, and group upcoming before past', () async {
    final a = await repo.book(today, 'dept-1', 660);
    final b = await repo.book(tomorrow, 'dept-1', 660);
    final c = await repo.book(today, 'dept-2', 660);
    expect({a.id, b.id, c.id}, hasLength(3));
    expect((await repo.slots(today, 'dept-1'))[660], SlotStatus.booked);
    expect((await repo.slots(today, 'dept-3'))[660], SlotStatus.available);
    expect(
      (await repo.slots(DateTime(2028, 5, 14), 'dept-1'))[660],
      SlotStatus.available,
    );
    Future<bool> compete() async {
      try {
        await repo.book(tomorrow, 'dept-2', 600);
        return true;
      } on StateError {
        return false;
      }
    }

    expect(
      await Future.wait([compete(), compete()]),
      unorderedEquals([true, false]),
    );
    auth.currentResident = const Resident(
      id: 'RES002',
      name: 'Other resident',
      phone: '01000000001',
    );
    expect(await repo.myAppointments(), isEmpty);
    await expectLater(repo.book(tomorrow, 'dept-1', 660), throwsStateError);
    await repo.book(tomorrow, 'dept-5', 600);
    auth.currentResident = MockAuthService.demoResident;
    now = tomorrow;
    final reopened = AppointmentRepository(auth, clock: () => now);
    final bookings = await reopened.myAppointments();
    expect(bookings, hasLength(4));
    expect(bookings.take(2).map((b) => b.startMinute), [600, 660]);
    final restored = bookings.firstWhere((r) => r.id == a.id);
    expect(restored.department.name, 'Department 1');
    expect(restored.endMinute, 720);
    expect(restored.date, today);
    expect(restored.resident.phone, '01000000000');
    expect(restored.bookedAt, DateTime(2028, 5, 10, 10).toUtc());
  });

  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.tap(f);
    await t.pumpAndSettle();
  }

  test('cancellation uses local midnight and completion follows the end of the slot', () async {
    final booking = await repo.book(tomorrow, 'dept-1', 660);
    now = DateTime(2028, 5, 10, 23, 59, 59);
    expect(booking.canCancelOn(now.toUtc()), isTrue);
    for (final time in [tomorrow, booking.start, booking.end]) {
      now = time;
      expect(booking.statusOn(now), BookingStatus.scheduled);
      expect(booking.canCancelOn(now.toUtc()), isFalse);
      await expectLater(repo.cancel(booking), throwsStateError);
    }
    for (final time in [
      booking.end.add(const Duration(microseconds: 1)),
      DateTime(2028, 5, 12),
    ]) {
      now = time;
      expect(booking.statusOn(now), BookingStatus.completed);
      await expectLater(repo.cancel(booking), throwsStateError);
    }
  });

  test('legacy bookings can be cancelled and rebooked without losing resident history', () async {
    final first = await repo.book(tomorrow, 'dept-1', 660);
    disk[disk.keys.single] = jsonEncode(
      first.toJson(),
    ); // Original single-booking format.
    final otherSlot = await repo.book(tomorrow, 'dept-1', 720);
    const otherResident = Resident(
      id: 'RES002',
      name: 'Other resident',
      phone: '01000000001',
    );
    auth.currentResident = otherResident;
    await expectLater(repo.cancel(first), throwsStateError);
    auth.currentResident = MockAuthService.demoResident;
    now = DateTime(2028, 5, 10, 23, 59, 59);
    await repo.cancel(first);
    expect((await repo.slots(tomorrow, 'dept-1'))[660], SlotStatus.available);
    expect((await repo.slots(tomorrow, 'dept-1'))[720], SlotStatus.booked);
    await expectLater(repo.cancel(first), throwsStateError);
    auth.currentResident = otherResident;
    final replacement = await repo.book(tomorrow, 'dept-1', 660);
    expect(replacement.id, isNot(first.id));
    expect((await repo.myAppointments()).single.id, replacement.id);
    auth.currentResident = MockAuthService.demoResident;
    await expectLater(repo.cancel(first), throwsStateError);
    expect((await repo.slots(tomorrow, 'dept-1'))[660], SlotStatus.booked);
    final cancelledAt = now;
    now = DateTime(2028, 5, 20);
    final restored = await AppointmentRepository(
      auth,
      clock: () => now,
    ).myAppointments();
    expect(restored.map((a) => a.id), [otherSlot.id, first.id]);
    expect(restored.last.cancelledAt, cancelledAt.toUtc());
    expect(restored.last.statusOn(now), BookingStatus.cancelled);
  });

  test('sorts scheduled, completed and cancelled bookings in their respective orders', () async {
    final early = await repo.book(today, 'dept-1', 660);
    final late = await repo.book(today, 'dept-1', 720);
    final future = await repo.book(tomorrow, 'dept-1', 600);
    final later = await repo.book(tomorrow, 'dept-1', 660);
    final firstCancelled = await repo.book(tomorrow, 'dept-1', 780);
    final lastCancelled = await repo.book(tomorrow, 'dept-1', 540);
    await repo.cancel(firstCancelled);
    now = now.add(const Duration(seconds: 1));
    await repo.cancel(lastCancelled);
    now = DateTime(2028, 5, 10, 16);
    expect((await repo.myAppointments()).map((b) => b.id), [
      future.id,
      later.id,
      late.id,
      early.id,
      lastCancelled.id,
      firstCancelled.id,
    ]);
  });

  test('only Sunday through Thursday accept new bookings', () async {
    for (var day = 12; day <= 18; day++) {
      final date = DateTime(2028, 5, day);
      final weekend =
          date.weekday == DateTime.friday || date.weekday == DateTime.saturday;
      final slots = await repo.slots(date, 'dept-1');
      if (weekend) {
        expect(slots.values, isNot(contains(SlotStatus.available)));
        await expectLater(repo.book(date, 'dept-1', 540), throwsStateError);
      } else {
        expect(slots.values, everyElement(SlotStatus.available));
        expect((await repo.book(date, 'dept-1', 540)).date, date);
      }
    }
    expect(disk, hasLength(5));
  });

  test(
    'an existing Friday booking remains available in My Appointments',
    () async {
      final friday = DateTime(2028, 5, 12);
      final saved = Appointment(
        id: 'previous-booking',
        resident: MockAuthService.demoResident,
        department: AppointmentConfig.departments.first,
        date: friday,
        startMinute: 540,
        endMinute: 600,
        bookedAt: now.toUtc(),
      );
      disk['hap.appointments.v1/2028-05-12/dept-1/540'] = jsonEncode(
        saved.toJson(),
      );
      expect((await repo.myAppointments()).single.id, saved.id);
      expect((await repo.slots(friday, 'dept-1'))[540], SlotStatus.booked);
    },
  );

  Future<void> openMyAppointments(WidgetTester t) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(390, 844);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(
      PortalApp(
        auth: auth,
        repository: SubmissionRepository(auth),
        stays: StayRepository(auth),
        appointments: repo,
      ),
    );
    await t.pumpAndSettle();
    await tap(t, find.text('My Appointments'));
  }

  Future<void> open(WidgetTester t) async {
    await openMyAppointments(t);
    expect(
      find.text("You haven't scheduled any appointments yet."),
      findsOneWidget,
    );
    await tap(t, find.text('Schedule an Appointment'));
    expect(find.text('Demo Resident'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  }

  testWidgets(
    'an open appointment card updates at midnight and after its end time',
    (t) async {
      now = DateTime(2028, 5, 10, 23, 59, 50);
      final booking = await repo.book(tomorrow, 'dept-1', 660);
      await openMyAppointments(t);
      expect(find.text('Cancel Appointment'), findsOneWidget);
      now = tomorrow;
      await t.pump(const Duration(seconds: 10));
      await t.pumpAndSettle();
      expect(find.text('Cancel Appointment'), findsNothing);
      expect(find.text('Scheduled'), findsOneWidget);
      now = booking.end.add(const Duration(milliseconds: 1));
      await t.pump(now.difference(tomorrow));
      await t.pumpAndSettle();
      expect(find.text('Completed'), findsOneWidget);
    },
  );

  Future<void> pickDate(WidgetTester t, int day) async {
    await tap(t, find.byTooltip('Select Appointment Date'));
    final picker = t.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(picker.firstDate, today);
    await tap(
      t,
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('$day'),
      ),
    );
    await tap(t, find.text('OK'));
  }

  Future<void> department(WidgetTester t, String name) async {
    await tap(t, find.byType(DropdownButtonFormField<String>));
    await tap(t, find.text(name).last);
  }

  testWidgets(
    'keep, failed save, successful cancellation and a confirmation after midnight',
    (t) async {
      await repo.book(tomorrow, 'dept-1', 660);
      await repo.book(tomorrow, 'dept-2', 660);
      await openMyAppointments(t);
      final cancel = find.text('Cancel Appointment');
      final yes = find.text('Yes, Cancel Appointment');
      const success = 'Your appointment has been cancelled successfully.';
      await tap(t, cancel.first);
      expect(find.text('Cancel Appointment?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to cancel this appointment?'),
        findsOneWidget,
      );
      await tap(t, find.text('Keep Appointment'));
      expect(find.text('Scheduled'), findsNWidgets(2));
      await tap(t, cancel.first);
      fail = true;
      await tap(t, yes);
      expect(find.textContaining('could not be saved'), findsOneWidget);
      expect(find.text(success), findsNothing);
      expect(cancel, findsNWidgets(2));
      fail = false;
      await tap(t, cancel.first);
      await tap(t, yes);
      expect(find.text(success), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(cancel, findsOneWidget);
      await tap(t, cancel);
      now = tomorrow;
      await tap(t, yes);
      expect(find.textContaining('no longer eligible'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(cancel, findsNothing);
    },
  );

  testWidgets(
    'on Friday the calendar opens on Sunday and disables both weekend days',
    (t) async {
      now = DateTime(2028, 5, 12);
      await open(t);
      await tap(t, find.byTooltip('Select Appointment Date'));
      final dialog = find.byType(DatePickerDialog);
      final picker = t.widget<DatePickerDialog>(dialog);
      expect(picker.initialDate, DateTime(2028, 5, 14));
      for (final day in [12, 13]) {
        final cell = find.descendant(of: dialog, matching: find.text('$day'));
        expect(picker.selectableDayPredicate!(DateTime(2028, 5, day)), isFalse);
        await tap(t, cell);
      }
      await tap(t, find.text('OK'));
      final dateField = find.ancestor(
        of: find.byTooltip('Select Appointment Date'),
        matching: find.byType(TextField),
      );
      final locale = MaterialLocalizations.of(t.element(dateField));
      expect(
        t.widget<TextField>(dateField).controller!.text,
        locale.formatShortDate(DateTime(2028, 5, 14)),
      );
      await department(t, 'Department 1');
      await tap(t, find.byType(ChoiceChip).first);
      // Simulate a selection returned under an older working-day configuration.
      await tap(t, find.byTooltip('Select Appointment Date'));
      Navigator.of(t.element(dialog)).pop(DateTime(2028, 5, 12));
      await t.pumpAndSettle();
      expect(t.widget<TextField>(dateField).controller!.text, isEmpty);
      expect(find.byType(ChoiceChip), findsNothing);
      await tap(t, find.text('Confirm Appointment'));
      expect(find.text('Select your appointment date.'), findsOneWidget);
      expect(disk, isEmpty);
    },
  );

  testWidgets(
    'date and department reset selection, booked slots disable, confirmation saves once and returns home',
    (t) async {
      await open(t);
      await tap(t, find.text('Confirm Appointment'));
      expect(find.text('Select your appointment date.'), findsOneWidget);
      await pickDate(t, 10);
      await department(t, 'Department 1');
      expect(find.byType(ChoiceChip), findsNWidgets(8));
      final slotLabel = AppointmentConfig.range(660, 720);
      final chip = find.widgetWithText(ChoiceChip, slotLabel);
      await tap(t, chip);
      await department(t, 'Department 2');
      expect(t.widget<ChoiceChip>(chip).selected, isFalse);
      await tap(t, chip);
      await pickDate(t, 11);
      expect(t.widget<ChoiceChip>(chip).selected, isFalse);
      await tap(t, chip);
      fail = true;
      await tap(t, find.text('Confirm Appointment'));
      expect(find.textContaining('could not be saved'), findsOneWidget);
      expect(find.text('Appointment Confirmed!'), findsNothing);
      fail = false;
      // Another booking wins the slot after this screen has displayed it.
      await repo.book(tomorrow, 'dept-2', 660);
      await tap(t, chip);
      await tap(t, find.text('Confirm Appointment'));
      expect(t.widget<ChoiceChip>(chip).onSelected, isNull);
      expect(find.textContaining('just been booked'), findsOneWidget);
      await tap(
        t,
        find.widgetWithText(ChoiceChip, AppointmentConfig.range(720, 780)),
      );
      writing = Completer<void>();
      final confirm = find.text('Confirm Appointment');
      await t.ensureVisible(confirm);
      final at = t.getCenter(confirm);
      await t.tapAt(at);
      await t.tapAt(at);
      await t.pump();
      expect(find.text('Appointment Confirmed!'), findsNothing);
      writing!.complete();
      await t.pumpAndSettle();
      expect(disk, hasLength(2));
      expect(find.text('Appointment Confirmed!'), findsOneWidget);
      expect(
        find.text('Your appointment has been successfully scheduled.'),
        findsOneWidget,
      );
      await tap(t, find.text('OK'));
      expect(find.text('Welcome, Demo Resident'), findsOneWidget);
      await tap(t, find.text('My Appointments'));
      expect(find.text('Department 2'), findsNWidgets(2));
      expect(find.text('Upcoming appointments'), findsOneWidget);
    },
  );
}
