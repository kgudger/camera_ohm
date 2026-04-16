import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
//import 'dart:math';
import 'package:camera_ohm/function_files/calculate_r.dart';
import 'package:camera_ohm/function_files/enter_page.dart';
import 'package:camera_ohm/function_files/camera_page.dart';

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
        title: 'CamerOhm',
        theme: ThemeData(
          colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        ),
      home: const MyHomePage(title: 'CamerOhm Page'),
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

bool _isExpanded = false;

class _MyHomePageState extends State<MyHomePage> {
  String _buttonText = "Camera Mode";
  @override

  Widget build(BuildContext context) {
    Widget colmn;
    switch (_isExpanded) {
      case true:
        colmn = CameraPage();
        break;
      case false:
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
                const Text('Welcome to CamerOhm!'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
/*                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                      child: const Text('Toggle Mode'),*/
                      child: Text(_buttonText),
                      onPressed: () {
                      // Update state on click
                        setState(() {
                          _isExpanded = !_isExpanded;
                          if (_buttonText == "Camera Mode") {
                            _buttonText = "Enter Color Mode";
                          } else {
                            _buttonText = "Camera Mode";
                          }
                        });
                      },

                    ),
                    SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Help'),
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

dynamic showAlertDialog(BuildContext context) {
  // set up the button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.of(context).pop(); // dismiss dialog
     },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Resistor Value"),
    content: Text(reString),
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

List<ColorLabel?> selectedColor = [ColorLabel.black, ColorLabel.black, ColorLabel.black, ColorLabel.none, ColorLabel.none, ColorLabel.none, ColorLabel.none];
final List<ColorLabel?> defaultColor = [ColorLabel.black, ColorLabel.black, ColorLabel.black, ColorLabel.none, ColorLabel.none, ColorLabel.none, ColorLabel.none];

typedef ColorEntry = DropdownMenuEntry<ColorLabel>;

// DropdownMenuEntry labels and values for the dropdown menu.
enum ColorLabel {
  black('Black',  Colors.black),
  brown('Brown',  Colors.brown),
  red('Red', Colors.red),
  orange('Orange', Colors.orange),
  yellow('Yellow', Colors.yellow),
  green('Green', Colors.green),
  blue('Blue', Colors.blue),
  pink('Violet', Colors.purple),
  grey('Grey', Colors.grey),
  white('White', Colors.white),
  gold('Gold', Colors.amber),
  silver('Silver', Color.fromARGB(0xFF, 0xC0, 0xC0, 0xC0)),
  none('None', Colors.black);

  const ColorLabel(this.label, this.color);
  final String label;
  final Color color;

  static final List<ColorEntry> entries = UnmodifiableListView<ColorEntry>(
    values.map<ColorEntry>(
      (ColorLabel color) => ColorEntry(
        value: color,
        label: color.label,
        enabled: color.label != 'Indigo',
        style: MenuItemButton.styleFrom(foregroundColor: color.color),
      ),
    ),
  );
}

class StatusService {
  // Singleton setup
  StatusService._internal();
  static final StatusService instance = StatusService._internal();

  // The actual notifier holding the String
  final ValueNotifier<String> sharedText = ValueNotifier<String>("Click Calculate...");

  // Helper method to update the value
  void updateText(String newValue) {
    sharedText.value = newValue;
  }
}