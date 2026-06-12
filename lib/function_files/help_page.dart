import 'package:flutter/material.dart';

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
      child: TextField(
        maxLines: null, // Allows the text area to expand vertically as needed
        controller: TextEditingController(
          text: (helpText),
        ),
        decoration: const InputDecoration(
          border: OutlineInputBorder(), // Adds a clean border around the text box
        ),
      ),
    );
  }
  String helpText = 'In "Enter Color Mode" use the drop down boxes to enter the colors, starting from the end farthest from the tolerance band. ';
}

