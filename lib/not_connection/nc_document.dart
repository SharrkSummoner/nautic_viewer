import 'package:flutter/material.dart';

import '../data/api/zipobject_services.dart';
import '../internal/scandata.dart';

class NoConnectionDocument extends StatefulWidget {
  NoConnectionDocument({Key? key, required this.url}) : super(key: key);

  String url;

  @override
  State<NoConnectionDocument> createState() => _NoConnectionDocumentState();
}

class _NoConnectionDocumentState extends State<NoConnectionDocument> {
  var data;
  var currentDocNumber;
  var currentSpool;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    data = getData(widget.url);
    currentDocNumber = data[0];
    currentSpool = data[1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Document"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text("Information from QR code", style: TextStyle(fontSize: 20)),
          ScanData(url: widget.url)
        ],
      ),
    );
  }
}
