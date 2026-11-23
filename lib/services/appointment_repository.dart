import 'dart:convert';

import '../config/appointment_config.dart';
import '../models/appointment.dart';
import '../models/booking_status.dart';
import '../models/resident.dart';
import '../models/stay_request.dart' show calendarDay;
import 'local_records_android.dart'
    if (dart.library.js_interop) 'local_records_web.dart'
    as storage;
import 'mock_auth_service.dart';

enum SlotStatus { available, booked, elapsed }

class AppointmentRepository {
  AppointmentRepository(this.auth, {this.clock = DateTime.now});
  final MockAuthService auth;
  final DateTime Function() clock;
  static const _prefix = 'hap.appointments.v1/';

  Resident get _resident =>
      auth.currentResident ??
      (throw StateError('Please log in to book an appointment.'));
  String _dayKey(DateTime date) =>
      calendarDay(date).toIso8601String().split('T').first;
  String _slotsKey(DateTime date, String departmentId) =>
      '$_prefix${_dayKey(date)}/${Uri.encodeComponent(departmentId)}/';

  // Older slots held one booking. Later reservations append to that slot's history.
  List<Map<String, dynamic>> _history(String raw) {
    final data = jsonDecode(raw);
    return data is List
        ? data.cast<Map<String, dynamic>>()
        : [data as Map<String, dynamic>];
  }

  Future<Map<int, SlotStatus>> slots(DateTime date, String departmentId) async {
    if (auth.currentResident == null) {
      throw StateError('Please log in to view appointments.');
    }
    final records = await storage.readRecords(_slotsKey(date, departmentId));
    final booked = records
        .map((raw) => _history(raw).last)
        .where((latest) => latest['cancelledAt'] == null)
        .map((latest) => latest['startMinute'] as int)
        .toSet();
    final now = clock();
    final slots = <int, SlotStatus>{};
    for (final minute in AppointmentConfig.startMinutes) {
      final start = DateTime(date.year, date.month, date.day, 0, minute);
      if (booked.contains(minute)) {
        slots[minute] = SlotStatus.booked;
      } else if (!AppointmentConfig.isWorkingDay(date) || !start.isAfter(now)) {
        slots[minute] = SlotStatus.elapsed;
      } else {
        slots[minute] = SlotStatus.available;
      }
    }
    return slots;
  }

  Future<Appointment> book(
    DateTime date,
    String departmentId,
    int startMinute,
  ) async {
    final resident = _resident;
    final day = calendarDay(date);
    final key = '${_slotsKey(day, departmentId)}$startMinute';
    final raw = await storage.readRecord(key);
    final history = raw == null ? <Map<String, dynamic>>[] : _history(raw);
    if (_resident.id != resident.id) throw StateError('Please sign in again.');
    final now = clock();
    if (day.isBefore(calendarDay(now)) ||
        !AppointmentConfig.isWorkingDay(day)) {
      throw StateError('Choose an available appointment date.');
    }
    final department = AppointmentConfig.departments
        .where((d) => d.id == departmentId)
        .firstOrNull;
    if (department == null) throw StateError('Choose a department.');
    final start = DateTime(day.year, day.month, day.day, 0, startMinute);
    if (!AppointmentConfig.startMinutes.contains(startMinute) ||
        !start.isAfter(now)) {
      throw StateError('Choose a time slot that has not started.');
    }
    if (history.isNotEmpty && history.last['cancelledAt'] == null) {
      throw StateError('This slot has just been booked. Choose another time.');
    }
    final slotId = 'APT-${_dayKey(day)}-${department.id}-$startMinute';
    final appointment = Appointment(
      id: history.isEmpty ? slotId : '$slotId-${history.length + 1}',
      resident: resident,
      department: department,
      date: day,
      startMinute: startMinute,
      endMinute: startMinute + AppointmentConfig.slotMinutes,
      bookedAt: now.toUtc(),
    );
    if (!await storage.compareAndSetRecord(
      key,
      raw,
      jsonEncode([...history, appointment.toJson()]),
    )) {
      throw StateError('This slot has just been booked. Choose another time.');
    }
    return appointment;
  }

  Future<void> cancel(Appointment selected) async {
    final resident = _resident;
    final key =
        '${_slotsKey(selected.date, selected.department.id)}${selected.startMinute}';
    final raw = await storage.readRecord(key);
    if (raw == null) throw StateError('This appointment could not be found.');
    final history = _history(raw);
    final latest = Appointment.fromJson(history.last);
    final now = clock();
    if (_resident.id != resident.id ||
        latest.resident.id != resident.id ||
        latest.id != selected.id ||
        !latest.canCancelOn(now)) {
      throw StateError(
        'This appointment is no longer eligible for cancellation.',
      );
    }
    history.last['cancelledAt'] = now.toUtc().toIso8601String();
    if (!await storage.compareAndSetRecord(key, raw, jsonEncode(history))) {
      throw StateError(
        'This appointment has already changed. Review its current status.',
      );
    }
  }

  Future<List<Appointment>> myAppointments() async {
    final resident = _resident;
    final raw = await storage.readRecords(_prefix);
    final bookings = raw
        .expand(_history)
        .map(Appointment.fromJson)
        .where((a) => a.resident.id == resident.id)
        .toList();
    final now = clock();
    bookings.sort((a, b) {
      final status = a.statusOn(now);
      final group = status.index.compareTo(b.statusOn(now).index);
      if (group != 0) return group;
      final order = switch (status) {
        BookingStatus.scheduled => a.start.compareTo(b.start),
        BookingStatus.completed => b.end.compareTo(a.end),
        BookingStatus.cancelled => b.cancelledAt!.compareTo(a.cancelledAt!),
      };
      return order != 0 ? order : a.id.compareTo(b.id);
    });
    return bookings;
  }
}
