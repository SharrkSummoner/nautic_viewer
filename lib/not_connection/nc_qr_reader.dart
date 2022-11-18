import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nautic_viewer/data/api/zipobject_services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../internal/local_files.dart';
import '../presentation/documentfromscanner.dart';
import 'nc_document.dart';

class NoConnectionQrReader extends StatefulWidget {
  const NoConnectionQrReader({Key? key}) : super(key: key);

  @override
  State<NoConnectionQrReader> createState() => _NoConnectionQrReaderState();
}

class _NoConnectionQrReaderState extends State<NoConnectionQrReader> {
  Barcode? barcode;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  var qrViewOpened = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
  }

  // @override
  // void deactivate() {
  //   // TODO: implement deactivate
  //   super.deactivate();
  //   SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
  // }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        alignment: Alignment.center,
        children: <Widget>[
          buildQrView(context),
          Positioned(
            child: buildControlButtons(),
            bottom: 40,
          )
        ],
    );
  }

  Widget buildControlButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Color.fromARGB(255, 119, 134, 233),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          IconButton(
              onPressed: () async {
                await controller?.toggleFlash();
                setState(() {});
              },
              icon: FutureBuilder<bool?>(
                future: controller?.getFlashStatus(),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    return Icon(
                      snapshot.data! ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    );
                  } else {
                    return Container();
                  }
                },
              )),
          IconButton(
              onPressed: () async {
                await controller?.flipCamera();
                setState(() {});
              },
              icon: FutureBuilder(
                future: controller?.getCameraInfo(),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    return Icon(
                      Icons.cameraswitch_sharp,
                      color: Colors.white,
                    );
                  } else {
                    return Container();
                  }
                },
              )),
        ],
      ),
    );
  }

  Widget buildQrView(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Color.fromARGB(255, 119, 134, 233),
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 15,
        cutOutSize: MediaQuery.of(context).size.width * 0.7,
      ),
    );
  }

  Future<void> _onQRViewCreated(QRViewController controller) async {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((barcode) async {
      await controller.pauseCamera();
      if (await canLaunch(barcode.code.toString())) {
        await launch(barcode.code.toString());
        controller.resumeCamera();
      } else {
        setState(() async {
          this.barcode = barcode;
          if (validateUrl(barcode.code.toString())) {
            saveLastScanUrl(barcode.code.toString());
            Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (context) =>
                        NoConnectionDocument(url: barcode.code.toString())))
                .then((value) => controller.resumeCamera());
          } else {
            await _dialogBuilder(context);
            controller.resumeCamera();
          }
        });

        print(barcode.code);
      }
    });

    controller.stopCamera();
    controller.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text(
            'This QR code is not valid',
            style: TextStyle(fontSize: 18),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Ok', style: TextStyle(fontSize: 18)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
