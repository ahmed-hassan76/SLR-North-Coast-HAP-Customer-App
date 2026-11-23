import 'booking_status.dart';
import 'resident.dart';

typedef StayStatus = BookingStatus;

DateTime calendarDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

// UTC midnights give each calendar day equal length across daylight-saving changes.
int nightsBetween(DateTime arrival, DateTime departure) {
  DateTime dayNumber(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day);
  return dayNumber(departure).difference(dayNumber(arrival)).inDays;
}

class StayRequest {
  const StayRequest({
    required this.id,
    required this.resident,
    required this.parcel,
    required this.arrival,
    required this.departure,
    required this.submittedAt,
    this.cancelledAt,
  });

  final String id;
  final Resident resident;
  final int parcel;
  final DateTime arrival;
  final DateTime departure;
  final DateTime submittedAt;
  final DateTime? cancelledAt;

  int get nights => nightsBetween(arrival, departure);
  StayStatus statusOn(DateTime now) {
    if (cancelledAt != null) return StayStatus.cancelled;
    return calendarDay(now).isAfter(departure)
        ? StayStatus.completed
        : StayStatus.scheduled;
  }

  bool canCancelOn(DateTime now) =>
      cancelledAt == null && calendarDay(now).isBefore(arrival);

  Map<String, Object> toJson() => {
    'id': id,
    'residentId': resident.id,
    'customerName': resident.name,
    'phone': resident.phone,
    'parcel': parcel,
    'arrival': arrival.toIso8601String().split('T').first,
    'departure': departure.toIso8601String().split('T').first,
    'nights': nights,
    'submittedAt': submittedAt.toUtc().toIso8601String(),
    if (cancelledAt != null)
      'cancelledAt': cancelledAt!.toUtc().toIso8601String(),
  };

  factory StayRequest.fromJson(Map<String, dynamic> data) => StayRequest(
    id: data['id'] as String,
    resident: Resident(
      id: data['residentId'] as String,
      name: data['customerName'] as String,
      phone: data['phone'] as String,
    ),
    parcel: data['parcel'] as int,
    arrival: DateTime.parse(data['arrival'] as String),
    departure: DateTime.parse(data['departure'] as String),
    submittedAt: DateTime.parse(data['submittedAt'] as String),
    cancelledAt: data['cancelledAt'] == null
        ? null
        : DateTime.parse(data['cancelledAt'] as String),
  );
}
