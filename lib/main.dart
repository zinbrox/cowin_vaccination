import 'dart:isolate';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:cowin_vaccination/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

main() async {
  //WidgetsFlutterBinding.ensureInitialized();
  //final int helloAlarmID = 0;
  //await AndroidAlarmManager.initialize();
  runApp(MyApp());
  //await AndroidAlarmManager.periodic(const Duration(minutes: 1), helloAlarmID, printHello);
}

void printHello() {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  print("[$now] Hello, world! isolate=${isolateId} function='$printHello'");
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
          fontFamily: GoogleFonts.rubik().fontFamily,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      initialRoute: '/home',
      routes: {
        '/home':(context) => Home(),
        }
    );
  }
}


