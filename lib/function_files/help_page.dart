import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});
  @override
  State<HelpPage> createState() => _HelpPage();
}
class _HelpPage extends State<HelpPage> {
  final TextEditingController colorController = TextEditingController();
  @override
  void initState() {
    super.initState();
    // Use 'widget.' to access properties from the StatefulWidget class
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Markdown(
          data: helpText,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 18),      // normal text
          )
        ),
      ),
    );
  }
  String helpText = '''In **Enter Color Mode** use the drop down boxes to enter the colors and calculate the resistor value. Start from the end farthest from the tolerance band.

In **Enter Value Mode** enter the resistor value in the text box to get the colors for that value.

Example: 1.2K 10% 

The top text box shows the resistance value for the colors you entered. The bottom text box show the nearest standard resistor value to the one entered, including the color bands for the standard resistor value.

The bottom text area will show the nearest standard resistor value to your request.

In **Calculate Values Mode** enter any 2 of Voltage, Current, Resistance, Watts on the left side and all 4 values are calculated and shown on the right side.

Version 1.0''';   
}

