import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'variables.dart';
import 'dart:async';



var platform = const MethodChannel('bridge');

int mins = 0;
int hrs = 0;


class Home extends StatelessWidget {
  const Home({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HushTime',
          style: TextStyle(
            fontFamily: 'AlfaSlabOne',
            fontSize: 20,
            color: Color.fromARGB(255, 243, 243, 243),
            //fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xff000814),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
        ),
      ),
      body: VolumeControllerWidget(),
    );
  }
}

class VolumeControllerWidget extends StatefulWidget {
  @override
  State<VolumeControllerWidget> createState() => VolControl();
}


class VolControl extends State<VolumeControllerWidget> {
  final TextEditingController timeController = TextEditingController();
  Timer? _timer;
  int secs = 0;
  
  @override
  void initState() {
    super.initState();
    checkTimer();
  }

  Future<void> checkTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final int? targetTimeMillis = prefs.getInt('timer_end_time');

    if (targetTimeMillis != null) {
      final targetTime = DateTime.fromMillisecondsSinceEpoch(targetTimeMillis);
      final now = DateTime.now();
      
      if (targetTime.isAfter(now)) {
        final remaining = targetTime.difference(now);
        setState(() {
          hrs = remaining.inHours;
          mins = remaining.inMinutes % 60;
          secs = remaining.inSeconds % 60;
        });
        startTimer(autoSave: false);
      } else {
        prefs.remove('timer_end_time');
        setState(() {
          hrs = 0;
          mins = 0;
          secs = 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    timeController.dispose();
    super.dispose();
  }

  void startTimer({bool autoSave = true}) async {
    _timer?.cancel();
    
    if (autoSave) {
      final prefs = await SharedPreferences.getInstance();
      final targetTime = DateTime.now().add(Duration(hours: hrs, minutes: mins, seconds: secs));
      await prefs.setInt('timer_end_time', targetTime.millisecondsSinceEpoch);
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
       if (!mounted) {
         timer.cancel();
         return; 
       }

       final prefs = await SharedPreferences.getInstance();
       final int? targetTimeMillis = prefs.getInt('timer_end_time');
       
       if (targetTimeMillis != null) {
          final targetTime = DateTime.fromMillisecondsSinceEpoch(targetTimeMillis);
          final now = DateTime.now();
          final remaining = targetTime.difference(now);
          
          if (remaining.inSeconds > 0) {
             setState(() {
               hrs = remaining.inHours;
               mins = remaining.inMinutes % 60;
               secs = remaining.inSeconds % 60;
             });
          } else {
             timer.cancel();
             prefs.remove('timer_end_time');
             setState(() {
               hrs = 0;
               mins = 0;
               secs = 0;
             });
          }
       } else {
         // Fallback if pref is missing for some reason
          if (secs > 0) {
            setState(() { secs--; });
          } else {
            if (mins > 0) {
              setState(() { mins--; secs = 59; });
            } else {
              if (hrs > 0) {
                setState(() { hrs--; mins = 59; secs = 59; });
              } else {
                timer.cancel();
              }
            }
          }
       }
    });
  }

  void stopTimer() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('timer_end_time');
    setState(() {
        secs = 0;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            width: 300,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "$hrs : ${mins.toString().padLeft(2, '0')} : ${secs.toString().padLeft(2, '0')}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'AlfaSlabOne',
                  fontSize: 100,
                  //fontWeight: FontWeight.bold,
                )
              ),
            ),
          ),
          
          SizedBox(height: 20),
          Column(
            children: [
              SizedBox(
                height: 55,
                width: 250,
                child: TextField(
                  controller: timeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    MaskedInputFormatter(
                      '##:##',
                      allowedCharMatcher: RegExp(r'[0-9]')
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'set duration (hh:mm)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)
                    ),
                  ),
                  onChanged: (value) {
                    if (value.length == 5) {
                      setState(() {
                        hrs = int.tryParse(value.substring(0, 2)) ?? 0;
                        mins = int.tryParse(value.substring(3, 5)) ?? 0;
                        secs = 0;
                      });
                      
                      if (hrs > 23) {
                        timeController.text = '23:${value.substring(3, 5)}';
                        setState(() {
                          hrs = 23;
                        });
                      }
                      if (mins > 59) {
                        timeController.text = '${value.substring(0, 2)}:59';
                        setState(() {
                          mins = 59;
                        });
                      }
                    }
                  }
                )
              ),
              SizedBox(height: 40)
            ],
          ),
          SizedBox(
            height: 50,
            width: 250,
            child: ElevatedButton(
              onPressed: () {
                if (hrs == 0 && mins == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please set a duration!'))
                  );
                } else {
                  dndPermission();
                  startTimer();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff000814),
              ),
              child: Text(
                'Mute',
                style: TextStyle(
                  fontFamily: 'AlfaSlabOne',
                  fontSize: 18,
                  color: Color(0xfff8f9fa),
                )
              )
            ),
          ),
          SizedBox(height: 30),
          SizedBox(
            height: 50,
            width: 250,
            child: ElevatedButton(
              onPressed: () {
                normalMode();
                stopTimer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff000814),
              ),
              child: Text(
                'Unmute',
                style: TextStyle(
                  fontFamily: 'AlfaSlabOne',
                  fontSize: 18,
                  //fontWeight: FontWeight.bold,
                  color: Color(0xfff8f9fa),
                )
              )
            ),
          ),
        ]
      )
    );
  }
}

void buttonColorChange() {
  grey = const Color(0xffe5e5e5);
}

Future<void> dndPermission() async {
  try {
    await platform.invokeMethod('dndPermission', {
      'hours': hrs,
      'minutes': mins,
    });
  } catch (e) {
    debugPrint("Error: $e");
  }
}

Future<void> normalMode() async {
  try {
    await platform.invokeMethod("normalMode");
  } catch (e) {
    debugPrint("error : $e");
  }
}

Future<void> startForegroundTask() async {
  try {
    await platform.invokeMethod("startForegroundTask");
  } catch (e) {
    debugPrint("error : $e");
  }
}