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
  DateTime? _userReservationStart;
  DateTime? _userReservationEnd;

  @override
  void initState() {
    super.initState();
    _loadReservedDates();
    _loadUserReservation();
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

  void _loadUserReservation() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('reservations')
            .where('deviceId', isEqualTo: widget.deviceId)
            .where('renterId', isEqualTo: userId)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      setState(() {
        _userReservationStart = (data['startDate'] as Timestamp).toDate();
        _userReservationEnd = (data['endDate'] as Timestamp).toDate();
      });
    }
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

    if (_userReservationStart != null && _userReservationEnd != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Je hebt dit toestel reeds gereserveerd.'),
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
      _loadUserReservation();
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
            if (_userReservationStart != null && _userReservationEnd != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '⚠️ Je hebt dit toestel reeds gereserveerd van '
                  '${_userReservationStart!.day}/${_userReservationStart!.month} '
                  'tot ${_userReservationEnd!.day}/${_userReservationEnd!.month}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            TableCalendar(
  firstDay: DateTime(2020),
  lastDay: DateTime(2030),
  focusedDay: _rangeStart ?? widget.startDate ?? DateTime.now(),
  availableCalendarFormats: const {CalendarFormat.month: 'Maand'},
  calendarFormat: CalendarFormat.month,
  rangeSelectionMode: RangeSelectionMode.enforced,
  rangeStartDay: _rangeStart,
  rangeEndDay: _rangeEnd,
  onDaySelected: _onDaySelected,
  enabledDayPredicate: (day) => !_isDisabled(day),
  calendarStyle: CalendarStyle(
    isTodayHighlighted: true,
    rangeHighlightColor: Colors.green.withOpacity(0.4),
    rangeStartDecoration: const BoxDecoration(
      color: Colors.green,
      shape: BoxShape.circle,
    ),
    rangeEndDecoration: const BoxDecoration(
      color: Colors.green,
      shape: BoxShape.circle,
    ),
    todayDecoration: BoxDecoration(
      color: Colors.grey.shade300,
      shape: BoxShape.circle,
    ),
    disabledTextStyle: const TextStyle(
      color: Colors.grey,
      decoration: TextDecoration.lineThrough,
    ),
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
