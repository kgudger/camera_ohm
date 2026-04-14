import 'package:flutter/material.dart';
import 'package:camera_ohm/function_files/calculate_r.dart';
import 'package:camera_ohm/main.dart';

class EnterPage extends StatefulWidget {
  const EnterPage({super.key});
  @override
  State<EnterPage> createState() => _EnterPage();
}
class _EnterPage extends State<EnterPage> {
  final TextEditingController colorController = TextEditingController();
  ColorLabel? val ;
//  selectedColor = [ColorLabel.black, ColorLabel.black, ColorLabel.black, ColorLabel.none, ColorLabel.none, ColorLabel.none, ColorLabel.none];

  @override
  Widget build(BuildContext context) {
  selectedColor = [ColorLabel.black, ColorLabel.black, ColorLabel.black, ColorLabel.none, ColorLabel.none, ColorLabel.none, ColorLabel.none];
  return Center(
      child: ListView(
  //      mainAxisAlignment: MainAxisAlignment.center,
        children: [
//          <Widget>[
          const SizedBox(height: 20),  
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
          const SizedBox(height: 20),  
          Center(
            child: Text(
              ' $reString ',
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

