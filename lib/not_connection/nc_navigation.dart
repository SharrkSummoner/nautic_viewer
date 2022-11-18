import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import 'nc_home.dart';
import 'nc_qr_reader.dart';

class NoConnectionNavigation extends StatefulWidget {
  const NoConnectionNavigation({Key? key}) : super(key: key);

  @override
  State<NoConnectionNavigation> createState() => _NoConnectionNavigationState();
}

class _NoConnectionNavigationState extends State<NoConnectionNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  var titleAppBar = Text("Nautic 3D");
  var _currentIndex = 0;
  List indexes = [];
  late TabController _tabController;

  final _kTabPages = <Widget>[
    NoConnectionHome(),
    NoConnectionQrReader(),
  ];

  final _kBottomNavBarItems = <SalomonBottomBarItem>[
    SalomonBottomBarItem(
        icon: Icon(Icons.home),
        title: Text("Home"),
        selectedColor: Color.fromARGB(255, 119, 134, 233)),
    SalomonBottomBarItem(
        icon: Icon(Icons.qr_code_scanner),
        title: Text("QR scanner"),
        selectedColor: Color.fromARGB(255, 119, 134, 233))
  ];

  @override
  Widget build(BuildContext context) {
    final bottomNavBar = SalomonBottomBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() {
        indexes.add(_currentIndex);
        _currentIndex = index;
      }),
      items: _kBottomNavBarItems,
    );

    return WillPopScope(
        child: Scaffold(
          key: _scaffoldKey,
          body: _kTabPages[_currentIndex],
          bottomNavigationBar: bottomNavBar,
        ),
        onWillPop: () async {
          setState(() {
            if (indexes.length > 0) {
              setState(() {
                _currentIndex = indexes[indexes.length - 1];
                indexes.removeLast();
              });
            } else {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            }
          });
          return false;
        });
  }
}
