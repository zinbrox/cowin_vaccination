import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show File, Platform;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class NotificationPlugin {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final BehaviorSubject<ReceivedNotification>
  didReceivedLocalNotificationSubject =
  BehaviorSubject<ReceivedNotification>();
  var initializationSettings;

  NotificationPlugin._() {
    init();
  }

  init() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    if (Platform.isIOS) {
      _requestIOSPermission();
    }
    initializePlatformSpecifics();
  }

  initializePlatformSpecifics() {
    var initializationSettingsAndroid = new
    AndroidInitializationSettings('LogoIcon');
    var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        ReceivedNotification receivedNotification = ReceivedNotification(
            id: id, title: title, body: body, payload: payload);
        didReceivedLocalNotificationSubject.add(receivedNotification);
      },
    );

    initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  }

  _requestIOSPermission() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        .requestPermissions(
      alert: false,
      badge: true,
      sound: true,
    );
  }

  setListenerForLowerVersions(Function onNotificationInLowerVersions) {
    didReceivedLocalNotificationSubject.listen((receivedNotification) {
      onNotificationInLowerVersions(receivedNotification);
    });
  }

  setOnNotificationClick(Function onNotificationClick) async {
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String payload) async {
          onNotificationClick(payload);
        });
  }


  Future<void> showNotification() async {
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL_ID',
      'CHANNEL_NAME',
      "CHANNEL_DESCRIPTION",
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      //timeoutAfter: 5000,
      styleInformation: BigTextStyleInformation(''),
      //styleInformation: DefaultStyleInformation(true, true),
    );
    var iosChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics =
    NotificationDetails(
        android: androidChannelSpecifics, iOS: iosChannelSpecifics);
    await getCustomKeywords();
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      description, //null
      platformChannelSpecifics,
      payload: articleURL,
    );
    /*
    await flutterLocalNotificationsPlugin.show(
      0,
      'Test Title',
      'Test Body', //null
      platformChannelSpecifics,
      payload: 'New Payload',
    );
     */
  }


  String keywords;
  String url;
  String title;
  String description;
  String articleURL;
  String imageURL;

  void getCustomKeywords() async {
    final prefs = await SharedPreferences.getInstance();

  }

  _downloadAndSaveFile(String url, String fileName) async {
    var directory = await getApplicationDocumentsDirectory();
    var filePath = '${directory.path}/$fileName';
    print(filePath);
    var response = await http.get(Uri.parse(url));
    var file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }


  Future<void> showNotificationWithAttachment() async {
    Time time1 = Time(8,0,0);
    Time time2 = Time(12,0,0);
    Time time3 = Time(16,0,0);
    Time time4 = Time(20,0,0);
    await getCustomKeywords();
    var attachmentPicturePath = await _downloadAndSaveFile(
        imageURL, 'attachment_img.jpg');
    var iOSPlatformSpecifics = IOSNotificationDetails(
      attachments: [IOSNotificationAttachment(attachmentPicturePath)],
    );
    var bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(attachmentPicturePath),
      //contentTitle: "<b>$title</b>",
      htmlFormatContentTitle: true,
      //summaryText: title,
      htmlFormatSummaryText: true,
    );
    var androidChannelSpecifics = AndroidNotificationDetails(
      'CHANNEL ID 2',
      'CHANNEL NAME 2',
      'CHANNEL DESCRIPTION 2',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: bigPictureStyleInformation,
    );

    var notificationDetails =
    NotificationDetails(
        android: androidChannelSpecifics, iOS: iOSPlatformSpecifics);
    await flutterLocalNotificationsPlugin.showDailyAtTime(
      0,
      title,
      null, //null
      time1,
      //RepeatInterval.everyMinute,
      notificationDetails,
      payload: articleURL,
    );

    await flutterLocalNotificationsPlugin.showDailyAtTime(
      1,
      title,
      null, //null
      time2,
      //RepeatInterval.everyMinute,
      notificationDetails,
      payload: articleURL,
    );
    await flutterLocalNotificationsPlugin.showDailyAtTime(
      2,
      title,
      null, //null
      time3,
      //RepeatInterval.everyMinute,
      notificationDetails,
      payload: articleURL,
    );
    await flutterLocalNotificationsPlugin.showDailyAtTime(
      3,
      title,
      null, //null
      time4,
      //RepeatInterval.everyMinute,
      notificationDetails,
      payload: articleURL,
    );

  }

  Future<void> cancelAllNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}