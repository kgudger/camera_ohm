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
  ColorLabel? selectedColor = ColorLabel.black;
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
  //      mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                selectedColor = color;
              },
              dropdownMenuEntries: ColorLabel.entries,
            ),
            const SizedBox(width: 24),
        ], // children
      ),
    );
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
  pink('Violet', Colors.purple),
  grey('Grey', Colors.grey),
  white('White', Colors.white);

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
