import 'package:flutter/material.dart';
import 'dart:math';

/// A page that converts user-entered resistor values into their corresponding color bands.
/// 
/// This widget provides a user interface with an input field for the resistor value,
/// and displays both the calculated color bands and the closest standard EIA resistor value.
class ValuePage extends StatefulWidget {
  const ValuePage({super.key});
  @override
  State<ValuePage> createState() => _ValuePage();
}
/// The state for [ValuePage] that handles user input and UI updates.
class _ValuePage extends State<ValuePage> {
 // Controller to manage the lifecycle of the resistor value input text field.
   final TextEditingController _controller = TextEditingController();

  String output1 = '';
  String output2 = '\n';

  /// Updates the displayed outputs based on the provided [input] string.
  ///
  /// This method invokes the [calcColors] logic to parse the text, retrieves a
  /// tuple containing the parsed color bands and standard values, and calls
  /// [setState] to refresh the user interface.
   void updateOutputs(String input) {
    final (result, standard) = calcColors(input);

    setState(() {
      output1 = result;
      output2 = standard;
    });
  }
  // Clean up the text controller when the widget is permanently removed 
  // from the widget tree to avoid memory leaks.
   @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
// returns the subpage for entering resistor values 
// and showing their colors and the standard resistor value and colors
    return Scaffold(
      appBar: AppBar( // title
        title: const Text('Resistor Value to Colors'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField( // title of the input text box
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter Resistor Value',
                border: OutlineInputBorder(),
              ),
              onSubmitted: updateOutputs, // calls updateOutputs on enter
            ),

            const SizedBox(height: 8),
            const Text( // title of 1st output text box
              'Resistor Colors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Read-only field displaying the calculated color bands.
            TextField(
              controller: TextEditingController(text: output1),
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            const Text( // title of the closest standard resistor value and colors
              'Closest Standard Resistor Value', 
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Read-only field displaying the closest matching standard industry value.
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

/// Calculates both the requested resistor color bands and the nearest standard series equivalent.
///
/// String input is [input] with requested resistor value and tolerance
/// Returns a tuple containing:
/// 1. A comma-separated string representation of the requested color bands.
/// 2. A string displaying formatted text comparing requested vs. standard values.
(String, String) calcColors(String input) {

  final parsed = parseInput(input); 
  if (parsed == null) {
    return ('', '');
  } // parsed is a class 'ParsedInput'with a number, text and a remainder

  // 2. Select EIA series (E12 or E24) based on custom tolerance threshold
  List<double> rValues = e12;
  final tolerance = parseTolerance(parsed.remainder);
  if (tolerance <= 0.05) { // the remainder has the actual tolerance value
    rValues = e24; // if less than 5% use the e24 entries
  }
  // 3. Determine the closest commercially available preferred value
  final standardSize = roundToSeries(parsed.number, rValues); // returns a ParsedInput
  // 4. Compute original input color sequence
  final colors = computeBands(parsed);
  // 5. Build and compute nearest industry standard replacement value sequence
  final newParsed = ParsedInput(standardSize,parsed.text,parsed.remainder);
  String result = colors.where((e) => e.isNotEmpty).join(', ');
  String result1 =   '''Requested: ${formatOhms(parsed)},
Nearest: ${formatOhms(newParsed)}'''; // includes newline in output
  // 6. Check if requested input perfectly matches the commercial preferred standard
  if (parsed.number == standardSize) {
    // If identical, output only the requested summary string and omit the matching sequence
    return (result, result1);
  }
// compute standard color sequence
  final standardColors = computeBands(newParsed);
  String result2 = standardColors.where((e) => e.isNotEmpty).join(', ');
  String resultAll = '''$result1
$result2''';
  return (result, resultAll); // 1st text box, 2nd text bos
} // requested value and nearest standard value.

/// Computes the complete electronic color code band array for a given [p].
///
/// Iteratively appends standard identifier bands including primary significant
/// digit sequences, multiplier shifts, and strict tolerance markers.
List<String> computeBands(ParsedInput p) {
// Normalizes raw tokenized input models into structured [ResistorValue] instances.
// ResistorValue is class of List<int> digits and int exponent.
  final r = parseResistor(p);

  final bands = <String>[];

  // // 1. Convert digits to colors
  bands.addAll(digitsToColors(r.digits));

  // 2. multiplier
  bands.add(exponentToColor(r.exponent));

  // 3. tolerance
  bands.add(toleranceToColor(r.tolerance));

  return bands;
}

/// Holds structurally isolated and tokenized parts of an original user raw input string.
class ParsedInput {
  final double number; // raw number
  final String? text;  // possible multiplier or ohms or tolerance
  final String? remainder; // tolerance?

  /// Creates a raw token container instance of [ParsedInput].
  ParsedInput(
    this.number,
    this.text,
    this.remainder,
  );
}

/// Parses raw alphanumeric user inputs into a structured [ParsedInput] object.
///
/// Returns `null` if a structural numerical sequence cannot be safely matched or parsed.
ParsedInput? parseInput(String input) {
  // Capture leading integer or floating-point segments
  final numberMatch =
      RegExp(r'^\s*(\d+(?:\.\d+)?)').firstMatch(input);

  if (numberMatch == null) {
    return null;
  }

  // Enforce consistent 3 significant figure truncation for accurate matching
  final number = roundToSigDigits(
    double.parse(numberMatch.group(1)!),
    3, // 3 digits
  );
  String remaining =
      input.substring(numberMatch.end).trim();

  String? text;
  String? remainder;

  // Process residual tokens following the parsed numeric values
  if (remaining.isNotEmpty) {
    final tokens = remaining.split(RegExp(r'\s+'));

    if (tokens.isNotEmpty) {
      // First token after the number
      final first = tokens[0];

      // Unit/multiplier?
      // Verify if token matches valid multi-lingual engineering ohm metrics
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
        // Fallback context: non-standard unit terms treated as raw secondary descriptors
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

/// Rounds a double [value] to a strict amount of [digits] precision.
double roundToSigDigits(
  double value,
  int digits,
) {
  return double.parse(
    value.toStringAsPrecision(digits),
  );
}

/// Maps integer values to standardized electronic color band strings.
List<String> digitsToColors(List<int> digits) {
  return digits
      .map((d) => digitColors[d])
      .toList(); // const digitColors = <String>[] where index = value
}

/// Evaluates SI standard scale metric string tokens into numerical scale factor doubles.
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

/// Extract component tolerance percentage from [text] tokens.
///
/// Defaults to standard baseline broad 20% limits (`0.20`) if terms aren't recognized.
double parseTolerance(String? text) {
  if (text == null) return 0.20; // default 20%

  final t = text.toLowerCase();

  if (t.contains('1%')) return 0.01;
  if (t.contains('2%')) return 0.02;
  if (t.contains('5%')) return 0.05;
  if (t.contains('10%')) return 0.10;

  return 0.20;
}

/// Encapsulates normalized mathematical base traits of an electronic resistor.
class ResistorValue {
  final List<int> digits; // all digits of initial double
  final int exponent;     // integer exponent power of 10
  final double tolerance; // tolerance percent (see parseTolerance)

  ResistorValue(this.digits, this.exponent, this.tolerance);
}

/// Normalizes raw tokenized input into [ResistorValue] instances.
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

  // Converts mantissa into array of integers.
  final digits = extractDigits(value);

  return ResistorValue(digits, exponent, tolerance);
}

/// Converts mantissa into array segments of integers.
List<int> extractDigits(double value) {
  // Sanitizes numerical strings, scientific notation distortions and trailing zeros.
  final s = normalize(value);

  return s
      .replaceAll('.', '')
      .split('')
      .map(int.parse)
      .toList();
}

/// Sanitizes numerical strings, bypassing scientific notation distortions and trailing zeros.
String normalize(double value) {
  String s = value.toString();

  // avoid scientific notation
  // Flatten default floating-point exponent indicators to literal notation 
  if (s.contains('e')) {
    s = value.toStringAsFixed(12);
  }

  // Strip trailing zeros and decimal point artifacts
  // trim trailing zeros
  s = s.replaceFirst(RegExp(r'\.?0+$'), '');

  return s;
}

/// Direct color code translation mapping array index directly to colors.
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

/// Resolves multipliers into equivalent color band labels.
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

/// Resolves percentage thresholds into component stripe labels.
String toleranceToColor(double t) {
  if (t <= 0.0005) return "Gray";
  if (t <= 0.0025) return "Blue";
  if (t <= 0.005) return "Green";
  if (t <= 0.01) return "Brown";
  if (t <= 0.02) return "Red";
  if (t <= 0.05) return "Gold";
  if (t <= 0.10) return "Silver";

  return "";
}

/// Snaps an ohm [value] to its closest target inside an explicit [series].
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
  // Project mantissa back to base original
  final bestFinal = best * pow(10, exponent);
  final bestRound = double.parse(
    bestFinal.toStringAsFixed(6),); // only 3 digits max
  return (bestRound);
}

/// Formats numeric values into human-readable text strings using SI labels.
String formatOhms(ParsedInput p) {
  // deals with null strings
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
/// EIA E12 standard preferred resistor value steps.
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

/// EIA E24 standard preferred resistor value steps (5% or better).
const e24 = [ // 5% tolerance (or less)
  1.0, 1.1, 1.2, 1.3, 1.5, 1.6, 1.8, 2.0,
  2.2, 2.4, 2.7, 3.0, 3.3, 3.6, 3.9, 4.3,
  4.7, 5.1, 5.6, 6.2, 6.8, 7.5, 8.2, 9.1,
];

