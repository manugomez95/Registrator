import 'package:flutter/material.dart';

class DatePicker extends StatefulWidget {
  DatePicker({Key key, this.showDate = true, this.showTime = false }) : super(key: key);

  final bool showDate;
  final bool showTime;

  @override
  _DatePickerState createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  Future<Null> _selectedDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2019),
        lastDate: DateTime(2021));

    if (picked != null && picked != _date) {
      print("Date selected: ${picked.toString()}");
      setState(() {
        _date = picked;
      });
    }
  }

  Future<Null> _selectedTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(context: context, initialTime: _time);

    if (picked != null && picked != _time) {
      print("Time selected: ${picked.toString()}");
      setState(() {
        _time = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      child: Text((widget.showDate ? "${_date.day}/${_date.month}/${_date.year} " : "") + (widget.showTime ? "${_time.hour}:${_time.minute}" : "")),
      onPressed: () {
        if (widget.showTime && !widget.showDate) _selectedTime(context);
        else if (widget.showDate) _selectedDate(context).then((nothing) {
          if (widget.showTime) _selectedTime(context);
        });
        },
    );
  }
}
