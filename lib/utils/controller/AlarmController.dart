import 'dart:io';
import 'dart:ui';
import 'package:bapkok/pages/MainPage.dart';
import 'package:bapkok/utils/api/MealData.dart';
import 'package:bapkok/utils/controller/SchoolController.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:timezone/timezone.dart' as tz;

class AlarmController extends GetxController {
  final box = GetStorage();
  var alarms = {}.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
    //scheduleAllAlarms();
  }

  void loadData() {
    alarms.value = box.read('alarms') ?? {};
  }

  void addAlarm(Map<String, dynamic> alarm) {
    final id = (alarms.length + 1).toString();
    alarms[id] = alarm;
    box.write('alarms', alarms);

    scheduleAlarm(id, alarm);
  }

  void setLoading(bool value) {
    isLoading.value = value;
  }

  void setAlarm(String id, Map<String, dynamic> alarm) {
    alarms[id] = alarm;
    box.write('alarms', alarms);

    scheduleAlarm(id, alarm);
  }

  void deleteAlarm(String id) {
    alarms.remove(id);
    box.write('alarms', alarms);

    cancelAlarm(id);
  }

  void toggleAlarm(String id) {
    alarms[id]['status'] = !alarms[id]['status'];
    box.write('alarms', alarms);

    if (alarms[id]['status']) {
      scheduleAlarm(id, alarms[id]);
    } else {
      cancelAlarm(id);
    }
  }

  void scheduleAllAlarms() {
    alarms.forEach((id, alarm) {
      if (alarm['status']) {
        scheduleAlarm(id, alarm);
      }
    });
  }

  void scheduleAlarm(String id, Map<String, dynamic> alarm) async {
    _scheduleDailyNotification(id, alarm['time']);
  }

  void clearAllAlarms() {
    alarms.forEach((id, alarm) {
      cancelAlarm(id);
    });
    alarms.clear();
    box.remove('alarms');
  }

  void cancelAlarm(String id) async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.cancel(int.parse(id));
  }

  Future<void> _scheduleDailyNotification(String id, String time) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    SchoolController schoolController = Get.find();

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        schoolController.selectMealType(alarms[id]["mealType"]);
        schoolController.selectedSchool(alarms[id]["schoolName"]);
        final data = await fetchSchoolMeal(
            schoolController.selectedSchool.value,
            '${DateTime.now().year}'
            '${DateTime.now().month.toString().padLeft(2, '0')}'
            '${DateTime.now().day.toString().padLeft(2, '0')}');
        schoolController.setMealData(data);
        Get.offAll(() => const MainPage());
      },
    );

    bool? result;
    if (Platform.isAndroid) {
      result = true;
    } else {
      result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    if (result == true) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      final hour = int.parse(time.split(":")[0]);
      final minute = int.parse(time.split(":")[1]);

      var android = const AndroidNotificationDetails(
        'daily_alarm',
        'Daily Alarm',
        channelDescription: 'Daily alarm notification',
        importance: Importance.max,
        priority: Priority.max,
        color: Color.fromARGB(255, 255, 0, 0),
      );

      var ios = const DarwinNotificationDetails();

      var detail = NotificationDetails(android: android, iOS: ios);

      makeDate(hour, min, sec) {
        var now = tz.TZDateTime.now(tz.local);
        var when = tz.TZDateTime(
            tz.local, now.year, now.month, now.day, hour, min, sec);
        if (when.isBefore(now)) {
          print(when.add(const Duration(minutes: 1)));
          return when.add(const Duration(minutes: 1));
        } else {
          print(when);
          return when;
        }
      }

      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      await flutterLocalNotificationsPlugin.zonedSchedule(
        int.parse(id),
        '급식 알림!',
        '알람을 눌러서 ${alarms[id]['mealType']}을 확인하세요!',
        makeDate(hour, minute, 0),
        detail,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: alarms[id]['mealType'],
      );
    }
  }
}
