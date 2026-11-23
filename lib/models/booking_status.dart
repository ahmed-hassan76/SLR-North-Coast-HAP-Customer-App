enum BookingStatus {
  scheduled('Scheduled'),
  completed('Completed'),
  cancelled('Cancelled');

  const BookingStatus(this.label);
  final String label;
}
