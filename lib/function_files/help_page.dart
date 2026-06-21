import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// A widget that displays the application help page.
///
/// This page renders markdown text to explain the operational details of the
/// "Enter Color Mode", "Enter Value Mode", and "Calculate Values Mode".
class HelpPage extends StatefulWidget {
  /// Creates a [HelpPage].
  const HelpPage({super.key});
  @override
  State<HelpPage> createState() => _HelpPage();
}

/// The state class for [HelpPage] that manages the markdown text display content.
class _HelpPage extends State<HelpPage> {
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
        // Renders a clean structural frame container around the document pane
        decoration: BoxDecoration(
          border: Border.all(),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Markdown(
          data: helpText,
          // Customizes the markdown layout typography to match the rest of the application
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 18),      // normal text
          )
        ),
      ),
    );
  }
  /// The markdown-formatted raw text containing instructions for all application modes.
  final String helpText = '''In **Enter Color Mode** use the drop down boxes to enter the colors and calculate the resistor value. Start from the end farthest from the tolerance band.

In **Enter Value Mode** enter the resistor value in the text box to get the colors for that value.

Example: 1.2K 10% 

The top text box shows the resistance value for the colors you entered.

The bottom text box show the nearest standard resistor value to the one entered, including the color bands for the standard resistor value if different from what you entered.

In **Calculate Values Mode** enter any 2 of Voltage, Current, Resistance, Watts on the left side and all 4 values are calculated and shown on the right side.

Version 1.0''';   
}

