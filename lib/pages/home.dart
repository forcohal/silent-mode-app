import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'variables.dart';

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
          'Quietify',
          style: TextStyle(
            fontSize: 24,
            color: Color.fromARGB(255, 243, 243, 243),
            fontWeight: FontWeight.bold,
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
  int hrsCount = 0;
  int minsCount = 0;
  int secsCount = 0;
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 100,
            width: 200,
            child: Text(
              "$hrs : $mins",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
              )
            ),
          ),
          
          SizedBox(height: 40),
          Column(
            children: [
              SizedBox(
                height: 35,
                width: 150,
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
                    labelText: 'hh:mm',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)
                    ),
                  ),
                  onChanged: (value) {
                    if (value.length == 5) {
                      setState(() {
                        hrs = int.tryParse(value.substring(0, 2)) ?? 0;
                        mins = int.tryParse(value.substring(3, 5)) ?? 0;
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
            height: 40,
            width: 150,
            child: ElevatedButton(
              onPressed: () {
                if (hrs == 0 && mins == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please set a duration!'))
                  );
                } else {
                  dndPermission();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff000814),
              ),
              child: Text(
                'Mute',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xfff8f9fa),
                )
              )
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 40,
            width: 150,
            child: ElevatedButton(
              onPressed: () {
                normalMode();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff000814),
              ),
              child: Text(
                'Unmute',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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