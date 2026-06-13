import 'package:flutter/material.dart';
import '../function_files/color_label.dart';

class ValuePage extends StatefulWidget {
  const ValuePage({super.key});
  @override
  State<ValuePage> createState() => _ValuePage();
}
class _ValuePage extends State<ValuePage> {
  final TextEditingController _controller = TextEditingController();

  String output1 = '';
  String output2 = '';

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
                labelText: 'Enter text',
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
  final colors = computeBands(parsed);
  final digitValues = parsed.number
    .toString()
    .replaceAll('.', '')
    .split('')
    .map(int.parse)
    .toList();
  final p = parseDigits(parsed.number);
//  final colors = digitsToColors(p.digits);
  String result = colors.join(', ');
//  final value = 0.0;
  
  return (result, "");
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
  final regex = RegExp(
    r'^\s*(\d+(?:\.\d+)?)(?:\s*([^\s]+))?(?:\s+(.*))?$',
  );

  final match = regex.firstMatch(input);

  if (match == null) {
    return null;
  }

  return ParsedInput(
    double.parse(match.group(1)!),
    match.group(2),
    match.group(3) ?? '',
  );
}

class ParsedNumber {
  final List<int> digits;
  final int decimalPosition;

  ParsedNumber(this.digits, this.decimalPosition);
}

ParsedNumber parseDigits(double value) {
  final s = value.toString();

  final decimalPosition = s.contains('.')
      ? s.indexOf('.')
      : s.length;

  final digits = s
      .replaceAll('.', '')
      .split('')
      .map(int.parse)
      .toList();

  return ParsedNumber(
    digits,
    decimalPosition,
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

/* Standard Resistor Values*/
const standardValues = <int>[
10,
12,
15,
18,
22,
27,
33,
39,
47,
56,
68,
82,
];


