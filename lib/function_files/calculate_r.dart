//import 'package:camera_ohm/main.dart';
import 'dart:math';
import 'color_label.dart';

/// The globally modified active textual output displaying the formatted resistance payload.
String reString = "Select Colors";

/// Core calculator that decodes electronic color bands into ohms resistance.
///
/// This function reads consecutive entries from [selectedColor] dynamically,
/// handles 4-band vs. 5-band configuration matrix variations, resolves scale
/// multiplier factors, and applies tolerance limits before writing back to [reString].
void calculateR() {
  String defaultString = "Invalid colors";
  
  // 1. Safely pull color band positions
  ColorLabel? c0 = selectedColor.elementAtOrNull(0);
  ColorLabel? c1 = selectedColor.elementAtOrNull(1);
  ColorLabel? c2 = selectedColor.elementAtOrNull(2);
  ColorLabel? c3 = selectedColor.elementAtOrNull(3);
  ColorLabel? c4 = selectedColor.elementAtOrNull(4);

  // 2. Basic null + range validation
  if (c0 == null || c1 == null || c2 == null) {
    reString = defaultString;
    return;
  }

  // 3. Validation: Resistors cannot start with Black (index 0), and digits must be within valid color bounds
  if (c0.index == 0 || c0.index > 9 || c1.index > 9 || c2.index >11) {
    reString = defaultString;
    return;
  }
  // Ensure multiplier bands are correct
  if (c3!.index < 12 && c2.index > 9){
    reString = defaultString;
    return;
  }
  
  // 4. Decode base values: Calculate the base two-digit mantissa sequence
  double totalR = c0.index * 10 + c1.index.toDouble();
  int multiplier = c2.index;
  int decimals = 1;

  // Optional 4th band
  if (c3.label != 'None') {
    totalR = totalR * 10 + c2.index;
    multiplier = c3.index;
    decimals = 2;
  }

  // 5. Apply multiplier
  totalR = _applyMultiplier(totalR, multiplier, defaultString);
  if (totalR == -1) return;

  // Format result
  String result = _formatResistance(totalR, decimals);

  // Tolerance
  String tolerance = _getTolerance(c4);

  // Update state display text
  reString = "$result $tolerance";
}

/// Helper that shifts mantissa values by powers of ten matching electronic code indices.
///
/// Indices 10 and 11 act as fractions by shifting into negative powers (Gold/Silver scaling).
double _applyMultiplier(double value, int multiplier, String defaultString) {
  if (multiplier <= 9) return value * pow(10, multiplier);
  if (multiplier == 10) return value * pow(10, -1);
  if (multiplier == 11) return value * pow(10, -2);
  // default return if not recognized
  reString = defaultString;
  return -1;
}

/// Formats floating-point doubles into human-readable labels (K, M, G).
/// 
/// [value] is resistor value and [decimals] is how many decimal places in returned String
String _formatResistance(double value, int decimals) {
  if (value >= 1e9) {
    return "R = ${(value / 1e9).toStringAsFixed(decimals)} G ohms";
  } else if (value >= 1e6) {
    return "R = ${(value / 1e6).toStringAsFixed(decimals)} M ohms";
  } else if (value >= 1e3) {
    return "R = ${(value / 1e3).toStringAsFixed(decimals)} K ohms";
  } else {
    return "R = ${value.toStringAsFixed(decimals)} ohms";
  }
}

/// Maps tolerance band colors into percentage strings.
String _getTolerance(ColorLabel? band) {
  switch (band?.label) {
    case 'Brown':
      return "1%";
    case 'Red':
      return "2%";
    case 'Green':
      return "0.5%";
    case 'Blue':
      return "0.25%";
    case 'Grey':
      return "0.05%";
    case 'Gold':
      return "5%";
    default:
      return "10%";
  }
}

