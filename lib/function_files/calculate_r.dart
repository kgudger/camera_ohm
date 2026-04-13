import 'package:camera_ohm/main.dart';
import 'dart:math';

String reString = "Select Colors";

void calculateR() {
  double totalR = 0.0;
  ColorLabel? tempC = selectedColor[0];
  int newR = (tempC!.index) ;
  if (newR == 0 || newR > 9 || selectedColor[1]!.index > 9 ) {
    reString = "Please enter appropriate colors";
    return;
  }
  int newMult = selectedColor[2]!.index;
  if (newMult > 9) {
    reString = "Please enter appropriate colors";
    return;
  }
  totalR = selectedColor[1]!.index.toDouble();
  totalR = newR.toDouble() * 10.0 + totalR;
  int decimals = 1;
  if (selectedColor[3]!.label != 'None') {
    totalR = 10*totalR + selectedColor[2]!.index ;
    newMult = selectedColor[3]!.index;
    decimals = 2;
  }
  switch (newMult) {
    case <= 9:
      totalR = totalR * pow(10,newMult);
    case 10:
      totalR = totalR * pow(10,-1);
    case 11:
        totalR = totalR * pow(10,-2);
    default:
      reString = "Please enter appropriate colors";
  } 
  switch (totalR) {
    case >= 1000000000 :
      reString = "R = ${(totalR / 1000000000).toStringAsFixed(decimals)} G ohms ";
    case >= 1000000:
      reString = "R = ${(totalR / 1000000).toStringAsFixed(decimals)} M ohms ";
    case >= 1000:
      reString = "R = ${(totalR / 1000).toStringAsFixed(decimals)} K ohms ";
    case -1.0:
      reString = "Please enter appropriate colors";
    default:
      reString = "R = ${totalR.toStringAsFixed(decimals)} ohms ";
  }
  String tol = "10%";
  switch (selectedColor[4]!.label) {
    case 'Brown':
      tol = "1%";
    case 'Red':
      tol = "2%";
    case 'Green':
      tol = "0.5%";
    case 'Blue':
      tol = "0.25%";
    case 'Grey':
      tol = "0.05%";
    case 'Gold':
      tol = "5%";
    default:
      tol = "10%";
  }
  reString = reString + tol; 
}

