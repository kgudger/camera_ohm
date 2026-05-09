import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:camera_ohm/main.dart';
import 'dart:math';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

//import 'package:flex_color_picker/flex_color_picker.dart';

//import 'package:opencv_dart/opencv.dart' as cv;
//import 'package:camera_ohm/function_files/camera_page.dart';

img.Image cropCenter(img.Image image) {
  final int w = image.width; // rotated 90 deg, so width is height
  final int h = image.height;

  final int cropW = (w * 0.1).toInt();
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
img.Image blurImage(img.Image image) {
  return img.gaussianBlur(image, radius: 1);
}

List<List<int>> extractPixels(img.Image image) {
  final pixels = <List<int>>[];

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      pixels.add([p.r.toInt(), p.g.toInt(), p.b.toInt()]);
    }
  }

  return pixels;
}

List<List<double>> kMeans(List<List<int>> pixels, int k) {
  final rand = Random();

  // Initialize centroids randomly
  List<List<double>> centroids = List.generate(
    k,
    (_) => pixels[rand.nextInt(pixels.length)]
        .map((e) => e.toDouble())
        .toList(),
  );

  for (int iter = 0; iter < 10; iter++) {
    List<List<List<int>>> clusters =
        List.generate(k, (_) => []);

    // Assign pixels to nearest centroid
    for (var p in pixels) {
      int best = 0;
      double bestDist = double.infinity;

      for (int i = 0; i < k; i++) {
        double dist = pow(p[0] - centroids[i][0], 2) +
            pow(p[1] - centroids[i][1], 2) +
            pow(p[2] - centroids[i][2], 2).toDouble();

        if (dist < bestDist) {
          bestDist = dist;
          best = i;
        }
      }

      clusters[best].add(p);
    }

    // Recompute centroids
    for (int i = 0; i < k; i++) {
      if (clusters[i].isEmpty) continue;

      double r = 0, g = 0, b = 0;

      for (var p in clusters[i]) {
        r += p[0];
        g += p[1];
        b += p[2];
      }

      centroids[i] = [
        r / clusters[i].length,
        g / clusters[i].length,
        b / clusters[i].length,
      ];
    }
  }
  return centroids;
}

Future<void> saveImage(img.Image image, int num) async {
  final pngBytes = img.encodePng(image);
  final Directory? directory = await getDownloadsDirectory();// 
  if (directory != null) {
  //final directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/intermediate_$num.png');
    await file.writeAsBytes(pngBytes);
    print('Image saved to ${file.path}');
  }
}
Future<List<ColorLabel?>> getResistorColors(XFile capturedImage) async {
  var logger = Logger();

  logger.d(capturedImage.path);

  // 1. Load the image bytes
  final bytes = await capturedImage.readAsBytes();
  img.Image? decodedImage = img.decodeImage(bytes);

  if (decodedImage == null) return [ColorLabel.none];
  
//  printCenter(decodedImage);
  decodedImage = cropCenter(decodedImage); // Crop to most important part
  saveImage(decodedImage,0);
    // 2. White balance correction
//  decodedImage = normalizeWhiteBalance(decodedImage);
//  saveImage(decodedImage,1);
//  printCenter(decodedImage);
  // 3. Contrast boost
  /*img.adjustColor(decodedImage, contrast: 1.5);
  printCenter(decodedImage);
*/
  decodedImage = blurImage(decodedImage);
//  printCenter(decodedImage);
  saveImage(decodedImage,2);

  final profile = horizontalProfile(decodedImage); // now it's HSV, not RGB
  saveHSVListToImage(profile, 1, profile.length,0);
/*  final smooth = smoothProfile(profile);
//  saveRgbListToImage(smooth, 1, smooth.length,1);
//  final segments = segmentBands(smooth);
  final segments = segmentBands(profile);
  final averaged = averageBands(segments);*/
  final transitions = transitionProfile(profile);
  final edges = detectEdges(transitions);
  final hsvProfile = averageHsvSegments(profile, edges); // gives small number of hsv values into bands
  final bandColors = hsvProfile.map(classifyColor).toList();
  final filtered = filterBands(bandColors);
  logger.d(filtered);
  final ordered = (filtered);
  logger.d(ordered);
  return ordered;
/*
  List<ColorLabel> detectedBands = await _analyzeImageForBands(decodedImage);

  final pixels = extractPixels(decodedImage);
  final clusters = kMeans(pixels, 9);
  detectedBands = clusters.map(matchColor).toList();
//  return detectedBands;
  List<ColorLabel> returnedBands = detectedBands.asMap().entries
    .where((entry) => entry.key % 2 != 0)
    .map((entry) => entry.value)
    .take(6)
    .toList();

  logger.d(returnedBands); // Prints a pretty-formatted list
  return returnedBands;*/
}

Future<List<ColorLabel>> _analyzeImageForBands(img.Image image) async {

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

ColorLabel matchColor(List<double> c) {
  double bestDist = double.infinity;
  int lindex = 0;
  ColorLabel colorLabel;

//  resistorColors.forEach((name, rgb) {
  for (final (index,  color) in candidates.indexed) {
    double dist = pow(c[0] - color.r * 255.0.round().clamp(0, 255), 2) +
        pow(c[1] - color.g * 255.0.round().clamp(0, 255), 2) +
        pow(c[2] - color.b * 255.0.round().clamp(0, 255), 2).toDouble();

    if (dist < bestDist) {
      bestDist = dist;
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

List<List<double>> horizontalProfile(img.Image image) {
  final profile = <List<double>>[];

  for (int y = 0; y < image.height; y++) {
    double r = 0, g = 0, b = 0;

    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      r += p.r;
      g += p.g;
      b += p.b;
    }

    final hsv = rgbToHsv(r/image.width, g/image.width, b/image.width);
    profile.add(hsv);
  }
  return profile;
}

List<double> transitionProfile(List<List<double>> profile) {
  final transitions = <double>[];

  transitions.add(0);

  for (int i = 1; i < profile.length; i++) {
    final prev = profile[i - 1];
    final curr = profile[i];

    final hueDiff =
          (curr[0] - prev[0]).abs();

    final satDiff =
            (curr[1] - prev[1]).abs();

    final valDiff = 
            (curr[2] - prev[2]).abs(); 

    final wrappedHueDiff =
            hueDiff > 100 ? 360 - hueDiff:hueDiff;
    // Weighted combination
    final score =
            valDiff * 20.0 +
            satDiff * 100.0 +
            wrappedHueDiff * 2.0;

    transitions.add(score);  
  }
  return transitions;
}

List<int> detectEdges(List<double> transitions) {
  const threshold = 15.0;
  const delta = 10 ; // distance across edge to detect for real

  final edges = <int>[];
  edges.add(0); // starting point
  int oldI = 1; // check for distance between edges

  int i = 1;
  for (i; i < transitions.length - 1; i++) {
    if (transitions[i] > threshold &&
        transitions[i] > transitions[i - 1] &&
        transitions[i] > transitions[i + 1]) {
      if ( i > oldI + delta) {
        edges.add(i);
        oldI = i;
      } 
    }
  }
  edges.add(i); // adds last point
  return edges;
}

List<List<double>> extractBandColors(
  List<List<double>> profile,
        List<int> edges,) {
  final colors = <List<double>>[];

  for (int i = 0; i < edges.length - 1; i++) {
    final start = edges[i];
    final end = edges[i + 1];

    double r = 0, g = 0, b = 0;
    int count = 0;

    for (int x = start; x < end; x++) {
      r += profile[x][0];
      g += profile[x][1];
      b += profile[x][2];
      count++;
    }

    colors.add([
      r / count,
      g / count,
      b / count,
    ]);
  }

  return colors;
}

List<List<double>> smoothProfile(List<List<double>> profile) {
  const window = 5;
  final smoothed = <List<double>>[];

  for (int i = 0; i < profile.length; i++) {
    double r = 0, g = 0, b = 0;
    int count = 0;

    for (int j = i - window; j <= i + window; j++) {
      if (j >= 0 && j < profile.length) {
        r += profile[j][0];
        g += profile[j][1];
        b += profile[j][2];
        count++;
      }
    }

    smoothed.add([r / count, g / count, b / count]);
  }

  return smoothed;
}

List<List<List<double>>> segmentBands(List<List<double>> profile) {
//  const threshold = 30.0;
  const threshold = 18.0;

  final bands = <List<List<double>>>[];
  List<List<double>> current = [profile.first];

  for (int i = 1; i < profile.length; i++) {
    final prev = profile[i - 1];
    final curr = profile[i];

    double diff = (curr[0] - prev[0]).abs() +
                  (curr[1] - prev[1]).abs() +
                  (curr[2] - prev[2]).abs();

    if (diff > threshold) {
      bands.add(current);
      current = [];
    }

    current.add(curr);
  }
  bands.add(current);
  return bands;
}

List<List<double>> averageBands(List<List<List<double>>> bands) {
  return bands.map((band) {
    double r = 0, g = 0, b = 0;

    for (var p in band) {
      r += p[0];
      g += p[1];
      b += p[2];
    }

    return [
      r / band.length,
      g / band.length,
      b / band.length,
    ];
  }).toList();
}

List<ColorLabel> filterBands(List<ColorLabel> bands) {
  // Keep largest color changes (heuristic)
  if (bands.length <= 6) return bands;

  return bands.sublist(0, 6); // simple fallback
}

List<ColorLabel> orderedColors(List<List<double>> bands) {
  return bands.map(matchColor).toList();
}

Future<void> saveHSVListToImage(
    List<List<double>> hsvData, int width, int height, int num) async {
  // 1. Create a new image
  final image = img.Image(width: width, height: height);

  // 2. Populate image with RGB values (assuming list is r,g,b,r,g,b...)
  int listIndex = 0;
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      if (listIndex < hsvData.length) {
        double h =hsvData[y*x][0];
        double s =hsvData[y*x][1];
        double v =hsvData[y*x][2];
        final hsvColor = HSVColor.fromAHSV(1.0, h, s, v);
        final Color rgbColor =  hsvColor.toColor();
        image.setPixelRgb(x, y, (rgbColor.r * 255.0).round().clamp(0, 255), 
                                (rgbColor.g * 255.0).round().clamp(0, 255), 
                                (rgbColor.b * 255.0).round().clamp(0, 255));
        listIndex ++;
      }
    }
  }

  // 3. Encode to PNG
  final pngBytes = Uint8List.fromList(img.encodePng(image));
//  final pngBytes = img.encodePng(image);

  // 4. Save to File
  final Directory? directory = await getDownloadsDirectory();// 
  if (directory != null) {
  //final directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/output_$num.png');
    await file.writeAsBytes(pngBytes);
//    print('Image saved to ${file.path}');
  }
}

double luminance(List<double> c) {
  return 0.299 * c[0] +
         0.587 * c[1] +
         0.114 * c[2];
}

double chroma(List<double> c) {
  final maxC = [c[0], c[1], c[2]].reduce((a, b) => a > b ? a : b);
  final minC = [c[0], c[1], c[2]].reduce((a, b) => a < b ? a : b);

  return maxC - minC;
}

List<double> rgbToHsv(double r, double g, double b) {
  r /= 255;
  g /= 255;
  b /= 255;

  double maxC = [r, g, b].reduce((a, b) => a > b ? a : b);
  double minC = [r, g, b].reduce((a, b) => a < b ? a : b);

  double delta = maxC - minC;

  double h = 0;

  if (delta != 0) {
    if (maxC == r) {
      h = 60 * (((g - b) / delta) % 6);
    } else if (maxC == g) {
      h = 60 * (((b - r) / delta) + 2);
    } else {
      h = 60 * (((r - g) / delta) + 4);
    }
  }

    if (h < 0) h += 360;

  double s = maxC == 0 ? 0 : delta / maxC;
  double v = maxC;

  return [h, s, v];
}

double hueDiff(List<double> a, List<double> b) {
  final hsvA = rgbToHsv(a[0], a[1], a[2]);
  final hsvB = rgbToHsv(b[0], b[1], b[2]);

  return (hsvA[0] - hsvB[0]).abs();
}

List<double> averageHsv(List<List<double>> segment) {
  double sumX = 0;
  double sumY = 0;
  double sumS = 0;
  double sumV = 0;

  for (final hsv in segment) {
    final hRad = hsv[0] * pi / 180;

    sumX += cos(hRad);
    sumY += sin(hRad);

    sumS += hsv[1];
    sumV += hsv[2];
  }

  final avgHue =
      atan2(sumY, sumX) * 180 / pi;

  return [
    avgHue < 0 ? avgHue + 360 : avgHue,
    sumS / segment.length,
    sumV / segment.length,
  ];
}

ColorLabel classifyColor(List<double> hsv) {
  final h = hsv[0];
  final s = hsv[1];
  final v = hsv[2];

  if (v < 0.15) return ColorLabel.values[0]; //"black";
  if (s < 0.15 && v > 0.7) return ColorLabel.values[9];//"white";
  if (s < 0.2) return ColorLabel.values[8];// "gray";

  if (h < 15 || h > 345) return ColorLabel.values[2];// "red";
  if (h < 45) return ColorLabel.values[1]; //"brown/orange";
  if (h < 70) return ColorLabel.values[4]; "yellow";
  if (h < 170) return ColorLabel.values[5]; "green";
  if (h < 260) return ColorLabel.values[6]; "blue";
  if (h < 320) return ColorLabel.values[7]; "violet";

  return ColorLabel.values[12]; // none;
}

List<List<double>> averageHsvSegments(
  List<List<double>> profile,
  List<int> edges,
) {
  final segments = <List<double>>[];

  // Need at least 2 edges to form a segment
  if (edges.length < 2) return segments;

  for (int i = 0; i < edges.length - 1; i++) {
    final start = edges[i];
    final end = edges[i + 1];

    if (end <= start) continue;

    double sumX = 0;
    double sumY = 0;

    double sumS = 0;
    double sumV = 0;

    int count = 0;

    // Average HSV values inside this segment
    for (int x = start; x < end; x++) {
      if (x < 0 || x >= profile.length) continue;

      final hsv = profile[x];

      final h = hsv[0];
      final s = hsv[1];
      final v = hsv[2];

      // Convert hue angle -> unit circle
      final radians = h * pi / 180.0;

      sumX += cos(radians);
      sumY += sin(radians);

      sumS += s;
      sumV += v;

      count++;
    }

    if (count == 0) continue;

    // Circular mean for hue
    double avgHue =
        atan2(sumY / count, sumX / count) * 180.0 / pi;

    // Normalize hue to 0–360
    if (avgHue < 0) {
      avgHue += 360;
    }

    final avgS = sumS / count;
    final avgV = sumV / count;

    segments.add([
      avgHue,
      avgS,
      avgV,
    ]);
  }

  return segments;
}
