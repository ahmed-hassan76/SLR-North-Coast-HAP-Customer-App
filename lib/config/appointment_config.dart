class Department {
  const Department(this.id, this.name);
  final String id;
  final String name;
}

abstract final class AppointmentConfig {
  static const departments = [
    Department('dept-1', 'Department 1'),
    Department('dept-2', 'Department 2'),
    Department('dept-3', 'Department 3'),
    Department('dept-4', 'Department 4'),
    Department('dept-5', 'Department 5'),
  ];
  static const workingDays = {
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
  };
  static const openingHour = 9;
  static const closingHour = 17;
  static const slotMinutes = 60;

  static bool isWorkingDay(DateTime date) => workingDays.contains(date.weekday);
  static List<int> get startMinutes => [
    for (
      int minute = openingHour * 60;
      minute + slotMinutes <= closingHour * 60;
      minute += slotMinutes
    )
      minute,
  ];
  static String get hours =>
      '${formatTime(openingHour * 60)} to ${formatTime(closingHour * 60)}';
  static String get duration =>
      slotMinutes == 60 ? 'one hour' : '$slotMinutes minutes';

  static String formatTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '${hour % 12 == 0 ? 12 : hour % 12}:$minute ${hour < 12 ? 'AM' : 'PM'}';
  }

  static String range(int start, int end) =>
      '${formatTime(start)} – ${formatTime(end)}';
}
