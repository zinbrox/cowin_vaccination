import 'dart:isolate';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:cowin_vaccination/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  runApp(MyApp());
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
        brightness: Brightness.light,
          fontFamily: GoogleFonts.rubik().fontFamily,
          textTheme: GoogleFonts.rubikTextTheme(
            Theme.of(context).textTheme,
          ),
          scaffoldBackgroundColor: Colors.black,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: GoogleFonts.rubik().fontFamily,
        primarySwatch: Colors.deepPurple,
      ),
      themeMode: ThemeMode.dark,
      initialRoute: '/home',
      routes: {
        '/home':(context) => Home(),
        }
    );
  }
}


