import '../config/appointment_config.dart';
import 'booking_status.dart';
import 'resident.dart';
import 'stay_request.dart' show calendarDay;

class Appointment {
  const Appointment({
    required this.id,
    required this.resident,
    required this.department,
    required this.date,
    required this.startMinute,
    required this.endMinute,
    required this.bookedAt,
    this.cancelledAt,
  });
  final String id;
  final Resident resident;
  final Department department;
  final DateTime date;
  final int startMinute;
  final int endMinute;
  final DateTime bookedAt;
  final DateTime? cancelledAt;

  DateTime get start =>
      DateTime(date.year, date.month, date.day, 0, startMinute);
  DateTime get end => DateTime(date.year, date.month, date.day, 0, endMinute);
  BookingStatus statusOn(DateTime now) {
    if (cancelledAt != null) return BookingStatus.cancelled;
    return now.isAfter(end) ? BookingStatus.completed : BookingStatus.scheduled;
  }

  bool canCancelOn(DateTime now) =>
      statusOn(now) == BookingStatus.scheduled &&
      calendarDay(now).isBefore(date);

  String get timeSlot => AppointmentConfig.range(startMinute, endMinute);
  Map<String, Object> toJson() => {
    'id': id,
    'residentId': resident.id,
    'customerName': resident.name,
    'phone': resident.phone,
    'departmentId': department.id,
    'departmentName': department.name,
    'date': date.toIso8601String().split('T').first,
    'startMinute': startMinute,
    'endMinute': endMinute,
    'bookedAt': bookedAt.toUtc().toIso8601String(),
    if (cancelledAt != null)
      'cancelledAt': cancelledAt!.toUtc().toIso8601String(),
  };
  factory Appointment.fromJson(Map<String, dynamic> data) => Appointment(
    id: data['id'] as String,
    resident: Resident(
      id: data['residentId'] as String,
      name: data['customerName'] as String,
      phone: data['phone'] as String,
    ),
    department: Department(
      data['departmentId'] as String,
      data['departmentName'] as String,
    ),
    date: DateTime.parse(data['date'] as String),
    startMinute: data['startMinute'] as int,
    endMinute: data['endMinute'] as int,
    bookedAt: DateTime.parse(data['bookedAt'] as String),
    cancelledAt: data['cancelledAt'] == null
        ? null
        : DateTime.parse(data['cancelledAt'] as String),
  );
}
