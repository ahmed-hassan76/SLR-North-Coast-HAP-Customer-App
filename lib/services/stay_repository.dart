import 'dart:convert';
import 'dart:math';

import '../models/resident.dart';
import '../models/stay_request.dart';
import 'mock_auth_service.dart';
import 'local_records_android.dart'
    if (dart.library.js_interop) 'local_records_web.dart'
    as storage;

class StayRepository {
  StayRepository(this.auth, {this.clock = DateTime.now});

  final MockAuthService auth;
  final DateTime Function() clock;
  static const parcelCount = 15;
  final _random = Random.secure();

  Resident get _resident =>
      auth.currentResident ??
      (throw StateError('Log in to access your stays.'));

  String _prefix(Resident resident) =>
      'hap.stays.v1/${Uri.encodeComponent(resident.id)}/';

  Future<StayRequest> schedule({
    required int parcel,
    required DateTime arrival,
    required DateTime departure,
  }) async {
    final resident = _resident;
    final now = clock();
    final start = calendarDay(arrival);
    final end = calendarDay(departure);
    if (parcel < 1 || parcel > parcelCount) {
      throw ArgumentError('Choose a parcel from 1 to 15.');
    }
    if (start.isBefore(calendarDay(now)) || !end.isAfter(start)) {
      throw ArgumentError(
        'Choose an arrival today or later and a later departure.',
      );
    }
    // Independent keys allow two tabs to add stays without replacing a shared list.
    final suffix = List.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final stay = StayRequest(
      id: 'ST-$suffix',
      resident: resident,
      parcel: parcel,
      arrival: start,
      departure: end,
      submittedAt: now.toUtc(),
    );
    await storage.writeRecord(
      '${_prefix(resident)}${stay.id}',
      jsonEncode(stay.toJson()),
    );
    return stay;
  }

  Future<void> cancel(String id) async {
    final resident = _resident;
    final key = '${_prefix(resident)}$id';
    final raw = await storage.readRecord(key);
    if (raw == null) throw StateError('This stay could not be found.');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final stay = StayRequest.fromJson(data);
    final now = clock();
    if (_resident.id != resident.id ||
        stay.resident.id != resident.id ||
        stay.id != id) {
      throw StateError('This stay does not belong to the signed-in resident.');
    }
    if (!stay.canCancelOn(now)) {
      throw StateError('This stay is no longer eligible for cancellation.');
    }
    data['cancelledAt'] = now.toUtc().toIso8601String();
    if (!await storage.compareAndSetRecord(key, raw, jsonEncode(data))) {
      throw StateError(
        'This stay has already changed. Review its current status.',
      );
    }
  }

  Future<List<StayRequest>> myStays() async {
    final resident = _resident;
    final records = await storage.readRecords(_prefix(resident));
    final stays = records
        .map(
          (raw) =>
              StayRequest.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        )
        .where((stay) => stay.resident.id == resident.id)
        .toList();
    final today = clock();
    stays.sort((a, b) {
      final aStatus = a.statusOn(today);
      final bStatus = b.statusOn(today);
      if (aStatus != bStatus) return aStatus.index.compareTo(bStatus.index);
      final order = switch (aStatus) {
        StayStatus.scheduled => a.arrival.compareTo(b.arrival),
        StayStatus.completed => b.departure.compareTo(a.departure),
        StayStatus.cancelled => b.cancelledAt!.compareTo(a.cancelledAt!),
      };
      return order != 0 ? order : a.id.compareTo(b.id);
    });
    return stays;
  }
}
