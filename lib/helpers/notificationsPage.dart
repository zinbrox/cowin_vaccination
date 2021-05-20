import 'dart:convert';

import 'package:cowin_vaccination/pages/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show File, Platform;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/subjects.dart';

class LocalNotifyManager {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  var initializationSettings;
  BehaviorSubject<ReceivedNotification> get didReceiveLocalNotificationSubject =>
  BehaviorSubject<ReceivedNotification>();

  LocalNotifyManager.init() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    if(Platform.isIOS) {
      requestIOSPermission();
    }
    initializePlatformSpecifics();
  }

  requestIOSPermission() {
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>().requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  initializePlatformSpecifics() {
    var initSettingAndroid = new AndroidInitializationSettings('notification_icon_logo');
    var initSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
          ReceivedNotification receivedNotification = ReceivedNotification(
              id: id, title: title, body: body, payload: payload);
          didReceiveLocalNotificationSubject.add(receivedNotification);
      },
    );
    initializationSettings = InitializationSettings(android: initSettingAndroid, iOS: initSettingsIOS);
  }

  setListenerForLowerVersions(Function onNotificationInLowerVersions) {
    didReceiveLocalNotificationSubject.listen((receivedNotification) {
      onNotificationInLowerVersions(receivedNotification);
    });
  }

  setOnNotificationClick(Function onNotificationClick) async {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
    onSelectNotification: (String payload) async {
      onNotificationClick(payload);
    });
  }

  Future<void> repeatNotification() async {
    print("In repeatNotification");
        var androidChannelSpecifics = AndroidNotificationDetails(
          'CHANNEL_ID 1',
          'Slot Availability',
          "Notifications about Slot Availabilities",
          importance: Importance.max,
          priority: Priority.max,
          onlyAlertOnce: true,
          styleInformation: BigTextStyleInformation(''),
        );
        var iosChannelSpecifics = IOSNotificationDetails();
        var platformChannelSpecifics =
        NotificationDetails(
            android: androidChannelSpecifics, iOS: iosChannelSpecifics);
        List<DistrictAvailability> filtered = await getAvailabilities();
        int capacity;
        String vaccine, center;
        // Sort sessions so the one with most available is at top
        if (filtered.length > 0) {
          for (var i in filtered) {
            i.sessions.sort((a, b) =>
                b['available_capacity'].compareTo(a['available_capacity']));
          }
          filtered.sort((a, b) =>
              b.sessions[0]['available_capacity'].compareTo(
                  a.sessions[0]['available_capacity']));

          capacity = filtered[0].sessions[0]['available_capacity'];
          vaccine = filtered[0].sessions[0]['vaccine'];
          center = filtered[0].centerName;

          await flutterLocalNotificationsPlugin.show(
            0,
            'Hurry! Slots Available at $center',
            'Available Capacity: $capacity. Vaccine: $vaccine',
            platformChannelSpecifics,
            payload: 'Test Payload',

          );
        }
  }


  List<DistrictAvailability> districtAvailabilities = [];


  Future<List<DistrictAvailability>> getAvailabilities() async {
    print("In getAvailabilities");
    DistrictAvailability districtAvailability;
    districtAvailabilities.clear();
    List<DistrictAvailability> filtered = [];

    var now = new DateTime.now();
    var formatter = new DateFormat('dd-MM-yyyy');
    String formattedDate = formatter.format(now);

    final prefs = await SharedPreferences.getInstance();
    final districtID = prefs.getInt('districtID') ?? 571;


    String url = "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByDistrict?district_id=$districtID&date=$formattedDate";
    var response = await http.get(Uri.parse(url));
    var jsonData = jsonDecode(response.body);

    for (var elements in jsonData['centers']) {
      districtAvailability = new DistrictAvailability(
        centerId: elements['center_id'],
        centerName: elements['name'],
        centerAddress: elements['address'],
        districtName: elements['district_name'],
        blockName: elements['block_name'],
        pincode: elements['pincode'],
        timeFrom: elements['from'],
        timeTo: elements['to'],
        feeType: elements['fee_type'],
        sessions: elements['sessions'],
      );


      districtAvailabilities.add(districtAvailability);
    }
    final doseNum = prefs.getString('doseNum') ?? "Dose 1";
    for(var i in districtAvailabilities)
      for(var j in i.sessions) {
        if(j['min_age_limit']==18)
          if((doseNum=="Dose 1" && j['available_capacity_dose1']>0) || (doseNum=="Dose 2" && j['available_capacity_dose2']>0))
          if(!filtered.contains(i))
            filtered.add(i);
      }
    print(filtered.length);
    return filtered;

  }

  Future<void> cancelAllNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

}

LocalNotifyManager localNotifyManager = LocalNotifyManager.init();

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;
  ReceivedNotification({@required this.id, @required this.title, @required this.body, @required this.payload});
}
