import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';


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
  final TextEditingController _myController = TextEditingController(text: 'Select Resistor Values:');

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
                    TextField(
                      controller: _myController,
                    )            
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
class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

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
//        scrollDirection: Axis.horizontal,
//        shrinkWrap: true,
        children: 
          <Widget>[
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
          Center(
            child: _buildDropdown("Temp Coef Color", ColorLabel.none, (val) {
              setState(() => selectedColor[5] = val);
              calculateR();
            }),
          ),          
/*            const SizedBox(width: 24),
            DropdownMenu<ColorLabel>(
              initialSelection: ColorLabel.black,
              controller: colorController,
                      // The default requestFocusOnTap value depends on the platform.
                      // On mobile, it defaults to false, and on desktop, it defaults to true.
                      // Setting this to true will trigger a focus request on the text field, and
                      // the virtual keyboard will appear afterward.
              requestFocusOnTap: true,
              label: const Text('Color'),
              onSelected: (ColorLabel? color) {
                selectedColor[0] = color;
                setState(() => selectedColor[0] = color);
              },
              dropdownMenuEntries: ColorLabel.entries,
            ),
            const SizedBox(height:  24),
            DropdownMenu<ColorLabel>(
              initialSelection: ColorLabel.black,
              controller: colorController,
                      // The default requestFocusOnTap value depends on the platform.
                      // On mobile, it defaults to false, and on desktop, it defaults to true.
                      // Setting this to true will trigger a focus request on the text field, and
                      // the virtual keyboard will appear afterward.
              requestFocusOnTap: true,
              label: const Text('Color'),
              onSelected: (ColorLabel? color) {
                setState(() {
                  selectedColor[1] = color;
                });
              },
              dropdownMenuEntries: ColorLabel.entries,
            ), */
        ]
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
List<ColorLabel?> selectedColor = [null, null, null, null, null, null];

void calculateR() {
  double totalR = 0.0;
  if (selectedColor[0] != null) {
    ColorLabel? tempC = selectedColor[0];
    int newR = (tempC!.index) ;
    if ((newR != 0) && (newR <= 9) ) {
      totalR = newR.toDouble();
      print(totalR);
      
    } else {
      newR = 0 ;
    }
  }
}

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
  violet('Violet', Colors.purple),
  grey('Grey', Colors.grey),
  white('White', Colors.white),
  gold('Gold', Colors.amber),
  silver('Silver', Color.fromARGB(0xFF, 0xC0, 0xC0, 0xC0)),
  none('None', Color.fromARGB(0x00, 0x00, 0x00, 0x00));
  
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