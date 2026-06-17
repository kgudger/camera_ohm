import 'package:flutter/material.dart';
import 'dart:math';

class CalcPage extends StatefulWidget {
  const CalcPage({super.key});
  @override
  State<CalcPage> createState() => _CalcPage();
}
class _CalcPage extends State<CalcPage> {
  final voltageIn = TextEditingController();
  final currentIn = TextEditingController();
  final resistanceIn = TextEditingController();
  final wattageIn = TextEditingController();

  final voltageOut = TextEditingController();
  final currentOut = TextEditingController();
  final resistanceOut = TextEditingController();
  final wattageOut = TextEditingController();

  void _onInputChanged(String _) {
    calcValues(
      voltageIn.text,
      currentIn.text,
      resistanceIn.text,
      wattageIn.text,
    );
  }

  Widget buildField(
    String title,
    TextEditingController controller,
    bool readOnly,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onSubmitted: readOnly ? null : _onInputChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resistor Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - inputs
            Expanded(
              child: Column(
                children: [
                  Center(
                    child: Text(
                      'Input',
                      style: TextStyle(
                      fontSize: 24.0, // Increase font size
                      fontWeight: FontWeight.bold, // Make text bold
                      ),
                    ),
                  ),
                  buildField(
                    'Voltage',
                    voltageIn,
                    false,
                  ),
                  const SizedBox(height: 16),

                  buildField(
                    'Current',
                    currentIn,
                    false,
                  ),
                  const SizedBox(height: 16),

                  buildField(
                    'Resistance',
                    resistanceIn,
                    false,
                  ),
                  const SizedBox(height: 16),

                  buildField(
                    'Watts',
                    wattageIn,
                    false,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Right column - outputs
            Expanded(
              child: Column(
                children: [
                  Center(
                    child: Text(
                      'Calculated',
                      style: TextStyle(
                      fontSize: 24.0, // Increase font size
                      fontWeight: FontWeight.bold, // Make text bold
                      ),
                    ),
                  ),
                  buildField(
                    'Voltage',
                    voltageOut,
                    true,
                  ),
                  const SizedBox(height: 16),

                  buildField(
                    'Current',
                    currentOut,
                    true,
                  ),
                  const SizedBox(height: 16),

                  buildField(
                    'Resistance',
                    resistanceOut,
                    true,
                  ),
                  const SizedBox(height: 16),

                  buildField(
                    'Watts',
                    wattageOut,
                    true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
    @override
    void dispose() {
    voltageIn.dispose();
    currentIn.dispose();
    resistanceIn.dispose();
    wattageIn.dispose();

    voltageOut.dispose();
    currentOut.dispose();
    resistanceOut.dispose();
    wattageOut.dispose();

    super.dispose();
  }
void calcValues(
  String voltage,
  String current,
  String resistance,
  String wattage,
) {
  double? v = double.tryParse(voltage);
  double? i = double.tryParse(current);
  double? r = double.tryParse(resistance);
  double? p = double.tryParse(wattage);

  final count =
      [v, i, r, p].where((x) => x != null).length;

  if (count < 2) {
    setState(() {
      voltageOut.text = '';
      currentOut.text = '';
      resistanceOut.text = '';
      wattageOut.text = '';
    });
    return;
  }

  try {
    // V + I
    if (v != null && i != null) {
      r = v / i;
      p = v * i;
    }

    // V + R
    else if (v != null && r != null) {
      i = v / r;
      p = v * i;
    }

    // V + P
    else if (v != null && p != null) {
      i = p / v;
      r = v / i;
    }

    // I + R
    else if (i != null && r != null) {
      v = i * r;
      p = v * i;
    }

    // I + P
    else if (i != null && p != null) {
      v = p / i;
      r = v / i;
    }

    // R + P
    else if (r != null && p != null) {
      i = sqrt(p / r);
      v = i * r;
    }

    setState(() {
      voltageOut.text = v?.toStringAsFixed(3) ?? '';
      currentOut.text = i?.toStringAsFixed(3) ?? '';
      resistanceOut.text = r?.toStringAsFixed(3) ?? '';
      wattageOut.text = p?.toStringAsFixed(3) ?? '';
    });
  } catch (_) {
    setState(() {
      voltageOut.text = '';
      currentOut.text = '';
      resistanceOut.text = '';
      wattageOut.text = '';
    });
  }
}}

