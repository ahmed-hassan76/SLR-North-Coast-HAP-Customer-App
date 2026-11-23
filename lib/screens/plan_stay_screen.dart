import '../widgets/portal_date_field.dart';
import '../widgets/resident_information.dart';

import 'package:material_ui/material_ui.dart';

import '../models/resident.dart';
import '../models/stay_request.dart';
import '../services/stay_repository.dart';
import '../theme/portal_theme.dart';
import '../widgets/portal_layout.dart';

class PlanStayScreen extends StatefulWidget {
  const PlanStayScreen({
    super.key,
    required this.resident,
    required this.repository,
  });
  final Resident resident;
  final StayRepository repository;

  @override
  State<PlanStayScreen> createState() => _PlanStayScreenState();
}

class _PlanStayScreenState extends State<PlanStayScreen> {
  final _form = GlobalKey<FormState>();
  int? _parcel;
  DateTime? _arrival;
  DateTime? _departure;
  bool _saving = false;
  String? _error;

  DateTime get _today => calendarDay(widget.repository.clock());

  Future<void> _pickDate({required bool arrival}) async {
    final today = _today;
    final earliestArrival = _arrival != null && _arrival!.isAfter(today)
        ? _arrival!
        : today;
    final first = arrival
        ? today
        : DateTime(
            earliestArrival.year,
            earliestArrival.month,
            earliestArrival.day + 1,
          );
    final previous = arrival ? _arrival : _departure;
    final picked = await showDatePicker(
      context: context,
      firstDate: first,
      currentDate: today,
      lastDate: DateTime(9999, 12, arrival ? 30 : 31),
      initialDate: previous == null || previous.isBefore(first)
          ? first
          : previous,
      helpText: arrival ? 'Select arrival date' : 'Select departure date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _error = null;
      if (arrival) {
        _arrival = picked;
        if (_departure != null && !_departure!.isAfter(picked)) {
          _departure = null;
        }
      } else {
        _departure = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.schedule(
        parcel: _parcel!,
        arrival: _arrival!,
        departure: _departure!,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'Your stay could not be saved. Check your dates and try again.';
        });
      }
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          scrollable: true,
          icon: const Icon(
            Icons.event_available_outlined,
            color: sea,
            size: 34,
          ),
          title: const Text('Request Submitted!'),
          content: const Text('Services Scheduled for Activation.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final nights = _arrival != null && _departure != null
        ? nightsBetween(_arrival!, _departure!)
        : null;
    return PopScope(
      canPop: !_saving,
      child: PortalScaffold(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeading(
                'Plan Your Stay',
                "Tell us when you're coming, and we'll get your neighborhood ready.",
              ),
              const SizedBox(height: 24),
              ResidentInformation(widget.resident),
              const SizedBox(height: 16),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Your Parcel',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      items: [
                        for (var i = 1; i <= StayRepository.parcelCount; i++)
                          DropdownMenuItem(value: i, child: Text('Parcel $i')),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _parcel = value),
                      validator: (value) =>
                          value == null ? 'Select your parcel.' : null,
                    ),
                    const SizedBox(height: 26),
                    Text('When Will You Be Visiting?', style: heading(24)),
                    const SizedBox(height: 18),
                    PortalDateField(
                      label: 'Arrival Date',
                      value: _arrival,
                      onTap: _saving ? null : () => _pickDate(arrival: true),
                      validator: (_) {
                        if (_arrival == null) {
                          return 'Select your arrival date.';
                        }
                        return _arrival!.isBefore(_today)
                            ? 'Choose today or a later date.'
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    PortalDateField(
                      label: 'Departure Date',
                      value: _departure,
                      onTap: _saving ? null : () => _pickDate(arrival: false),
                      validator: (_) {
                        if (_departure == null) {
                          return 'Select your departure date.';
                        }
                        return _arrival != null &&
                                !_departure!.isAfter(_arrival!)
                            ? 'Choose a date after arrival.'
                            : null;
                      },
                    ),
                    if (nights != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Stay Duration: $nights ${nights == 1 ? 'Night' : 'Nights'}',
                          style: const TextStyle(
                            color: sea,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                      onPressed: _saving ? null : _submit,
                      child: Text(_saving ? 'Saving…' : 'Confirm My Stay'),
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
