import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'destination.dart';

class DestinationView extends StatefulWidget {
  const DestinationView({ Key key, this.destination }) : super(key: key);

  final Destination destination;

  @override
  _DestinationViewState createState() => _DestinationViewState();
}


class _DestinationViewState extends State<DestinationView> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
      ),
      body: widget.destination.page, // TextField(controller: _textController)
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}