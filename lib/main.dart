import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera_ohm/function_files/calculate_r.dart';
import 'package:camera_ohm/function_files/enter_page.dart';
import 'package:camera_ohm/function_files/help_page.dart';
import 'package:camera_ohm/function_files/value_page.dart';
import 'package:camera_ohm/function_files/calc_page.dart';

void main() {
runApp(const CamerOhmApp());
}

/// The root application widget wrapping localized states and themes.
class CamerOhmApp extends StatelessWidget {
  const CamerOhmApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Injects global app model lifecycle states using ChangeNotifierProvider
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'OhmOhm',
        theme: ThemeData(
          // Generates harmonious primary and accent color pairings from a deep purple core token
          colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        ),
      home: const MyHomePage(title: 'OhmOhm Page'),
      )
    );
  }
}
/// Global shared state model tracking domain settings or background data configurations.
class MyAppState extends ChangeNotifier {
}

/// The responsive primary layout scaffold supporting cross-page view switching.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  /// The decorative headline title displayed in sub-components or window regions.
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// Handles the UI composition and menu navigation selections for [MyHomePage].
class _MyHomePageState extends State<MyHomePage> {
  // Keeps track of the contextual toggle text display for the Help button
  String _buttonText = "Help";
  // Flat structural indexing strings representing target page navigation paths
  final List<String> _pageNames = [
  'Enter Value Mode',
  'Enter Color Mode',
  'Calculate Values Mode', // note no Help page in this list
  'Help'
  ];
  // keeps track of drop down list value
  int _isExpanded = 1; // Enter page
  @override

  Widget build(BuildContext context) {
    Widget colmn;
    // Route matrix matching the active active page pointer index to dedicated widgets
    switch (_isExpanded) {
      case 2:
        colmn = CalcPage(); // page to calculate V,I,R,W from any 2
        break;
      case 0:
        colmn = ValuePage(); // page to give colors and standard R value
        break;
      case 3:
        colmn = HelpPage(); 
        break;
      default:
        colmn = EnterPage(); // enter colors to get R value
      break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Center(
            child: Column(
              children: [
                const SizedBox(height: 40),  
                const Text('Resistor Calculator'), // title
                // Horizontal navigation workspace menu items
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dynamic workspace dropdown selector
                    DropdownButton<int>(
                      // Restrains pointer bounds to active calculated dropdown index cards only
                      value: (_isExpanded <= 2) ? _isExpanded : null,
                      hint: const Text('Select Mode'),
                      // Generate selection options for calculation modes, intentionally skipping Help
                      items: List.generate( 3, // doesn't include Help and restrains pointer
                        (index) => DropdownMenuItem<int>(
                          value: index,
                          child: Text(_pageNames[index]),
                        ),
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _buttonText = "Help"; // reset Help button (could have been Exit Help)
                          _isExpanded = value;
                          // Reset fallback string labels 
                          reString = "Select Colors to get R";
                        });
                      },
                    ),
                    SizedBox(width: 20),
                    // Contextual multi-action Help toggle button
                    ElevatedButton(
                      child: Text(_buttonText), // Help button
                      onPressed: () {
                        setState(() {
                          if (_isExpanded != 3){
                            // Route directly to Help View layout
                            _isExpanded = 3;
                            _buttonText = "Exit Help";
                          }
                          else {
                            // Close Help and fall back to default operational page route
                            _isExpanded = 1;
                            _buttonText = "Help";
                          }
                        });
                      },
                    ),
                  ],
                ),
                // Core operational frame showing the currently mapped active sub-page view
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: colmn, // sub page holder
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
