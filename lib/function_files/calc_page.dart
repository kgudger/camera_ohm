import 'package:flutter/material.dart';
import 'dart:math';

/// A widget that provides an Ohm's Law and electrical power calculator page.
///
/// It allows users to enter any two parameters out of Voltage, Current, Resistance,
/// or Wattage, and dynamically calculates the remaining values.
class CalcPage extends StatefulWidget {
  const CalcPage({super.key});
  @override
  State<CalcPage> createState() => _CalcPage();
}

/// The state for [CalcPage] managing text inputs, component state, and equations.
class _CalcPage extends State<CalcPage> {
  // Input fields controllers
  final voltageIn = TextEditingController();
  final currentIn = TextEditingController();
  final resistanceIn = TextEditingController();
  final wattageIn = TextEditingController();

  // Read-only calculated output fields controllers
  final voltageOut = TextEditingController();
  final currentOut = TextEditingController();
  final resistanceOut = TextEditingController();
  final wattageOut = TextEditingController();

  // Triggers recalculations whenever any user-controlled text changes.
  void _onInputChanged(String _) {
    calcValues(
      voltageIn.text,
      currentIn.text,
      resistanceIn.text,
      wattageIn.text,
    );
  }
  /// Helper layout widget that builds a standard labeled [TextField].
  ///
  /// Listens to user submissions via [_onInputChanged].
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
                    child: Text( // header title
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
                    child: Text( // right column title
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
    // Prevent system memory leaks by discarding lifecycle handles
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
  /// Core solver that applies Ohm's Law and Watt's Law equations.
  ///
  /// Needs at least 2 structural non-null metric values to properly calculate. 
  /// Updates target text rendering buffers inside a single [setState] block.
  void calcValues(
    String voltage,
    String current,
    String resistance,
    String wattage,
  ) {
    // Matches leading numbers, allowing optional whitespace and decimal points
    // Parse the matched digits, or fallback to null if no number was found
    double? v = parseInput(voltage);  
    double? i = parseInput(current);  
    double? r = parseInput(resistance);  
    double? p = parseInput(wattage);  

    // 2. Count active numerical entries present
    final count =
        [v, i, r, p].where((x) => x != null).length;

    // 3. Reject insufficient datasets or empty states
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
      // 4. Matrix selection branch solving remaining electrical parameters
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

      // 5. Commit clean values rounded to three decimal positions back to the UI
      setState(() {
        voltageOut.text = formatEngineering(v); // scales to k,M,G or m,μ
        currentOut.text = formatEngineering(i);
        resistanceOut.text = formatEngineering(r);
        wattageOut.text = formatEngineering(p);
      });
    } catch (_) {
      // Fallback reset on arithmetic failures like dividing by zero
      setState(() {
        voltageOut.text = '';
        currentOut.text = '';
        resistanceOut.text = '';
        wattageOut.text = '';
      });
    }
  }
}

/// Parses an engineering string input into a standard base double value.
/// 
/// Supports negative values, metric prefixes (m, k, M), and units:
/// * Volts: V, v, volt, volts, voltage
/// * Amps: A, a, amp, amps, ampere, amperes
/// * Ohms: Ω, ohm, ohms, R, r
/// * Watts: W, w, watt, watts
double? parseInput(String input) {
  // 1. Regex captures: Optional minus, digits with optional decimals, 
  //    optional spacing, optional SI prefix, and the specific target unit text.
  final RegExp genericRegex = RegExp(
    r'^\s*(-?\d+(?:\.\d+)?)\s*([mKkMuμG])?\s*(volt|volts|V|v|ampere|amperes|amp|amps|A|a|ohm|ohms|R|r|Ω|watt|watts|W|w)?',
    caseSensitive: true,
  );

  final Match? match = genericRegex.firstMatch(input);
  if (match == null) return null;

  // 2. Extract and parse the root base double value
  final String numberStr = match.group(1)!;
  double? value = double.tryParse(numberStr);
  if (value == null) return null;

  // 3. Scale the value using the captured SI multiplier prefix
  final String? prefix = match.group(2);
  if (prefix != null) {
    switch (prefix) {
      case 'u':
      case 'micro':
      case 'μ':
        value *= 1e-6; // micro
        break;
      case 'm':
        value *= 1e-3; // milli
        break;
      case 'k':
      case 'K':
        value *= 1e3;  // kilo
        break;
      case 'M':
        value *= 1e6;  // Mega
        break;
      case 'G':
        value *= 1e9;  // Giga
        break;
    }
  }

  return value;
}
/// Formats a raw numeric double value into engineering notation with metric prefixes.
///
/// Scales values greater than 1000 into k, M, or G units, and scales values
/// smaller than 0.001 into m or μ units. Falls back to three decimal places if no
/// matching scaling conditions are met.
String formatEngineering(double? value) {
  if (value == null) return '';
  
  // Handle absolute values for scaling check, while preserving the original sign
  final double absVal = value.abs();

  if (absVal >= 1e9) {
    return '${(value / 1e9).toStringAsFixed(3)} G';
  } else if (absVal >= 1e6) {
    return '${(value / 1e6).toStringAsFixed(3)} M';
  } else if (absVal >= 1e3) {
    return '${(value / 1e3).toStringAsFixed(3)} k';
  } else if (absVal > 0 && absVal <= 0.001) {
    // If it is smaller than or equal to 0.001 but big enough to be micro scale
    if (absVal <= 1e-4) {
      return '${(value * 1e6).toStringAsFixed(3)} μ';
    }
    return '${(value * 1e3).toStringAsFixed(3)} m';
  }
  
  // Standard fallback format for values between 0.001 and 1000
  return value.toStringAsFixed(3);
}