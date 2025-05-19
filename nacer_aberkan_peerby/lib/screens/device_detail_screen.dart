import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;
  final String ownerId;
  final String name;
  final String description;
  final double price;
  final String category;
  final DateTime? startDate;
  final DateTime? endDate;

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.startDate,
    this.endDate,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _isSubmitting = false;
  Set<DateTime> _reservedDates = {};

  @override
  void initState() {
    super.initState();
    _loadReservedDates();
  }

  void _loadReservedDates() async {
    final reservations =
        await FirebaseFirestore.instance
            .collection('reservations')
            .where('deviceId', isEqualTo: widget.deviceId)
            .get();

    final reserved = <DateTime>{};
    for (var doc in reservations.docs) {
      final data = doc.data();
      final start = (data['startDate'] as Timestamp).toDate();
      final end = (data['endDate'] as Timestamp).toDate();
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        reserved.add(DateTime(d.year, d.month, d.day));
      }
    }

    setState(() {
      _reservedDates = reserved;
    });
  }

  bool _isDisabled(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    final inPeriod =
        widget.startDate != null &&
        widget.endDate != null &&
        !normalized.isBefore(widget.startDate!) &&
        !normalized.isAfter(widget.endDate!);
    return !inPeriod || _reservedDates.contains(normalized);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_isDisabled(selectedDay)) return;

    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        _rangeStart = selectedDay;
        _rangeEnd = null;
      } else if (_rangeStart != null && _rangeEnd == null) {
        if (selectedDay.isBefore(_rangeStart!)) {
          _rangeEnd = _rangeStart;
          _rangeStart = selectedDay;
        } else {
          _rangeEnd = selectedDay;
        }
      }
    });
  }

  Future<void> _reserveDevice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (user.uid == widget.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Je kan je eigen toestel niet reserveren.'),
        ),
      );
      return;
    }

    if (_rangeStart == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kies een periode.')));
      return;
    }

    final start = _rangeStart!;
    final end = _rangeEnd ?? _rangeStart!;

    if (start.isBefore(widget.startDate!) || end.isAfter(widget.endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periode buiten beschikbaarheid.')),
      );
      return;
    }

    for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      if (_reservedDates.contains(DateTime(d.year, d.month, d.day))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Geselecteerde periode bevat reeds gereserveerde dagen.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    await FirebaseFirestore.instance.collection('reservations').add({
      'deviceId': widget.deviceId,
      'ownerId': widget.ownerId,
      'renterId': user.uid,
      'startDate': start,
      'endDate': end,
      'createdAt': Timestamp.now(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reservering succesvol!')));

    setState(() {
      _isSubmitting = false;
      _rangeStart = null;
      _rangeEnd = null;
      _loadReservedDates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.description),
            const SizedBox(height: 8),
            Text('Categorie: ${widget.category}'),
            Text('Prijs: €${widget.price.toStringAsFixed(2)} per dag'),
            const SizedBox(height: 12),
            if (widget.startDate != null && widget.endDate != null)
              Text(
                'Beschikbaar van ${widget.startDate!.day}/${widget.startDate!.month} tot '
                '${widget.endDate!.day}/${widget.endDate!.month}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 20),
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _rangeStart ?? widget.startDate ?? DateTime.now(),
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Maand'},
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              selectedDayPredicate:
                  (day) =>
                      _rangeStart != null &&
                      (_rangeEnd ?? _rangeStart!).compareTo(day) >= 0 &&
                      day.compareTo(_rangeStart!) >= 0,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              onDaySelected: _onDaySelected,
              enabledDayPredicate: (day) => !_isDisabled(day),
              calendarStyle: CalendarStyle(
                isTodayHighlighted: true,
                rangeHighlightColor: Colors.green.withOpacity(0.4),
                rangeStartDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                disabledTextStyle: const TextStyle(
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough, // 🔥 Doorgestreept
                ),
                defaultTextStyle: const TextStyle(color: Colors.black),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final normalized = DateTime(day.year, day.month, day.day);

                  // Groene bolletjes voor beschikbare dagen
                  if (!_isDisabled(day)) {
                    return Container(
                      margin: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return null;
                },
              ),
            ),

            const SizedBox(height: 20),
            if (_rangeStart != null)
              Text(
                'Gekozen: ${_rangeStart!.day}/${_rangeStart!.month} '
                '${_rangeEnd != null ? ' - ${_rangeEnd!.day}/${_rangeEnd!.month}' : ''}',
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _reserveDevice,
              child:
                  _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Reserveer'),
            ),
          ],
        ),
      ),
    );
  }
}
