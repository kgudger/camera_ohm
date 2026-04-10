import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
//import 'dart:math';
import 'package:camera_ohm/function_files/calculate_r.dart';
import 'package:camera/camera.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  bool _isExpanded = false;
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
                const Text('Welcome to CamerOhm!'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() => _isExpanded = !_isExpanded),
                      child: const Text('Toggle Screen'),
                    ),
                    SizedBox(width: 20),
                    Text('Select Resistor Values:'
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
class CameraPage extends StatefulWidget {/*/  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Placeholder(),
        ]
      ),
    );
  }*/
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPage();
}

class _CameraPage extends State<CameraPage> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    // 1. Get available cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // 2. Initialize controller with the first camera
    _controller = CameraController(cameras[0], ResolutionPreset.medium);
    await _controller!.initialize();

    if (!mounted) return;
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Camera in Column")),
      body: Column(
        children: [
          // Other UI elements
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Live Camera Preview:", style: TextStyle(fontSize: 18)),
          ),
          
          // Camera Preview inside the Column
          Expanded(
            child: _isInitialized
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CameraPreview(_controller!),
                    ),
                  )
                : Center(child: CircularProgressIndicator()),
          ),

          // Action buttons below the camera
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () => print("Take Photo Logic"),
              child: Text("Capture Image"),
            ),
          ),
        ],
      ),
    );
  }
}

class EnterPage extends StatefulWidget {
  const EnterPage({super.key});
  @override
  State<EnterPage> createState() => _EnterPage();
}
class _EnterPage extends State<EnterPage> {
  final TextEditingController colorController = TextEditingController();
  ColorLabel? val ;
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
  //      mainAxisAlignment: MainAxisAlignment.center,
        children: [
//          <Widget>[
          Center(
            child: _buildDropdown("First Color", ColorLabel.black, (val) {
              setState(() => selectedColor[0] = val);
              calculateR();
            }),
          ),
          const SizedBox(height: 20),  
          // Menu 2
          Center(
            child: _buildDropdown("Second Color", ColorLabel.black, (val) {
              setState(() => selectedColor[1] = val);
              calculateR();
            }),
          ),
          const SizedBox(height: 20),  
          // Menu 3
          Center(
            child: _buildDropdown("Third Color", ColorLabel.black, (val) {
              setState(() => selectedColor[2] = val);
              calculateR();
            }),
          ),
          const SizedBox(height: 20),  
          // Menu 4
          Center(
            child: _buildDropdown("Fourth Color", ColorLabel.none, (val) {
              setState(() => selectedColor[3] = val);
              calculateR();
            }),
          ),
          const SizedBox(height: 20),  
          // Menu 5
          Center(
            child: _buildDropdown("Tolerance Color", ColorLabel.none, (val) {
              setState(() => selectedColor[4] = val);
              calculateR();
            }),
          ),
          const SizedBox(height: 20),  
          // Menu 6
  /*        Center(
            child: _buildDropdown("Temp Coef Color", ColorLabel.none, (val) {
              setState(() => selectedColor[5] = val);
              calculateR();
            }),
          ),          
          const SizedBox(height: 20),  */
          ElevatedButton(
            onPressed: () {
              showAlertDialog(context);
            },
            child: const Text('Show Resistor Value'),
          ),
        ], // children
      ),
    );
  }
  Widget _buildDropdown(String label, ColorLabel? currentVal, ValueChanged<ColorLabel?> onChanged) {
    return DropdownMenu<ColorLabel>(
      label: Text(label),
      initialSelection: currentVal,
      onSelected: onChanged,
      width: 200.0,
      dropdownMenuEntries: ColorLabel.entries, /*options.map((String value) {
        return DropdownMenuEntry<String>(
          value: value,
          label: value,
        ); 
      }).toList(),*/
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
