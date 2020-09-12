import 'package:clock/constant/theme_colors.dart';
import 'package:clock/models/alarm_model.dart';
import 'package:clock/services/alarm_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import '../../main.dart';

class Alarm extends StatefulWidget {
  @override
  _AlarmState createState() => _AlarmState();
}

class _AlarmState extends State<Alarm> {
  DateTime _alarmTime;
  AlarmDB _alarmDB = AlarmDB();
  Future<List<AlarmModel>> _alarms;
  String _alarmTimeString;
  @override
  void initState() {
    _alarmDB.initializeDatabase().then((value) => loadAlarms());
    super.initState();
  }

  void loadAlarms() {
    _alarms = _alarmDB.getAlarms();
    if (mounted) setState(() {});
  }

  void scheduleAlarm(DateTime scheduledNotificationDateTime) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_notif',
      'alarm_notif',
      'Channel for Alarm notification',
      icon: 'codex_logo',
      sound: RawResourceAndroidNotificationSound('a_long_cold_sting'),
      largeIcon: DrawableResourceAndroidBitmap('codex_logo'),
    );

    var iOSPlatformChannelSpecifics = IOSNotificationDetails(
        sound: 'a_long_cold_sting.wav', presentAlert: true, presentBadge: true, presentSound: true);
    var platformChannelSpecifics =
        NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(0, 'Office', 'Good morning! Time for office.',
        scheduledNotificationDateTime, platformChannelSpecifics);
  }

  void showButtomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      clipBehavior: Clip.antiAlias,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(32.0),
              child: Column(
                children: [
                  FlatButton(
                    onPressed: () async {
                      var selectedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (selectedTime != null) {
                        final now = DateTime.now();
                        var selectedDateTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        _alarmTime = selectedDateTime;

                        setState(() {
                          String _period = selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
                          _alarmTimeString = selectedTime.toString();
                          // '${selectedTime.hourOfPeriod.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}  $_period';
                        });
                      }
                    },
                    child: Text(
                      _alarmTimeString,
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                  CheckboxListTile(
                    value: false,
                    onChanged: (onChange) {},
                    title: Text('Repeat'),
                  ),
                  TextField(
                    onChanged: (value) {},
                    decoration: InputDecoration(
                      hintText: 'Lable',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  FloatingActionButton.extended(
                    onPressed: () async {
                      DateTime scheduleAlarmDateTime;
                      if (_alarmTime.isAfter(DateTime.now()))
                        scheduleAlarmDateTime = _alarmTime;
                      else
                        scheduleAlarmDateTime = _alarmTime.add(Duration(days: 1));

                      var alarmInfo = AlarmModel(
                        dateTime: scheduleAlarmDateTime,
                        lable: 'alarm',
                        enable: true,
                        // days: ['sun', 'dar', 'sl'],
                      );
                      _alarmDB.insertAlarm(alarmInfo);
                      // scheduleAlarm(
                      //     scheduleAlarmDateTime);
                    },
                    icon: Icon(Icons.alarm),
                    label: Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        elevation: 0.0,
        tooltip: 'Add alarm',
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _alarmTimeString = DateFormat('HH:mm').format(DateTime.now());
          showButtomSheet(context);
        },
      ),
      body: FutureBuilder(
        future: _alarms,
        builder: (context, snapshot) => snapshot.hasData
            ? ListView(
                children: snapshot.data.map<Widget>((alarm) {
                  var alarmTime = DateFormat('hh:mm').format(alarm.dateTime);
                  var dayAndNight = DateFormat('aa').format(alarm.dateTime);
                  return Container(
                    padding: EdgeInsets.all(12.0),
                    margin: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18.0),
                      boxShadow: [
                        BoxShadow(
                          offset: Offset(0, 0),
                          color: kShadowColor.withOpacity(0.14),
                          blurRadius: 38,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.alarm),
                            SizedBox(width: 4.0),
                            Text(
                              alarm.lable,
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                            Spacer(),
                            Switch(
                              onChanged: (bool value) {
                                setState(() {
                                  alarm.enable = value;
                                });
                              },
                              activeColor: Theme.of(context).primaryColor,
                              value: alarm?.enable ?? true,
                            ),
                          ],
                        ),
                        // Row(
                        //   children: alarm.days.map((e) => Text('$e, ')).toList(),
                        // ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              alarmTime,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline3
                                  .copyWith(color: Theme.of(context).primaryColor),
                            ),
                            Text(
                              dayAndNight,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline3
                                  .copyWith(fontSize: 14.0, color: Theme.of(context).primaryColor),
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.delete_outline),
                              onPressed: () {},
                            )
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
              )
            : Container(
                child: Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }
}
