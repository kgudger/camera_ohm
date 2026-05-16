import 'package:flutter/material.dart';
import 'dart:collection';

typedef ColorEntry = DropdownMenuEntry<ColorLabel>;

List<ColorLabel?> selectedColor = [ColorLabel.black, ColorLabel.black, ColorLabel.black, ColorLabel.none, ColorLabel.none, ColorLabel.none, ColorLabel.none];
final List<ColorLabel?> defaultColor = [ColorLabel.black, ColorLabel.black, ColorLabel.black, ColorLabel.none, ColorLabel.none, ColorLabel.none, ColorLabel.none];

// DropdownMenuEntry labels and values for the dropdown menu.
enum ColorLabel {
  black('Black',  Colors.black),
  brown('Brown',  Colors.brown),
  red('Red', Colors.red),
  orange('Orange', Colors.orange),
  yellow('Yellow', Colors.yellow),
  green('Green', Colors.green),
  blue('Blue', Colors.blue),
  violet('Violet', Colors.purple),
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

