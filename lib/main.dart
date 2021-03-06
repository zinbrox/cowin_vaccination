import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:cowin_vaccination/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
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
      title: "Cowin Slot Notifier",
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
        fontFamily: GoogleFonts.roboto().fontFamily,
        primarySwatch: Colors.deepPurple,
      ),
      themeMode: ThemeMode.dark,
      initialRoute: '/splash',
      routes: {
        '/splash':(context) => SplashScreen(),
        '/home':(context) => Home(),
        }
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
  void wait() {
    Future.delayed(const Duration(seconds: 3), () async {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void initState() {
    super.initState();
    wait();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(image: AssetImage("assets/SlotNotifierLogo.png"), height: 200,),
                SizedBox(height: 20,),
                Text("Slot Notifier", style: GoogleFonts.raleway(textStyle: TextStyle(fontSize: 30, color: Colors.white),))
              ],
            )),
            Text("zinbrox", style: GoogleFonts.rubik(textStyle: TextStyle(fontSize: 20, decoration: TextDecoration.overline),),),
            SizedBox(height: 20,)
          ],
        ),),
    );
  }
}



