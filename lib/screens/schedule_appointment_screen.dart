import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../config/app_feature_registry.dart';
import '../config/appointment_config.dart';
import '../models/appointment.dart';
import '../models/resident.dart';
import '../models/stay_request.dart' show calendarDay;
import '../services/appointment_repository.dart';
import '../theme/portal_theme.dart';
import '../widgets/portal_date_field.dart';
import '../widgets/portal_layout.dart';
import '../widgets/resident_information.dart';

class ScheduleAppointmentScreen extends StatefulWidget {
  const ScheduleAppointmentScreen({
    super.key,
    required this.resident,
    required this.repository,
  });
  final Resident resident;
  final AppointmentRepository repository;

  @override
  State<ScheduleAppointmentScreen> createState() =>
      _ScheduleAppointmentScreenState();
}

class _ScheduleAppointmentScreenState extends State<ScheduleAppointmentScreen> {
  final _form = GlobalKey<FormState>();
  DateTime? _date;
  String? _department;
  int? _minute;
  Future<Map<int, SlotStatus>>? _slots;
  Timer? _slotTimer;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _slotTimer?.cancel();
    super.dispose();
  }

  void _loadSlots() {
    _slotTimer?.cancel();
    if (_date != null && !AppointmentConfig.isWorkingDay(_date!)) {
      _date = null;
      _minute = null;
    }
    final date = _date;
    final department = _department;
    if (date == null || department == null) {
      _slots = null;
      return;
    }
    _slots = widget.repository.slots(date, department);
    // Update a form left open when the next slot starts.
    final now = widget.repository.clock();
    final next = AppointmentConfig.startMinutes
        .map((m) => DateTime(date.year, date.month, date.day, 0, m))
        .where((start) => start.isAfter(now))
        .firstOrNull;
    if (next != null) {
      final midnight = DateTime(now.year, now.month, now.day + 1);
      final refreshAt = next.isBefore(midnight) ? next : midnight;
      _slotTimer = Timer(refreshAt.difference(now), () {
        if (!mounted || _saving) return;
        setState(() {
          final minute = _minute;
          if (minute != null &&
              !DateTime(
                date.year,
                date.month,
                date.day,
                0,
                minute,
              ).isAfter(widget.repository.clock())) {
            _minute = null;
          }
          _loadSlots();
        });
      });
    }
  }

  Future<void> _pickDate() async {
    _clearClosedDate();
    final today = calendarDay(widget.repository.clock());
    var initial = _date != null && !_date!.isBefore(today) ? _date! : today;
    if (AppointmentConfig.workingDays.isEmpty) {
      setState(() => _error = 'There are no appointment dates available.');
      return;
    }
    while (!AppointmentConfig.isWorkingDay(initial)) {
      initial = DateTime(initial.year, initial.month, initial.day + 1);
    }
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      currentDate: today,
      initialDate: initial,
      lastDate: DateTime(9999, 12, 31),
      selectableDayPredicate: AppointmentConfig.isWorkingDay,
      helpText: 'Select appointment date',
    );
    if (!mounted || picked == null || picked == _date) return;
    setState(() {
      _date = picked;
      _minute = null;
      _error = null;
      _loadSlots();
    });
  }

  Future<void> _confirm() async {
    _clearClosedDate();
    if (_saving || !_form.currentState!.validate()) return;
    final minute = _minute;
    if (minute == null) {
      setState(() => _error = 'Choose an available time slot.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    late final Appointment booking;
    try {
      booking = await widget.repository.book(_date!, _department!, minute);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _minute = null;
          _error = error is StateError
              ? error.message
              : 'Your appointment could not be saved. Please try again.';
          _loadSlots();
        });
      }
      return;
    }
    if (!mounted) return;
    final formattedDate = MaterialLocalizations.of(context)
        .formatShortDate(booking.date);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => PopScope(
        canPop: false,
        child: AlertDialog(
          scrollable: true,
          icon: const Icon(Icons.event_available_outlined, color: sea),
          title: const Text('Appointment Confirmed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your appointment has been successfully scheduled.'),
              const SizedBox(height: 16),
              Text(booking.department.name),
              Text(formattedDate),
              Text(booking.timeSlot),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  void reassemble() {
    super.reassemble();
    _clearClosedDate();
  }

  // A form may still be open when the configured working days change.
  void _clearClosedDate() {
    if (_date != null && !AppointmentConfig.isWorkingDay(_date!)) {
      setState(_loadSlots);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: PortalScaffold(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeading(
                appointmentFeature.name,
                'Choose a date and reserve a time with the department you need.',
              ),
              const SizedBox(height: 24),
              ResidentInformation(
                widget.resident,
                title: 'Customer Information',
              ),
              const SizedBox(height: 16),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PortalDateField(
                      label: 'Appointment Date',
                      value: _date,
                      onTap: _saving ? null : _pickDate,
                      validator: (_) => _date == null
                          ? 'Select your appointment date.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      items: [
                        for (final d in AppointmentConfig.departments)
                          DropdownMenuItem(value: d.id, child: Text(d.name)),
                      ],
                      validator: (id) =>
                          id == null ? 'Select a department.' : null,
                      onChanged: _date == null || _saving
                          ? null
                          : (id) => setState(() {
                              _department = id;
                              _minute = null;
                              _error = null;
                              _loadSlots();
                            }),
                    ),
                    if (_slots != null) ...[
                      const SizedBox(height: 24),
                      Text('Appointment slots', style: heading(24)),
                      const SizedBox(height: 12),
                      FutureBuilder<Map<int, SlotStatus>>(
                        future: _slots,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const LinearProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Column(
                              children: [
                                const Text(
                                  'Available slots could not be loaded.',
                                ),
                                TextButton(
                                  onPressed: () => setState(_loadSlots),
                                  child: const Text('Try again'),
                                ),
                              ],
                            );
                          }
                          final slots = snapshot.requireData;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!slots.containsValue(SlotStatus.available))
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'No slots are available for this date and department.',
                                  ),
                                ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final entry in slots.entries)
                                    ChoiceChip(
                                      label: Text(
                                        AppointmentConfig.range(
                                          entry.key,
                                          entry.key +
                                              AppointmentConfig.slotMinutes,
                                        ),
                                      ),
                                      selected:
                                          _minute == entry.key &&
                                          entry.value == SlotStatus.available,
                                      selectedColor: mist,
                                      checkmarkColor: sea,
                                      tooltip: switch (entry.value) {
                                        SlotStatus.booked => 'Already booked',
                                        SlotStatus.elapsed => 'Unavailable',
                                        SlotStatus.available => 'Available',
                                      },
                                      onSelected:
                                          entry.value != SlotStatus.available ||
                                              _saving
                                          ? null
                                          : (_) => setState(() {
                                              _minute = entry.key;
                                              _error = null;
                                            }),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _confirm,
                      child: Text(_saving ? 'Saving…' : 'Confirm Appointment'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
