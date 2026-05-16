import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:camera_ohm/function_files/cam_calc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:camera_ohm/function_files/color_label.dart';
import 'package:flutter_test/flutter_test.dart'; // <-- Change this
//import 'package:camera_ohm/function_files/calculate_r.dart';

void main() {
  test('Run Image Analysis', () async {
    // Adding await ensures the test runner waits for the process to complete
    await analyzeImage(); 
  });
}

Future<void> analyzeImage() async {
  var logger = Logger();
  // 1. Use await to get the value out of the Future
  // 2. Use '?' or 'Directory?' because the result can be null
/*  final Directory? directory = await getDownloadsDirectory();

  if (directory != null) {
    print("Downloads path: ${directory.path}");
  } else {
    print("Could not find the downloads directory.");
    return;
  }
  final File file = File('${directory.path}/intermediate_0.png');*/
  final File file = File('intermediate_0.png');
  final bytes = await file.readAsBytes();
  final XFile xFile = XFile(file.path);

  img.Image? decodedImage = img.decodeImage(bytes);

  if (decodedImage != null) {
    print('Image decoded! Resolution: ${decodedImage.width}x${decodedImage.height}');
  }
  List<ColorLabel?> selectedColor;
  selectedColor = await getResistorColors(xFile);
  logger.d(selectedColor);
}

// DropdownMenuEntry labels and values for the dropdown menu.
/*enum ColorLabel {
  black('Black',  Colors.black),
  brown('Brown',  Colors.brown),
  red('Red', Colors.red),
  orange('Orange', Colors.orange),
  yellow('Yellow', Colors.yellow),
  green('Green', Colors.green),
  blue('Blue', Colors.blue),
  pink('Violet', Colors.purple),
  grey('Grey', Colors.grey),
  white('White', Colors.white),
  gold('Gold', Colors.amber),
  silver('Silver', Color.fromARGB(0xFF, 0xC0, 0xC0, 0xC0)),
  none('None', Colors.black);

  const ColorLabel(this.label, this.color);
  final String label;
  final Color color;

  static final List<ColorEntry> entries = UnmodifiableListView<ColorEntry>(
    values.map<ColorEntry>(
      (ColorLabel color) => ColorEntry(
        value: color,
        label: color.label,
        enabled: color.label != 'Indigo',
        style: MenuItemButton.styleFrom(foregroundColor: color.color),
      ),
    ),
  );
}
*/
