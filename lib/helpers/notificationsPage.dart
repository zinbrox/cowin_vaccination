import 'dart:convert';

import 'package:cowin_vaccination/pages/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show File, Platform;
import 'package:http/http.dart' as http;
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
    var initSettingAndroid = new AndroidInitializationSettings('@mipmap/ic_launcher');
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

  /*
  Future<void> showNotification() async {
    var androidChannelSpecifics = AndroidNotificationDetails(
        'CHANNEL_ID',
        'CHANNEL_NAME',
        'CHANNEL_DESCRIPTION',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );
    var iosChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics =
    NotificationDetails(
        android: androidChannelSpecifics, iOS: iosChannelSpecifics);
    //await getCustomKeywords();
    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Title', //title,
      'Test Description', //description, //null
      platformChannelSpecifics,
      payload: 'New Payload', //articleURL,
    );
  }
   */
  Future<void> repeatNotification() async {
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL_ID 3',
      'CHANNEL_NAME 3',
      "CHANNEL_DESCRIPTION 3",
      importance: Importance.max,
      priority: Priority.max,
      styleInformation: DefaultStyleInformation(true, true),
    );
    var iosChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics =
    NotificationDetails(android: androidChannelSpecifics, iOS: iosChannelSpecifics);
    List<DistrictAvailability> filtered = await getAvailabilities();
    if(filtered.length > 0) {
      await flutterLocalNotificationsPlugin.periodicallyShow(
        0,
        filtered[0].centerName,
        'Repeating Test Body',
        RepeatInterval.everyMinute,
        platformChannelSpecifics,
        payload: 'Test Payload',
      );
    }
  }


  List<DistrictAvailability> districtAvailabilities = [];


  Future<List<DistrictAvailability>> getAvailabilities() async {
    DistrictAvailability districtAvailability;
    districtAvailabilities.clear();
    List<DistrictAvailability> filtered = [];
    String url = "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByDistrict?district_id=571&date=14-05-2021";
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
    for(var i in districtAvailabilities)
      for(var j in i.sessions) {
        if(j['min_age_limit']==45 && j['available_capacity']>0)
          if(!filtered.contains(i))
            filtered.add(i);
      }
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
