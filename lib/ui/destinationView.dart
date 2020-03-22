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
  // TextEditingController _textController; // To test state persistence

  @override
  void initState() {
    super.initState();
    /*_textController = TextEditingController(
      text: 'sample text: ${widget.destination.title}',
    );*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        /*actions: <Widget>[IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () {},)]*/ // TODO onPressed function passed as parameter
      ),
      body: widget.destination.page, // TextField(controller: _textController)
    );
  }

  @override
  void dispose() {
    // _textController.dispose();
    super.dispose();
  }
}