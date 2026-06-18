import 'package:flutter/material.dart';
import 'dart:math';

class ValuePage extends StatefulWidget {
  const ValuePage({super.key});
  @override
  State<ValuePage> createState() => _ValuePage();
}
class _ValuePage extends State<ValuePage> {
  final TextEditingController _controller = TextEditingController();

  String output1 = '';
  String output2 = '\n';

  void updateOutputs(String input) {
    final (result, standard) = calcColors(input);

    setState(() {
      output1 = result;
      output2 = standard;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resistor Value to Colors'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter Resistor Value',
                border: OutlineInputBorder(),
              ),
              onSubmitted: updateOutputs,
            ),

            const SizedBox(height: 8),
            const Text(
              'Resistor Colors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: TextEditingController(text: output1),
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Closest Standard Resistor Value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: TextEditingController(text: output2),
              readOnly: true,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

(String, String) calcColors(String input) {

  final parsed = parseInput(input); 
  if (parsed == null) {
    return ('', '');
  }
  List<double> rValues = e12;
  final tolerance = parseTolerance(parsed.remainder);
  if (tolerance <= 0.05) {
    rValues = e24;
  }
  final standardSize = roundToSeries(parsed.number, rValues);
  final colors = computeBands(parsed);
  final newParsed = ParsedInput(standardSize,parsed.text,parsed.remainder);
  final standardColors = computeBands(newParsed);
  String result = colors.join(', ');
  String result1 =   '''Requested: ${formatOhms(parsed)},
Nearest: ${formatOhms(newParsed)}''';
  String result2 = standardColors.join(', ');
  String resultAll = '''$result1
$result2''';
  return (result, resultAll);
}

List<String> computeBands(ParsedInput p) {
  final r = parseResistor(p);

  final bands = <String>[];

  // 1. significant digits
  bands.addAll(digitsToColors(r.digits));

  // 2. multiplier
  bands.add(exponentToColor(r.exponent));

  // 3. tolerance
  bands.add(toleranceToColor(r.tolerance));

  return bands;
}

class ParsedInput {
  final double number;
  final String? text;
  final String? remainder;

  ParsedInput(
    this.number,
    this.text,
    this.remainder,
  );
}

ParsedInput? parseInput(String input) {
  final numberMatch =
      RegExp(r'^\s*(\d+(?:\.\d+)?)').firstMatch(input);

  if (numberMatch == null) {
    return null;
  }

  final number = roundToSigDigits(
    double.parse(numberMatch.group(1)!),
    3,
);
  String remaining =
      input.substring(numberMatch.end).trim();

  String? text;
  String? remainder;

  if (remaining.isNotEmpty) {
    final tokens = remaining.split(RegExp(r'\s+'));

    if (tokens.isNotEmpty) {
      // First token after the number
      final first = tokens[0];

      // Unit/multiplier?
      if (RegExp(
        r'^(k|K|m|M|g|G|ohm|ohms|Ω|r|R)$',
      ).hasMatch(first)) {
        text = first;

        if (tokens.length > 1) {
          remainder =
              tokens.sublist(1).join(' ');
        }
      } else {
        // No unit found
        remainder = remaining;
      }
    }
  }

  return ParsedInput(
    number,
    text,
    remainder,
  );
}

double roundToSigDigits(
  double value,
  int digits,
) {
  return double.parse(
    value.toStringAsPrecision(digits),
  );
}

List<String> digitsToColors(List<int> digits) {
  return digits
      .map((d) => digitColors[d])
      .toList();
}

double unitMultiplier(String? unit) {
  if (unit == null) return 1.0;

  final u = unit.toLowerCase();

  if (u.contains('g')) return 1e9;
  if (u.contains('m')) return 1e6;
  if (u.contains('k')) return 1e3;
  if (u.contains('kω')) return 1e3;
  if (u.contains('mω')) return 1e6;
  if (u.contains('gω')) return 1e9;
  if (u.contains('ohm') || u.contains('ω')) return 1.0;

  return 1.0;
}

double parseTolerance(String? text) {
  if (text == null) return 0.20; // default 20%

  final t = text.toLowerCase();

  if (t.contains('1%')) return 0.01;
  if (t.contains('2%')) return 0.02;
  if (t.contains('5%')) return 0.05;
  if (t.contains('10%')) return 0.10;

  return 0.20;
}

class ResistorValue {
  final List<int> digits;
  final int exponent;
  final double tolerance;

  ResistorValue(this.digits, this.exponent, this.tolerance);
}

ResistorValue parseResistor(ParsedInput p) {
  final unitMult = unitMultiplier(p.text);
  final tolerance = parseTolerance(p.remainder);

  double value = p.number * unitMult;

  // Convert to scientific form: digits × 10^exp
  int exponent = 0;

  while (value >= 100) {
    value /= 10;
    exponent++;
  }

  while (value < 10 && value > 0) {
    value *= 10;
    exponent--;
  }

  final digits = extractDigits(value);

  return ResistorValue(digits, exponent, tolerance);
}

String normalizeDouble(double value) {
  String s = value.toString();

  // handle scientific notation
  if (s.contains('e')) {
    s = value.toStringAsFixed(10);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }

  return s;
}

List<int> extractDigits(double value) {
  final s = normalize(value);

  return s
      .replaceAll('.', '')
      .split('')
      .map(int.parse)
      .toList();
}

String normalize(double value) {
  String s = value.toString();

  // avoid scientific notation
  if (s.contains('e')) {
    s = value.toStringAsFixed(12);
  }

  // trim trailing zeros
  s = s.replaceFirst(RegExp(r'\.?0+$'), '');

  return s;
}

const digitColors = <String>[
  "Black",   // 0
  "Brown",   // 1
  "Red",     // 2
  "Orange",  // 3
  "Yellow",  // 4
  "Green",   // 5
  "Blue",    // 6
  "Violet",  // 7
  "Gray",    // 8
  "White",   // 9
];

String exponentToColor(int exp) {
  const map = {
    -2: "Silver",
    -1: "Gold",
     0: "Black",
     1: "Brown",
     2: "Red",
     3: "Orange",
     4: "Yellow",
     5: "Green",
     6: "Blue",
     7: "Violet",
     8: "Gray",
     9: "White",
  };
  return map[exp] ?? "Black";
}

String toleranceToColor(double t) {
  if (t <= 0.01) return "Brown";
  if (t <= 0.02) return "Red";
  if (t <= 0.05) return "Gold";
  if (t <= 0.10) return "Silver";

  return "";
}


double roundToSeries(
  double value,
  List<double> series,
) {
  if (value <= 0) return value;

  // Normalize to 1 ≤ mantissa < 10
  int exponent = 0;
  double mantissa = value;

  while (mantissa >= 10) {
    mantissa /= 10;
    exponent++;
  }

  while (mantissa < 1) {
    mantissa *= 10;
    exponent--;
  }

  // Find nearest preferred value
  double best = series.first;
  double bestError =
      (mantissa - best).abs();

  for (final candidate in series) {
    final error =
        (mantissa - candidate).abs();

    if (error < bestError) {
      best = candidate;
      bestError = error;
    }
  }
  final bestFinal = best * pow(10, exponent);
  final bestRound = double.parse(
    bestFinal.toStringAsFixed(6),);
  return (bestRound);
}
/*
String nearestSeriesString(
  ParsedInput p,
  List<double> series,
) {
  final unitMultiplier = switch (p.text?.toLowerCase()) {
    'k' => 1e3,
    'm' => 1e6,
    _ => 1.0,
  };

  final actualValue = p.number * unitMultiplier;

  final result = roundToSeries(
    actualValue,
    series,
  );

  return 'Requested: ${formatOhms(result.requestedValue)}, '
         'Nearest: ${formatOhms(result.closestValue)}';
}
*/
String formatOhms(ParsedInput p) {
  if (p.number >= 1e9) {
    return '${(p.number / 1e9).toStringAsFixed(2)}  ${p.text ?? ''} GΩ ${p.remainder ?? ''}';
  }

  if (p.number >= 1e6) {
    return '${(p.number / 1e6).toStringAsFixed(2)}  ${p.text ?? ''} MΩ ${p.remainder ?? ''}';
  }

  if (p.number >= 1e3) {
    return '${(p.number / 1e3).toStringAsFixed(2)}  ${p.text ?? ''} kΩ ${p.remainder ?? ''}';
  }

  return '${p.number.toStringAsFixed(2)} ${p.text ?? ''} Ω ${p.remainder ?? ''}';
}

/* Standard Resistor Values*/
const e12 = [ // 10% tolerance
  1.0,
  1.2,
  1.5,
  1.8,
  2.2,
  2.7,
  3.3,
  3.9,
  4.7,
  5.6,
  6.8,
  8.2,
];
const e24 = [ // 5% tolerance (or less)
  1.0, 1.1, 1.2, 1.3, 1.5, 1.6, 1.8, 2.0,
  2.2, 2.4, 2.7, 3.0, 3.3, 3.6, 3.9, 4.3,
  4.7, 5.1, 5.6, 6.2, 6.8, 7.5, 8.2, 9.1,
];

