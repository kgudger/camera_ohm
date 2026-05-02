import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:camera_ohm/main.dart';
import 'dart:math';
import 'package:logger/logger.dart';

//import 'package:flex_color_picker/flex_color_picker.dart';

//import 'package:opencv_dart/opencv.dart' as cv;
//import 'package:camera_ohm/function_files/camera_page.dart';

img.Image cropCenter(img.Image image) {
  final int w = image.width;
  final int h = image.height;

  final int cropW = (w * 0.4).toInt();
  final int cropH = (h * 0.6).toInt();

  return img.copyCrop(
    image,
    x: (w - cropW) ~/ 2,
    y: (h - cropH) ~/ 2,
    width: cropW,
    height: cropH,
  );
}

img.Image normalizeWhiteBalance(img.Image image) {
  int totalR = 0, totalG = 0, totalB = 0;
  int count = image.width * image.height;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      totalR += p.r.toInt();
      totalG += p.g.toInt();
      totalB += p.b.toInt();
    }
  }

  final avgR = totalR / count;
  final avgG = totalG / count;
  final avgB = totalB / count;

  final gray = (avgR + avgG + avgB) / 3;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);

      int r = (p.r * gray / avgR).clamp(0, 255).toInt();
      int g = (p.g * gray / avgG).clamp(0, 255).toInt();
      int b = (p.b * gray / avgB).clamp(0, 255).toInt();

      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return image;
}

void printCenter(img.Image image) {
  final int w = image.width;
  final int h = image.height;
  final int centerPix = (w ~/ 2);
  int centerY = h ~/ 2 ;

  for (int y = centerY - 3; y < centerY + 3; y++ ){
    print(image.getPixel(centerPix, y));
  }  
}


Future<List<ColorLabel?>> getResistorColors(XFile capturedImage) async {
  var logger = Logger();

  logger.d(capturedImage.path);

  // 1. Load the image bytes
  final bytes = await capturedImage.readAsBytes();
  img.Image? decodedImage = img.decodeImage(bytes);

  if (decodedImage == null) return [ColorLabel.none];
  
  printCenter(decodedImage);
  decodedImage = cropCenter(decodedImage); // Crop to most important part
    // 2. White balance correction
  decodedImage = normalizeWhiteBalance(decodedImage);
  printCenter(decodedImage);

  // 3. Contrast boost
  img.adjustColor(decodedImage, contrast: 1.5);
  printCenter(decodedImage);

  // The model would return bounding boxes for the bands.
  List<ColorLabel> detectedBands = await _analyzeImageForBands(decodedImage,capturedImage);
  List<ColorLabel> returnedBands = detectedBands.asMap().entries
    .where((entry) => entry.key % 2 != 0)
    .map((entry) => entry.value)
    .take(6)
    .toList();

  logger.d(returnedBands); // Prints a pretty-formatted list
  return returnedBands;
}

Future<List<ColorLabel>> _analyzeImageForBands(img.Image image, XFile capturedImage) async {
/*  final imgcv = cv.imread(capturedImage.path);
// 2. Convert to HSV color space (better for color detection)
  final hsv = cv.cvtColor(imgcv, cv.COLOR_BGR2HSV);

  // 3. Define the range for a specific color (e.g., Red)
  // Note: Red often wraps around the 0-180 scale in HSV
//  final lowerRed = cv.Scalar(0, 100, 100, 0);
//  final upperRed = cv.Scalar(10, 255, 255, 0);

  final mat1 = cv.Mat.zeros(100, 100, cv.MatType.CV_8UC3);
  final mat2 = cv.Mat.zeros(100, 100, cv.MatType.CV_8UC3);
  final lowercolor = cv.Scalar(0, 100,100, 0); // Red
  final uppercolor = cv.Scalar(10, 255, 255, 0); // Red
  
  // Fill the matrix with the scalar value
  mat1.setTo(lowercolor);
  mat2.setTo(uppercolor);

  // 4. Create a mask to isolate Red pixels
  final mask = cv.inRange(hsv, mat1, mat2);

  // 5. Find contours of the color bands
  final (contours, _) = cv.findContours(mask, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

  for (int i = 0; i < contours.length; i++) {
    final contour = contours[i]; // Access individual contour
//for (var contour in contours.iter) {
    final area = cv.contourArea(contour);
    if (area > 100) { // Filter out small noise
      final rect = cv.boundingRect(contour);
      // 'rect' now contains the x,y coordinates of a red band!
      cv.rectangle(imgcv, rect, cv.Scalar(0, 255, 0, 0), thickness: 2);
    }
  }
  cv.imwrite("result.jpg", imgcv);*/
  // Logic Flow:
  // A. Detect the Resistor body (usually tan or blue).
  // B. Scan the horizontal axis for sharp color changes (the bands).
  // C. Map the RGB values of those bands to the closest ColorLabel.
  
  // Example dummy return representing a 4-band resistor: 
  // [Brown, Black, Red, Gold] -> 1k Ohm
  final List<ColorLabel> colorLabel = [];
  final List<img.Pixel> centerPixels = getCenterPixels(image);
  //int i = 0;
  Color oldColor = Colors.black;
  var indexOld = 0;
  List<int> listR = [];
  List<int> listG = [];
  List<int> listB = [];
  int pixelr;
  int pixelg;
  int pixelb;

  for (var (index, pixel) in centerPixels.indexed) {
    pixelr = pixel.r.toInt();
    pixelg = pixel.g.toInt();
    pixelb = pixel.b.toInt();
  
    listR.add(pixelr);
    listB.add(pixelb);
    listG.add(pixelg);

    Color flutterColor = Color.fromARGB(
    pixel.a.toInt(), 
    pixelr, 
    pixelg, 
    pixelb);

    double distance = getColorDistance(oldColor, flutterColor);
//    print("distance = $distance");
    if ( distance > 20 ) {
      if ((index - 2) > indexOld) {
        pixelr = calculateMedian(listR);
        pixelg = calculateMedian(listG);
        pixelb = calculateMedian(listB);
        Color medianColor = Color.fromARGB(
          255, 
          pixelr, 
          pixelg, 
          pixelb);
        indexOld = index;                
        colorLabel.add(getClosestColor(medianColor, candidates));
        listR.clear();
        listB.clear();
        listG.clear();
      }  // don't do this if they're too close
    }
    oldColor = flutterColor;
  }
  return colorLabel;
  /*[
    ColorLabel.brown,
    ColorLabel.black,
    ColorLabel.red,
    ColorLabel.none,
    ColorLabel.gold,
  ];*/
}
List<img.Pixel> getCenterPixels(img.Image photo) {
  // 640 / 2 = 320 (the center column)
  int centerX = photo.width;
  int ytop = photo.height ~/ 4; // 1/4 of the way down
  int ybottom = ytop * 3;       // 3/4 of the way down
  centerX = centerX ~/ 2 ; 
  List<img.Pixel> columnPixels = [];

  for (int y = ytop; y < ybottom; y++) {
    // Grabs the pixel at the center X coordinate for every Y row
//    print(photo.getPixel(centerX, y));
    columnPixels.add(photo.getPixel(centerX, y));
  }
  return columnPixels;
  // Now columnPixels contains all 480 pixels from the center line
}
double getColorDistance(Color c1, Color c2) {
  return sqrt(
    pow(c1.r * 255.0.round().clamp(0, 255) - c2.r * 255.0.round().clamp(0, 255), 2) +
    pow(c1.g * 255.0.round().clamp(0, 255) - c2.g * 255.0.round().clamp(0, 255), 2) +
    pow(c1.b * 255.0.round().clamp(0, 255) - c2.b * 255.0.round().clamp(0, 255), 2),
  ).toDouble();
}
ColorLabel getClosestColor(Color target, List<Color> candidates) {
//  Color closestColor = candidates.first;
  double minDistance = double.infinity;
  int lindex = 0;
  ColorLabel colorLabel;

//  for (var color in candidates) {
  for (final (index,  color) in candidates.indexed) {
    // Calculate squared Euclidean distance in RGB space
    // Using squared distance avoids expensive sqrt() calls for comparisons
    double distance = pow(target.r * 255.0.round().clamp(0, 255) - color.r * 255.0.round().clamp(0, 255), 2) +
                      pow(target.g * 255.0.round().clamp(0, 255) - color.g * 255.0.round().clamp(0, 255), 2) +
                      pow(target.b * 255.0.round().clamp(0, 255) - color.b * 255.0.round().clamp(0, 255), 2).toDouble();

    if (distance < minDistance) {
      minDistance = distance;
//      closestColor = color;
      lindex = index;
    }
  }
  colorLabel = ColorLabel.values[lindex];
  return colorLabel;
}

int calculateMedian(List<int> list) {

  if (list.isEmpty) return 0;

  // 2. Sort the sublist (required for median)
  list.sort();

  int middle = list.length ~/ 2;

  // 3. Apply median logic
  if (list.length % 2 == 1) {
    // Odd length: return the middle element
    return list[middle];
  } else {
    // Even length: return average of the two middle elements
    return (list[middle - 1] + list[middle]) ~/ 2;
  }
}

List<Color> candidates = ColorLabel.values.map((e) => e.color).toList(); 

