//import 'package:camera_ohm/main.dart';
import 'dart:math';
import '../function_files/color_label.dart';

String reString = "Select Colors";

void calculateR() {
  String defaultString = "Inappropriate colors";
  
  ColorLabel? c0 = selectedColor.elementAtOrNull(0);
  ColorLabel? c1 = selectedColor.elementAtOrNull(1);
  ColorLabel? c2 = selectedColor.elementAtOrNull(2);
  ColorLabel? c3 = selectedColor.elementAtOrNull(3);
  ColorLabel? c4 = selectedColor.elementAtOrNull(4);

  // Basic null + range validation
  if (c0 == null || c1 == null || c2 == null) {
    reString = defaultString;
    return;
  }

  if (c0.index == 0 || c0.index > 9 || c1.index > 9 || c2.index > 9) {
    reString = defaultString;
    return;
  }

  double totalR = c0.index * 10 + c1.index.toDouble();
  int multiplier = c2.index;
  int decimals = 1;

  // Optional 4th band
  if (c3 != null && c3.label != 'None') {
    totalR = totalR * 10 + c2.index;
    multiplier = c3.index;
    decimals = 2;
  }

  // Apply multiplier
  totalR = _applyMultiplier(totalR, multiplier, defaultString);
  if (totalR == -1) return;

  // Format result
  String result = _formatResistance(totalR, decimals);

  // Tolerance
  String tolerance = _getTolerance(c4);

  reString = "$result $tolerance";
}

double _applyMultiplier(double value, int multiplier, String defaultString) {
  if (multiplier <= 9) return value * pow(10, multiplier);
  if (multiplier == 10) return value * pow(10, -1);
  if (multiplier == 11) return value * pow(10, -2);

  reString = defaultString;
  return -1;
}

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

