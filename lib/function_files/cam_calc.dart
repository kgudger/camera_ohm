import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
//import 'package:camera_ohm/main.dart';
import 'dart:math';
import 'package:logger/logger.dart';
//import 'package:opencv_dart/opencv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
//import 'dart:typed_data';
import 'color_label.dart';
// need math package.

Future<(List<ColorLabel?>, List<int>, List<String>)> getResistorColors(XFile capturedImage) async {
  var logger = Logger();

  logger.d(capturedImage.path);

  // 1. Load the image bytes
  final bytes = await capturedImage.readAsBytes();
  img.Image? decodedImage = img.decodeImage(bytes);

  if (decodedImage == null) return ([ColorLabel.none], <int>[],["none"]);//return ([ColorLabel.none],List<int>);
  saveImage(decodedImage, 0);
  decodedImage = cropCenter(decodedImage); // Crop to most important part
  saveImage(decodedImage,1);
    // 2. White balance correction
  decodedImage = normalizeWhiteBalance(decodedImage);
  saveImage(decodedImage,2);
  
  //decodedImage = blurImage(decodedImage); // no blur
  //saveImage(decodedImage,3);

  final (hsvprofile, rgbProfile, hsv2Profile) = horizontalProfile(decodedImage); 
    // now it's HSV and RGB
//  saveHSVListToImage(hsvprofile, 1, hsvprofile.length,0);
  saveImage(rgbProfile,3);
//  final transitions = transitionProfile(hsvprofile); // profile is HSV
//  final transitions2 = transitionProfile(hsv2Profile); // profile is HSV
//  final edges = detectEdges(transitions);
  final smoothed = smoothProfile(hsv2Profile);
  final edges = segmentRegions(smoothed); // find regions instead of edges
  logger.d("Edges = ${edges.length}");
  // merge small regions here?
//  final edges2 = detectEdges(transitions2);
  final (profileHsv, mids) = averageHsvSegments(hsv2Profile, edges); // new regions instead
  logger.d("Average == ${profileHsv.length}");
//  final profileHsv2 = mergeRegions(profileHsv);
//  logger.d("Average2 == ${profileHsv2.length}");
  final bandColorsHsv = profileHsv.map(classifyColor).toList(); // list of ColorLabels
//  logger.d("2nd");
//  final bandColorsHsv2 = profileHsv2.map(classifyColor).toList();
  final bandColorsHsv2 = profileHsv.map(classifyKnn).toList();
  logger.d("hsv = $bandColorsHsv");
  logger.d("hsv2 = $bandColorsHsv2");
  List<String> colorNames = bandColorsHsv2.map((color) => color.name).toList();
  logger.d("color names = $colorNames");
//  logger.d(bandColors);
  final filtered2 = filterBands(bandColorsHsv2);
  logger.d("new filter = $filtered2");
  final filtered = filterBands(bandColorsHsv);
  logger.d(filtered);

  final ordered = (filtered);
  return (ordered, mids, colorNames);
}

List<Color> candidates = ColorLabel.values.map((e) => e.color).toList(); 

img.Image cropCenter(img.Image image) {
  final int w = image.width; // rotated 90 deg, so width is height
  final int h = image.height;

  final int cropW = (w * 0.05).toInt();
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
  final img.Image rgbImage = img.Image(
    width: image.width,
    height: image.height,
    numChannels: image.numChannels, // Match the color channels (e.g., RGB or RGBA)
  ); // new image to store the results in

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

      rgbImage.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  return rgbImage;
}

img.Image blurImage(img.Image image) {
  return img.gaussianBlur(image, radius: 1);
}

Future<void> saveImage(img.Image image, int num) async {
  final pngBytes = img.encodePng(image);
  final Directory? directory = await getDownloadsDirectory();// 
  if (directory != null) {
  //final directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/intermediate_$num.png');
    await file.writeAsBytes(pngBytes);
//    print('Image saved to ${file.path}');
  }
}

(List<List<double>> hsvprofile, img.Image rgbprofile, List<List<double>> hsv2Profile) horizontalProfile(img.Image image) {
  final hsvProfile = <List<double>>[];
  final hsv2Profile = <List<double>>[];
//  final rgbProfile = <List<double>>[];
  final img.Image rgbProfile = img.Image(
    width: image.width,
    height: image.height,
    numChannels: image.numChannels, // Match the color channels (e.g., RGB or RGBA)
  );

  for (int y = 0; y < image.height; y++) {
    double r = 0, g = 0, b = 0;
    List<double> listR = [];
    List<double> listG = [];
    List<double> listB = [];
    List<double> listH = [];
    List<double> listS = [];
    List<double> listV = [];
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final hsv = rgbToHsv(p.r.toDouble(), p.g.toDouble(), p.b.toDouble()); // move rgbToHsv for each pixel here
      listH.add(hsv[0]);
      listS.add(hsv[1]);
      listV.add(hsv[2]);
      r += p.r;
      g += p.g;
      b += p.b;
      listR.add(p.r.toDouble());
      listG.add(p.g.toDouble());
      listB.add(p.b.toDouble());
    }

    final hsv = rgbToHsv(r/image.width, g/image.width, b/image.width);
    hsvProfile.add(hsv);
    hsv2Profile.add([calculateMedian(listH),
                    calculateMedian(listS),
                    calculateMedian(listV)]);

//    final rgb = [r/image.width, g/image.width, b/image.width];
    rgbProfile.setPixelRgba(0, y, r/image.width, 
              g/image.width, b/image.width, 255);
  }
  return (hsvProfile, rgbProfile, hsv2Profile);
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
/*    final score =
            valDiff * 20.0 +
            satDiff * 100.0 +
            wrappedHueDiff * 2.0;
*/
    final score = (wrappedHueDiff * 0.6) + (satDiff * 0.3) + (valDiff * 0.1);
    transitions.add(score);  
  }
  return transitions;
}

List<int> detectEdges(List<double> transitions) {
  const threshold = 0.20; // was 100.0;
  const windowSize = 5; // how many pixels wide transition zone
//  const delta = 15 ; // distance across edge to detect for real

  final edges = <int>[0]; // starting point
  int lastEdge = 0;
//  int oldI = 1; // check for distance between edges
/*
  int i = 1;
  for (i; i < transitions.length - 1; i++) {
    if (transitions[i] > threshold &&
        transitions[i] > transitions[i - 1] &&
        transitions[i] > transitions[i + 1]) {
      if ( i > oldI + delta) {
        edges.add(i);
        final iDelta = i - oldI;
        final deltaThresh = transitions[i];
        print("idelta = $iDelta, threshold = $deltaThresh");
        oldI = i;
      } 
    }
  }
  edges.add(i); // adds last point*/
  for (int i = windowSize; i < transitions.length - windowSize; i++) {
    // Human Vision Check: Is the average transition value in this local window 
    // significantly higher than the baseline noise?
    double localAverage = 0.0;
    for (int w = -windowSize; w <= windowSize; w++) {
      localAverage += transitions[i + w];
    }
    localAverage /= (windowSize * 2 + 1);

    if (localAverage > threshold && (i - lastEdge) > 15) {
      // Find the exact local peak within this window to pin the edge precisely
      int peakIndex = i;
      double maxVal = transitions[i];
      for(int w = -windowSize; w <= windowSize; w++) {
        if(transitions[i + w] > maxVal) {
          maxVal = transitions[i + w];
          peakIndex = i + w;
        }
      }
      
      edges.add(peakIndex);
      lastEdge = peakIndex;
      i += windowSize; // Skip past the rest of this transition zone
    }
  }
  
  edges.add(transitions.length - 1);
  return edges;
}

double hueDistance(double h1, double h2) {
  final d = (h1 - h2).abs();
  return d > 180 ? 360 - d : d;
}

List<int> segmentRegions(List<List<double>> profile) {
 final edges = <int>[0];

 var current = profile[0];

 for (int i = 1; i < profile.length; i++) {
   final next = profile[i];

   final dh = hueDistance(current[0], next[0]) / 180.0;
   final ds = (current[1] - next[1]).abs();
   final dv = (current[2] - next[2]).abs();

   final distance =
       dh * 3.0 +
       ds * 2.0 +
       dv;

   // Region changed enough
   if (distance > 0.35) { // initially 0.25
     edges.add(i);
     current = next;
   } else {
     // Slowly adapt region mean
     current = [
       (current[0] * 0.9 + next[0] * 0.1),
       (current[1] * 0.9 + next[1] * 0.1),
       (current[2] * 0.9 + next[2] * 0.1),
     ];
   }
 }

 edges.add(profile.length - 1);

 return edges;
}

final samples = <ColorSample>[
  ColorSample(210.93769425249954, 0.27093328483603346, 0.6890883639214002, ColorLabel.values[0]), // black
  ColorSample(217.1657010302195, 0.3154980286647754, 0.29607057453071695, ColorLabel.values[0]), // black
  ColorSample(231.39474234666258, 0.31945328790987976, 0.4250180912599855, ColorLabel.values[0]), // black
//  ColorSample(65.80395409103818, 0.45780597430404546, 0.4830136934664936, ColorLabel.values[0]), // black

  ColorSample(27.28721602576081, 0.5404774413449049, 0.4359643335376775, ColorLabel.values[1]), // brown
  ColorSample(18.32064783968096, 0.7340887115692256, 0.2906068861048038, ColorLabel.values[1]), // brown
  ColorSample(5.454545454545454, 0.7284768211920529, 0.5921568627450979, ColorLabel.values[1]), // brown

  ColorSample(16.818420087262496, 0.9861414074289593, 1.0, ColorLabel.values[2]), // red
  ColorSample(284.71332496146545, 0.3111493839395141, 0.6644504966481407, ColorLabel.values[2]), // red
  ColorSample(9.370778714348916, 0.9795086119930451, 0.7026264328007525, ColorLabel.values[2]), // red
  ColorSample(5.753031075330524, 0.8975515324366099, 0.6897165478219655, ColorLabel.values[2]), // red

  ColorSample(17.358992702922617, 0.6925015339795019, 0.7768444648696938, ColorLabel.values[3]), // orange
  ColorSample(12.609665277584893, 0.41376634557614433, 0.8036447648948105, ColorLabel.values[3]), // orange
  ColorSample(24.14630860700314, 0.869204588739556, 0.8899336171981685, ColorLabel.values[3]), // orange

  ColorSample(54.27234253322814, 0.7619898870432208, 0.6540767962743032, ColorLabel.values[4]), // yellow
  ColorSample(40.83696272018235, 0.3319916571961642, 0.8574313921873056, ColorLabel.values[4]), // yellow
  ColorSample(59.39330344647117, 0.9797945874876657, 0.7783449731343245, ColorLabel.values[4]), // yellow

  ColorSample(161.72730382607674, 0.9781841975994472, 0.39324026634350834, ColorLabel.values[5]), // green
  ColorSample(163.69213033241073, 0.6392351203529959, 0.5828383566670376, ColorLabel.values[5]), // green
  ColorSample(157.38639848564213, 0.9444707753629212, 0.35916976915393733, ColorLabel.values[5]), // green

  ColorSample(186.68566910316306, 0.2764461360876425, 0.6267477086932804, ColorLabel.values[6]), // blue
  ColorSample(211.3587355736654, 0.6977581658608437, 0.9232900745569139, ColorLabel.values[6]), // blue
  ColorSample(211.83335462827137, 0.6902301687104894, 0.8954194456433388, ColorLabel.values[6]), // blue

  ColorSample(255.12027715024198, 0.604108855640004, 0.8385241773448531, ColorLabel.values[7]), // violet
  ColorSample(265.5549986611829, 0.42786195787030984, 0.8632997107587806, ColorLabel.values[7]), // violet
  ColorSample(261.48697224698543, 0.41060083410084874, 0.8414544668370109, ColorLabel.values[7]), // violet

  ColorSample(0, 0, 0.5, ColorLabel.values[8]), // grey

  ColorSample(225.4623728229465, 0.185235116727912, 0.9714050330401406, ColorLabel.values[9]), // white
  ColorSample(202.7554027647056, 0.20835526019770229, 0.9608742065022001, ColorLabel.values[9]), // white
  ColorSample(217.65279359335676, 0.14332171894557993, 0.6216039749732875, ColorLabel.values[9]), // white

  ColorSample(237.00696833733292, 0.34896335041550003, 0.8781481268739254, ColorLabel.values[10]), // silver
  ColorSample(234.73167662793583, 0.1703919560700564, 0.5971943938116031, ColorLabel.values[10]), // silver
  ColorSample(213.32943896277814, 0.1574551017897365, 0.9882116419415354, ColorLabel.values[10]), // silver

  ColorSample(40.05037908856158, 0.4520224161518332, 0.6640633566557742, ColorLabel.values[11]), // gold
  ColorSample(0.0, 0.05800275180964968, 0.8092295637256028, ColorLabel.values[11]), // gold
  ColorSample(44.10000000000003, 0.08967057509771076, 0.7941176470588236, ColorLabel.values[11]), // gold
//  ColorSample(34, 0.52, 0.58, ColorLabel.gold),
];

class ColorSample {
  final double h;
  final double s;
  final double v;
  final ColorLabel label;

  ColorSample(this.h, this.s, this.v, this.label);
}

ColorLabel classifyKnn(
  List<double> hsv,
) 
{
  final sorted = [...samples];
  sorted.sort((a, b) {
    final da = hsvDistance(hsv[0], hsv[1], hsv[2], a.h, a.s, a.v);
    final db = hsvDistance(hsv[0], hsv[1], hsv[2], b.h, b.s, b.v);

    return da.compareTo(db);
  });

  // Use top 3 neighbors
  final top = sorted.take(3);
  for (final s in sorted.take(3)) { // for debug only
    print(
      '${s.label} '
      '${hsvDistance(hsv[0], hsv[1], hsv[2], s.h, s.s, s.v)}'
    );
  }

  final votes = <ColorLabel, double>{};
  for (final sample in top) {
    final d = hsvDistance(
      hsv[0],
      hsv[1],
      hsv[2],
      sample.h,
      sample.s,
      sample.v,
  );

  final weight = 1.0 / (d + 0.0001);

  votes[sample.label] =
      (votes[sample.label] ?? 0) + weight;
}
  return votes.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;
}

/*
List<List<double>> mergeRegions(List<List<double>> profile) {
/*  const minWidth = 6;

  if (edges.length < 3) { // return if only 3 edges
    return edges;
  }

  final result = <int>[0];

  int i = 1;

  while (i < edges.length) {
    final current = edges[i];
    final width = edges[i] - result.last; // how far are we from the last one

    // Tiny region with neighbors
    if (width < minWidth && i < (edges.length - 1)) {

  if (profile.length < 3) {
    return profile; // not enough segments to merge
  }

  List<List<double>> result = [[...profile.first]];
  int i = 1;

  while (i < (profile.length)) { // make sure we stay in bounds with -1 and +1
    final prev = profile[i-1];
    final current = profile[i];
    final prevDist = hsvDistance(current, prev);
    print("distance $prevDist");
    if (prevDist < 0.020) { // very close
//    if (prevDist < 3.0) { // very close
      result.last = (current); // replace the last entry with this new one
    }
    else {
      result.add(current); // add a new entry with the current value
    }
    i++; // 
  }
*/
/*
      final prev = result.last;
      final next = edges[i + 1];
// leave out this distance calculation for now
      final prevDist =
          hsvDistance(current.hsv, prev.hsv);

      final nextDist =
          hsvDistance(current.hsv, next.hsv);

      // Merge with closest neighbor
      if (prevDist < nextDist) {
        prev.end = current.end;
      } else {
        next.start = current.start;
      }

      i++;
      continue;
    }

    result.add(current);
    i++;
  }
*/
  return result;
}
*/
List<List<double>> smoothProfile(
  List<List<double>> profile,
) {
  final result = <List<double>>[];

  for (int i = 0; i < profile.length; i++) {
    double hX = 0;
    double hY = 0;
    double s = 0;
    double v = 0;
    int count = 0;

    for (int j = i - 2; j <= i + 2; j++) {
      if (j < 0 || j >= profile.length) continue;

      final p = profile[j];

      final rad = p[0] * pi / 180.0;

      hX += cos(rad);
      hY += sin(rad);

      s += p[1];
      v += p[2];

      count++;
    }

    double h =
        atan2(hY / count, hX / count) * 180.0 / pi;

    if (h < 0) h += 360;

    result.add([
      h,
      s / count,
      v / count,
    ]);
  }

  return result;
}

List<ColorLabel> filterBands(List<ColorLabel> bands) {
  // Keep largest color changes (heuristic)
  if (bands.length <= 2) return []; // short list just returns list

  // Count occurrences
  final counts = <ColorLabel, int>{};
  for (final color in bands) {
    counts[color] = (counts[color] ?? 0) + 1;
  }
  // Find most common color(s)
  int maxCount = 0;
  for (final count in counts.values) {
    if (count > maxCount) {
      maxCount = count;
    }
  }
  final mostCommon = counts.entries
      .where((e) => e.value == maxCount)
      .map((e) => e.key)
      .toSet();

  final result = <ColorLabel>[];

  ColorLabel? previous;
  // Ignore first and last bands
  final trimmed = bands.sublist(1, bands.length - 1);

  for (final color in trimmed) {
    // Ignore dominant background colors
    if (mostCommon.contains(color)) {
      continue;
    }
    // Collapse duplicates
    if (previous == color) {
      continue;
    }
    result.add(color);
    previous = color;
  }

  ColorLabel tolerance = ColorLabel.values[12] ; // none
  
  if (result.length == 4) { // 4th is tolerance
      tolerance = result[3]; // 4th  band
      result[3] = ColorLabel.values[12]; // none
      result.add(tolerance); // put tolerance in last place
      return result;
  }
  // Returns a lazy iterable of up to 5 items, then converts it back to a List
  return result.take(5).toList();
}
/*
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

*/
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
/*
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
*/
ColorLabel classifyColor(List<double> hsv) {
  final h = hsv[0];
  final s = hsv[1];
  final v = hsv[2];

  if (v < 0.12) {
    print("HSV Black = $hsv");
    return ColorLabel.values[0]; //"black";
  }
  if (s < 0.15) {
  // Silver: bright low-saturation metallic gray
    if (v >= 0.55 && v < 0.6) { // ChatGPT used .82
      print("HSV Silver = $hsv");
      return ColorLabel.values[11]; // silver
    }
    if (v >= 0.6) {  // ChatGPT used .82
      print("HSV White = $hsv");
      return ColorLabel.values[9]; // white
    }
    print("HSV Gray = $hsv");
    return ColorLabel.values[8]; // gray
  }
  
  if (h < 15 || h > 345) {
    print("HSV Red = $hsv");    
    return ColorLabel.values[2];// "red";
  }
  if (h >= 15 && h < 45) {
    // Brown = darker orange
    if (v < 0.55) {
      print("HSV Brown = $hsv");
      return ColorLabel.values[1]; //"brown";
    }
    // Gold tends to be less saturated
    if (s < 0.65 && v > 0.6) {
      print("HSV Gold = $hsv");
      return ColorLabel.values[10]; //"gold";
    }
    print("HSV Orange = $hsv");
    return ColorLabel.values[3]; //"orange";
  }
  if (h >= 45 && h < 70) {
   print("HSV Yellow = $hsv");
   return ColorLabel.values[4];// "yellow";
  }
  if (h >= 70 && h < 170) {
    print("HSV Green = $hsv");
    return ColorLabel.values[5]; //"green";
  }
  if (h >= 170 && h < 260) {
    print("HSV Blue = $hsv");
    return ColorLabel.values[6]; //"blue";
  }
  if (h >= 260 && h < 320) {
    print("HSV Violet = $hsv");
    return ColorLabel.values[7]; //"violet";
  }
  print("HSV Unknown = $hsv");
  return ColorLabel.values[12]; // none;
  /*
  You may want to tune the thresholds depending on your camera pipeline:
Increase silver lower bound (v >= 0.6) if too many grays become silver.
Lower white threshold (v >= 0.8) if silver becomes white too often.
  */
}
/*
ColorLabel classifyHSV(List<double> hsv) {
  final h = hsv[0];
  final s = hsv[1];
  final v = hsv[2];

  // ---------------- BLACK ----------------
  // Allow slightly brighter dark pixels
  if (v < 0.18) {
    return ColorLabel.values[0]; // black
  }

  // ---------------- NEUTRALS ----------------
  // Handle white/gray/silver before hue checks
  if (s < 0.20) {
    if (v > 0.82) {
      return ColorLabel.values[9]; // white
    }

    if (v > 0.45) {
      return ColorLabel.values[11]; // silver
    }

    return ColorLabel.values[8]; // gray
  }

  // ---------------- RED ----------------
  // Narrow red slightly so orange stops becoming red
  if (h < 12 || h >= 350) {
    return ColorLabel.values[2]; // red
  }

  // ---------------- BROWN / ORANGE / GOLD ----------------
  // Camera orange often appears 10-40
  if (h >= 12 && h < 45) {

    // Brown = darker orange/red
    if (v < 0.42) {
      return ColorLabel.values[1]; // brown
    }

    // Gold is usually:
    // medium saturation
    // medium brightness
    // yellow-orange hue
    if (h > 20 &&
        h < 50 &&
        s > 0.35 &&
        s < 0.75 &&
        v > 0.45 &&
        v < 0.75) {
      return ColorLabel.values[10]; // gold
    }

    return ColorLabel.values[3]; // orange
  }

  // ---------------- YELLOW ----------------
  // Widen yellow slightly
  if (h >= 45 && h < 75) {
    return ColorLabel.values[4]; // yellow
  }

  // ---------------- GREEN ----------------
  // Reduce overlap into cyan
  if (h >= 75 && h < 155) {
    return ColorLabel.values[5]; // green
  }

  // ---------------- BLUE ----------------
  // Start blue later to stop green becoming blue
  if (h >= 155 && h < 255) {
    return ColorLabel.values[6]; // blue
  }

  // ---------------- VIOLET ----------------
  if (h >= 255 && h < 340) {
    return ColorLabel.values[7]; // violet
  }

  return ColorLabel.values[12]; // none
}

double calculateMode(List<double> numbers) {
  if (numbers.isEmpty) return 0.0;

  // 1. Create a frequency map to count occurrences
  final Map<double, int> counts = {};
  for (final num in numbers) {
    counts[num] = (counts[num] ?? 0) + 1;
  }

  // 2. Find the highest frequency
  final int maxCount = counts.values.reduce((a, b) => a > b ? a : b);

  // 3. Collect all numbers that appear with the maximum frequency
  final List<double> countList =  counts.entries
      .where((entry) => entry.value == maxCount)
      .map((entry) => entry.key)
      .toList(); // list of all entries that meat maxCount

  return countList[countList.length ~/ 2];
}
*/
/*
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
*/
(List<List<double>>, List<int>) averageHsvSegments(
  List<List<double>> profile,
  List<int> edges,
) {
  final segments = <List<double>>[];
  final mids = <int>[];   // mid points of segments

  if (edges.length < 2) {
    mids.add(edges.length~/2);
    return (segments, mids); // if there are no segments.
  } 
  for (int i = 0; i < edges.length - 1; i++) {
    int start = edges[i];
    int end = edges[i + 1];

    if (end <= start) continue;

    // Ignore noisy edge-transition pixels
    const edgeTrim = 3;

    start += edgeTrim;
    end -= edgeTrim;

    if (end <= start) continue;

    double sumX = 0;
    double sumY = 0;

    double weightedS = 0;
    double weightedV = 0;
    double totalWeight = 0;

    int count = 0;

    for (int x = start; x < end; x++) {
      if (x < 0 || x >= profile.length) continue;

      final hsv = profile[x];

      final h = hsv[0];
      final s = hsv[1];
      final v = hsv[2];

      // Ignore extremely dark pixels
      if (v < 0.08) continue;

      // Weight colorful bright pixels more strongly
      final weight = (s * s) * (0.5 + v * 0.5);

      // Only contribute hue if saturation meaningful
      if (s > 0.08) {
        final radians = h * pi / 180.0;

        sumX += cos(radians) * weight;
        sumY += sin(radians) * weight;
      }

      weightedS += s * weight;
      weightedV += v * weight;

      totalWeight += weight;
      count++;
    }

    if (count == 0 || totalWeight <= 0) continue;

    double avgHue;

    // If hue vector nearly vanished, segment is neutral
    final double calculatedMagnitude = sqrt(sumX * sumX + sumY * sumY);

    if (calculatedMagnitude < 0.001) {
      avgHue = 0;
    } else {
      avgHue = atan2(sumY, sumX) * 180.0 / pi;

      if (avgHue < 0) {
        avgHue += 360;
      }
    }

    final avgS = weightedS / totalWeight;
    final avgV = weightedV / totalWeight;

    segments.add([
      avgHue,
      avgS,
      avgV,
    ]);
    mids.add((start+end)~/2);
  } // <-- Closes the for loop

  return (segments, mids); // <-- Returns the calculated segments
}

List<double> rgbToLab(double r, double g, double b) {
  // Normalize RGB
  r /= 255.0;
  g /= 255.0;
  b /= 255.0;

  // Gamma correction
  r = r > 0.04045
      ? pow((r + 0.055) / 1.055, 2.4).toDouble()
      : r / 12.92;

  g = g > 0.04045
      ? pow((g + 0.055) / 1.055, 2.4).toDouble()
      : g / 12.92;

  b = b > 0.04045
      ? pow((b + 0.055) / 1.055, 2.4).toDouble()
      : b / 12.92;

  // RGB -> XYZ
  double x =
      r * 0.4124 +
      g * 0.3576 +
      b * 0.1805;

  double y =
      r * 0.2126 +
      g * 0.7152 +
      b * 0.0722;

  double z =
      r * 0.0193 +
      g * 0.1192 +
      b * 0.9505;

  // Reference white
  x /= 0.95047;
  y /= 1.00000;
  z /= 1.08883;

  double f(double t) {
    return t > 0.008856
        ? pow(t, 1 / 3).toDouble()
        : (7.787 * t) + (16 / 116);
  }

  final fx = f(x);
  final fy = f(y);
  final fz = f(z);

  final L = (116 * fy) - 16;
  final A = 500 * (fx - fy);
  final B = 200 * (fy - fz);

  return [L, A, B];
}

final resistorHSV = {
  ColorLabel.values[0]: [0.0,   0.0, 0.05], // black
  ColorLabel.values[1]: [25.0,  0.75, 0.35], // brown
  ColorLabel.values[2]:   [0.0,   0.85, 0.75], // red
  ColorLabel.values[3]:[30.0,  0.90, 0.90], // orange
  ColorLabel.values[4]:[60.0,  0.85, 0.95], // yellow
  ColorLabel.values[5]: [120.0, 0.80, 0.60], // green
  ColorLabel.values[6]:  [220.0, 0.85, 0.70], // blue
  ColorLabel.values[7]:[285.0, 0.75, 0.65], // violet
  ColorLabel.values[8]:  [0.0,   0.0, 0.50], // gray
  ColorLabel.values[9]: [0.0,   0.0, 0.95], // white
  ColorLabel.values[10]:  [45.0,  0.55, 0.75], // gold
  ColorLabel.values[11]:  [0.0,  0.0, 0.75], // silver
  ColorLabel.values[12]:  [0.0,  0.0, 0.0], // none
};

double hsvDistance(
  double h1,
  double s1,
  double v1,
  double h2,
  double s2,
  double v2,
) {
  // Circular hue distance
  double dh = (h1 - h2).abs();

  if (dh > 180) {
    dh = 360 - dh;
  }

  // Normalize
  dh /= 180.0;

  final ds = s1 - s2;
  final dv = v1 - v2;

  // Hue reliability:
  // weak when dark or desaturated
  final hueConfidence =
      ((s1 + s2) * 0.5) *
      ((v1 + v2) * 0.5);

  return
      dh * dh * hueConfidence * 2.0 +
      ds * ds * 2.5 +
      dv * dv * 1.2;
}

/*
double hsvDistance(
  List<double> a,
  List<double> b,
) {
  double h1 = a[0];
  double s1 = a[1];
  double v1 = a[2];

  double h2 = b[0];
  double s2 = b[1];
  double v2 = b[2];

  double hueDiff = 0;

  // Only compare hue if both colors are colorful
  if (s1 > 0.12 && s2 > 0.12) {
    hueDiff = (h1 - h2).abs();

    if (hueDiff > 180) {
      hueDiff = 360 - hueDiff;
    }

    hueDiff /= 180.0;
  }

  final satDiff = (s1 - s2).abs();
  final valDiff = (v1 - v2).abs();

  return
      hueDiff * 0.7 +
      satDiff * 0.2 +
      valDiff * 0.1;
}
*/
/*
double hsvDistance(
  List<double> a,
  List<double> b,
) {
  double hueDiff =
      (a[0] - b[0]).abs();

  // Circular hue distance
  if (hueDiff > 180) {
    hueDiff = 360 - hueDiff;
  }

  final satDiff =
      (a[1] - b[1]).abs();

  final valDiff =
      (a[2] - b[2]).abs();

  return
      hueDiff * 2.0 +
      satDiff * 100 +
      valDiff * 40;

  return
      hueDiff * 0.65 +
      satDiff * 0.20 +
      valDiff * 0.15;}
*/
/*
ColorLabel classifyHSV(List<double> hsv) {

  ColorLabel best = ColorLabel.values[0]; // black
  double bestDist = double.infinity;

  resistorHSV.forEach((name, ref) {

    final d = hsvDistance(hsv, ref);

    if (d < bestDist) {
      bestDist = d;
      best = name;
    }
  });

  return best;
}
*/
/*
double labDistance(List<double> a, List<double> b) {
  return sqrt(
    pow(a[0] - b[0], 2) +
    pow(a[1] - b[1], 2) +
    pow(a[2] - b[2], 2),
  );
}

ColorLabel classifyLab(List<double> lab) {
/*  final lab =
      rgbToLab(rgb[0], rgb[1], rgb[2]);
*/
  ColorLabel bestColor = ColorLabel.values[0]; // black
  double bestDistance = double.infinity;

  resistorLabColors.forEach((name, refLab) {
    final d = labDistance(lab, refLab);

    if (d < bestDistance) {
      bestDistance = d;
      bestColor = name; // name is a ColorLabel
    }
  });

  return bestColor;
}

List<List<double>> averageLabSegments(
  List<List<double>> rgbProfile,
  List<int> edges,
) {
  final segments = <List<double>>[];

  if (edges.length < 2) return segments;

  for (int i = 0; i < edges.length - 1; i++) {
    final start = edges[i];
    final end = edges[i + 1];
    if (end <= start) continue;

    final margin =
        ((end - start) * 0.1).toInt();

    final safeStart = start + margin;
    final safeEnd = end - margin;

    double sumR = 0;
    double sumG = 0;
    double sumB = 0;

    int count = 0;

    for (int x = safeStart; x < safeEnd; x++) {
      if (x < 0 || x >= rgbProfile.length) continue;

      sumR += rgbProfile[x][0];
      sumG += rgbProfile[x][1];
      sumB += rgbProfile[x][2];

      count++;
    }

    if (count == 0) continue;

    segments.add(rgbToLab(sumR / count,
      sumG / count,
      sumB / count)
    ); // convert rgb average to LAB to return.
  }
  return segments;
}

final resistorLabColors = {
  ColorLabel.values[0]: rgbToLab(0, 0, 0), // black
  ColorLabel.values[1]: rgbToLab(120, 70, 30), // brown
  ColorLabel.values[2]: rgbToLab(200, 30, 30), // red
  ColorLabel.values[3]: rgbToLab(255, 120, 20), // orange
  ColorLabel.values[4]: rgbToLab(255, 220, 30), // yellow
  ColorLabel.values[5]: rgbToLab(30, 160, 60), // green
  ColorLabel.values[6]: rgbToLab(30, 90, 220), // blue
  ColorLabel.values[7]: rgbToLab(140, 60, 180), // violet
  ColorLabel.values[8]: rgbToLab(140, 140, 140), // gray
  ColorLabel.values[9]: rgbToLab(240, 240, 240), // white
  ColorLabel.values[10]: rgbToLab(212, 175, 55), // gold
  ColorLabel.values[11]: rgbToLab(192, 192,192), // silver
  ColorLabel.values[12]: rgbToLab(0, 0, 0), // none
};

void printCenter(img.Image image) {
  final int w = image.width;
  final int h = image.height;
  final int centerPix = (w ~/ 2);
  int centerY = h ~/ 2 ;

  for (int y = centerY - 3; y < centerY + 3; y++ ){
    print(image.getPixel(centerPix, y));
  }  
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
*/
double calculateMedian(List<num> list) {

  if (list.isEmpty) return 0;

  // 2. Sort the sublist (required for median)
  list.sort();

  int middle = list.length ~/ 2;

  // 3. Apply median logic
  if (list.length % 2 == 1) {
    // Odd length: return the middle element
    return list[middle].toDouble();
  } else {
    // Even length: return average of the two middle elements
    return (list[middle - 1] + list[middle]) / 2;
  }
}
/*
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

List<ColorLabel> orderedColors(List<List<double>> bands) {
  return bands.map(matchColor).toList();
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


*/
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
