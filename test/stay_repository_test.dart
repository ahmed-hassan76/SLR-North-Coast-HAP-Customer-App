import 'dart:convert';

import 'package:customer_app/models/resident.dart';
import 'package:customer_app/models/stay_request.dart';
import 'package:customer_app/services/mock_auth_service.dart';
import 'package:customer_app/services/stay_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _ResidentSession extends MockAuthService {
  @override
  Resident? currentResident = MockAuthService.demoResident;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('hap/stay_storage');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, String> disk;
  late DateTime now;
  late _ResidentSession auth;
  late StayRepository repository;
  DateTime day(int day) => DateTime(2028, 4, day);

  setUp(() {
    disk = {};
    now = day(1);
    auth = _ResidentSession();
    repository = StayRepository(auth, clock: () => now);
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'get') return disk[call.arguments as String];
      if (call.method == 'replace') {
        final key = call.arguments['key'] as String;
        if (disk[key] != call.arguments['expected']) return false;
        disk[key] = call.arguments['value'] as String;
        return true;
      }
      if (call.method == 'save') {
        disk[call.arguments['key']] = call.arguments['value'];
        return null;
      }
      return [
        for (final entry in disk.entries)
          if (entry.key.startsWith(call.arguments as String)) entry.value,
      ];
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    auth.dispose();
  });

  test('rejects invalid dates, out-of-range parcels and unauthenticated access before writing', () async {
    for (final parcel in [0, 16]) {
      await expectLater(
        repository.schedule(parcel: parcel, arrival: day(1), departure: day(2)),
        throwsArgumentError,
      );
    }
    for (final (arrival, departure) in [(0, 2), (2, 2), (3, 2)]) {
      await expectLater(
        repository.schedule(
          parcel: 1,
          arrival: day(arrival),
          departure: day(departure),
        ),
        throwsArgumentError,
      );
    }
    auth.currentResident = null;
    await expectLater(
      repository.schedule(parcel: 1, arrival: day(1), departure: day(2)),
      throwsStateError,
    );
    await expectLater(repository.myStays(), throwsStateError);
    expect(disk, isEmpty);
  });

  test('multiple concurrent requests survive reopening with distinct IDs and complete resident details', () async {
    now = DateTime(2028, 4, 1, 23, 59);
    final saved = await Future.wait([
      for (var i = 0; i < 3; i++)
        repository.schedule(parcel: 15, arrival: day(1), departure: day(6)),
    ]);
    final ids = saved.map((stay) => stay.id).toSet();
    expect(ids, hasLength(3));
    expect(
      disk.values.map((raw) => jsonDecode(raw)['nights']),
      everyElement(5),
    );
    // Start a new repository and session; the only shared state is the platform storage.
    final newAuth = MockAuthService()..login('01000000000', 'Demo1234');
    addTearDown(newAuth.dispose);
    final reloaded = await StayRepository(newAuth, clock: () => now).myStays();
    expect(reloaded.map((stay) => stay.id).toSet(), ids);
    for (final stay in reloaded) {
      expect(stay.resident.id, 'RES001');
      expect(stay.resident.name, 'Demo Resident');
      expect(stay.resident.phone, '01000000000');
      expect(stay.parcel, 15);
      expect(stay.arrival, day(1));
      expect(stay.departure, day(6));
      expect(stay.nights, 5);
      expect(stay.submittedAt, now.toUtc());
      expect(stay.statusOn(now), StayStatus.scheduled);
    }
  });

  test('the current resident sees only their own requests', () async {
    final original = await repository.schedule(
      parcel: 1,
      arrival: day(1),
      departure: day(2),
    );
    auth.currentResident = const Resident(
      id: 'RES002',
      name: 'Second Resident',
      phone: '01000000001',
    );
    expect(await repository.myStays(), isEmpty);
    final other = await repository.schedule(
      parcel: 2,
      arrival: day(1),
      departure: day(2),
    );
    expect((await repository.myStays()).single.id, other.id);
    auth.currentResident = MockAuthService.demoResident;
    expect((await repository.myStays()).single.id, original.id);
  });

  test('departures remain scheduled all day; retrieval sorts using the current calendar date', () async {
    for (final (parcel, arrival, departure) in [
      (1, 4, 10),
      (2, 2, 8),
      (3, 12, 20),
      (4, 10, 15),
    ]) {
      await repository.schedule(
        parcel: parcel,
        arrival: day(arrival),
        departure: day(departure),
      );
    }
    now = DateTime(2028, 4, 10, 23, 59, 59);
    var stays = await repository.myStays();
    expect(stays.map((s) => s.parcel), [1, 4, 3, 2]);
    expect(stays.first.statusOn(now), StayStatus.scheduled);
    now = day(11);
    stays = await repository.myStays();
    expect(stays.map((s) => s.parcel), [4, 3, 1, 2]);
    expect(stays[2].statusOn(now), StayStatus.completed);
  });

  test('duration counts calendar nights across month, year and leap-day boundaries', () {
    expect(
      nightsBetween(DateTime(2028, 2, 28, 23), DateTime(2028, 3, 1, 1)),
      2,
    );
    expect(nightsBetween(DateTime(2028, 12, 31), DateTime(2029, 1, 1)), 1);
  });

  test('legacy stays cancel in place once and remain cancelled after reloading past departure', () async {
    final stay = await repository.schedule(
      parcel: 2,
      arrival: day(3),
      departure: day(6),
    );
    final other = await repository.schedule(
      parcel: 3,
      arrival: day(4),
      departure: day(7),
    );
    expect(jsonDecode(disk.values.first).containsKey('cancelledAt'), isFalse);
    now = DateTime(2028, 4, 2, 23, 59);
    await repository.cancel(stay.id);
    final saved = Map.of(disk);
    await expectLater(repository.cancel(stay.id), throwsStateError);
    expect(disk, saved);
    now = day(20);
    final loaded = await StayRepository(auth, clock: () => now).myStays();
    expect(loaded.map((s) => s.id), [other.id, stay.id]);
    expect(loaded.first.statusOn(now), StayStatus.completed);
    final cancelled = loaded.last;
    expect(cancelled.statusOn(now), StayStatus.cancelled);
    expect(cancelled.cancelledAt, DateTime(2028, 4, 2, 23, 59).toUtc());
    expect(cancelled.arrival, stay.arrival);
    expect(cancelled.nights, stay.nights);
    expect(cancelled.resident.id, stay.resident.id);
  });

  test(
    'cancellation is blocked on arrival, during the stay, and after completion',
    () async {
      final stay = await repository.schedule(
        parcel: 1,
        arrival: day(2),
        departure: day(5),
      );
      final saved = Map.of(disk);
      for (final date in [day(2), day(3), day(5), day(6)]) {
        now = date;
        expect(stay.canCancelOn(now), isFalse);
        await expectLater(repository.cancel(stay.id), throwsStateError);
      }
      expect(disk, saved);
    },
  );

  test('resident ownership and concurrent cancellations are checked against storage', () async {
    final stay = await repository.schedule(
      parcel: 1,
      arrival: day(2),
      departure: day(5),
    );
    auth.currentResident = const Resident(
      id: 'RES002',
      name: 'Second Resident',
      phone: '',
    );
    await expectLater(repository.cancel(stay.id), throwsStateError);
    auth.currentResident = null;
    await expectLater(repository.cancel(stay.id), throwsStateError);
    auth.currentResident = MockAuthService.demoResident;
    Future<bool> attempt() async {
      try {
        await repository.cancel(stay.id);
        return true;
      } on StateError {
        return false;
      }
    }

    expect(
      await Future.wait([attempt(), attempt()]),
      unorderedEquals([true, false]),
    );
  });

  test(
    'list groups scheduled, completed, then most recently cancelled',
    () async {
      final stays = [
        for (final i in [1, 2, 3, 4])
          await repository.schedule(
            parcel: i,
            arrival: day(i == 1 ? 2 : 10),
            departure: day(i == 1 ? 3 : 12),
          ),
      ];
      await repository.cancel(stays[1].id);
      now = day(2);
      await repository.cancel(stays[3].id);
      now = day(5);
      expect((await repository.myStays()).map((s) => s.parcel), [3, 1, 4, 2]);
    },
  );
}
