import 'package:flutter/material.dart';
import 'package:camera_ohm/function_files/calculate_r.dart';
//import 'package:camera_ohm/main.dart';
import '../function_files/color_label.dart';

/// A widget that allows users to select resistor color bands from dropdown menus.
///
/// This interactive view maps selected colors into an internal state tracking list
/// and automatically updates the computed electrical resistance value via [calculateR].
class EnterPage extends StatefulWidget {
  /// Creates an [EnterPage].
  const EnterPage({super.key});
  @override
  State<EnterPage> createState() => _EnterPage();
}

/// The state management layer for [EnterPage] handling dropdown changes.
class _EnterPage extends State<EnterPage> {
  @override
  void initState() {
    super.initState();
    // Use 'widget.' to access properties from the StatefulWidget class
    // Re-initialize the active working array safely from a default standard state template
    selectedColor = List.from(defaultColor); 
  }

  @override
  Widget build(BuildContext context) {
  //  reString = "Click to get R";
  return Center(
      child: ListView(
  //      mainAxisAlignment: MainAxisAlignment.center,
        children: [
//          <Widget>[
          const SizedBox(height: 20),  
          // 1st Band Selection (First significant digit)
          Center(
            child: _buildDropdown("First Color", ColorLabel.black, (val) {
              setState(() => selectedColor[0] = val);
              calculateR();
            }),
          ),
          const SizedBox(height: 20),  
          // Menu 2
          // 2nd Band Selection (Second significant digit)
          Center(
            child: _buildDropdown("Second Color", ColorLabel.black, (val) {
              setState(() => selectedColor[1] = val);
              calculateR();
            }),
          ),
          const SizedBox(height: 20),  
          // Menu 3
          // 3rd Band Selection (Third significant digit or decimal multiplier)
          Center(
            child: _buildDropdown("Third Color", ColorLabel.black, (val) {
              setState(() => selectedColor[2] = val);
              calculateR();
            }),
          ),
          const SizedBox(height: 20),  
          // Menu 4
          // 4th Band Selection (Multiplier or secondary attribute spacing)
          Center(
            child: _buildDropdown("Fourth Color", ColorLabel.none, (val) {
              setState(() => selectedColor[3] = val);
              calculateR();
            }),
          ),
          const SizedBox(height: 20),  
          // Menu 5
          // 5th Band Selection (Tolerance margin percentage descriptor)
          Center(
            child: _buildDropdown("Tolerance Color", ColorLabel.none, (val) {
              setState(() => selectedColor[4] = val);
              calculateR();
            }),
          ),
          const SizedBox(height: 20),  
          const SizedBox(height: 20),  
          // Output
          // Displays the calculated data output
          Center(
            child: Text(
              ' $reString ', // updated output string from calculateR
              style: TextStyle(
              fontSize: 24.0, // Increase font size
              fontWeight: FontWeight.bold, // Make text bold
              ),
            ),
          ),
        ], // children
      ),
    );
  }
  /// Helper factory function that scaffolds a unified engineering [DropdownMenu].
  ///
  /// Maps predefined [ColorLabel.entries] into an immutable dropdown list tracking
  /// explicit selections through an isolated [onChanged] callback hook.
  Widget _buildDropdown(String label, ColorLabel? currentVal, ValueChanged<ColorLabel?> onChanged) {
    return DropdownMenu<ColorLabel>(
      label: Text(label),
      initialSelection: currentVal,
      onSelected: onChanged, // requires entry, not continuous
      width: 200.0,
      dropdownMenuEntries: ColorLabel.entries, 
    );
  }
}

