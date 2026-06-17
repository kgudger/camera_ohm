import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:collection/collection.dart';
//import 'dart:math';
import 'package:camera_ohm/function_files/calculate_r.dart';
import 'package:camera_ohm/function_files/enter_page.dart';
//import 'package:camera_ohm/function_files/camera_page.dart';
import 'package:camera_ohm/function_files/help_page.dart';
import 'package:camera_ohm/function_files/value_page.dart';
import 'package:camera_ohm/function_files/calc_page.dart';

void main() {
runApp(const CamerOhmApp());
}

class CamerOhmApp extends StatelessWidget {
  const CamerOhmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'OhmOhm',
        theme: ThemeData(
          colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        ),
      home: const MyHomePage(title: 'OhmOhm Page'),
      )
    );
  }
}

class MyAppState extends ChangeNotifier {
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

int _isExpanded = 1; // Enter page

class _MyHomePageState extends State<MyHomePage> {
  String _buttonText = "Help";
  final List<String> _pageNames = [
  'Enter Value Mode',
  'Enter Color Mode',
  'Calculate Values Mode',
  'Help'
];
  @override

  Widget build(BuildContext context) {
    Widget colmn;
  //  selectedColor = [ColorLabel.black, ColorLabel.black, ColorLabel.black, ColorLabel.none, ColorLabel.none, ColorLabel.none, ColorLabel.none];
    switch (_isExpanded) {
      case 2:
        colmn = CalcPage();
        break;
      case 0:
        colmn = ValuePage();
        break;
      case 3:
        colmn = HelpPage();
        break;
      default:
        colmn = EnterPage();
      break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Center(
            child: Column(
  //        mainAxisAlignment: .center,
              children: [
                const SizedBox(height: 40),  
                const Text('Resistor Calculator'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<int>(
                      value: (_isExpanded <= 2) ? _isExpanded : null,
                      hint: const Text('Select Mode'),
                      items: List.generate(
                        3, // doesn't include Help
                        (index) => DropdownMenuItem<int>(
                          value: index,
                          child: Text(_pageNames[index]),
                        ),
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _buttonText = "Help";
                          _isExpanded = value;
                          reString = "Select Colors to get R";
                        });
                      },
                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      child: Text(_buttonText),
                      onPressed: () {
                        setState(() {
                          if (_isExpanded != 3){
                            _isExpanded = 3;
                            _buttonText = "Exit Help";
                          }
                          else {
                            _isExpanded = 1;
                            _buttonText = "Help";
                          }
                        });
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: colmn,
                  ),
                )
              ], // children
            ),
          ), 
        );
      }, //builder
    );
  }
}

class DialogHelper {
  static dynamic showAlertDialog(BuildContext context, String message) {  
  // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.of(context).pop(); // dismiss dialog
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Debug Info"),
      content: Text(message),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
  //      calculateR();
        return alert;
      },
    );
  }
}

class StatusService {
  // Singleton setup
  StatusService._internal();
  static final StatusService instance = StatusService._internal();

  // The actual notifier holding the String
  final ValueNotifier<String> sharedText = ValueNotifier<String>(" $reString");

  // Helper method to update the value
  void updateText(String newValue) {
    sharedText.value = newValue;
  }
}

