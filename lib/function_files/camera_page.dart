import 'package:camera_ohm/function_files/calculate_r.dart';
import 'package:flutter/material.dart';
//import 'package:camera/camera.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camera_ohm/main.dart';
import 'package:camera_ohm/function_files/cam_calc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPage();
}

class _CameraPage extends State<CameraPage> {
  bool _isInitialized = false;
  var logger = Logger();
  final String _processedText = "No image processed yet";

  // 1. Your custom function to process the image
/*  Future<void> _getResistorColors(String filePath) async {
    setState(() {
      _processedText = "Processing...";
    });

    // Simulate some logic (like OCR or AI analysis)
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real app, you might use Google ML Kit or an API call here
    setState(() {
      _processedText = "Processed File: ${p.basename(filePath)}\nStatus: Success";
      
    });
  }
*/
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _init();
  //  _setupCamera();
  //  selectedColor = List.from(defaultColor);
  //  reString = "Calculate R";
  }
  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _isInitialized = true);
    }
  }
  Future<void> _checkPermissions() async {
  final status = await Permission.camera.request();
  if (!status.isGranted) {
    // Handle denied permission
    debugPrint("Camera permission not granted");
  }
}
  @override
  Widget build(BuildContext context) {
    StatusService.instance.updateText(reString);
    return Scaffold(
  /*    body: CameraAwesomeBuilder.awesome(
        sensorConfig: SensorConfig.single(
        sensor: Sensor.position(SensorPosition.back),
        ),
                    saveConfig: SaveConfig.photoAndVideo(
                      initialCaptureMode: CaptureMode.photo,
                      photoPathBuilder: (sensors) async {
                        final Directory extDir = await getTemporaryDirectory();
                        final testDir = await Directory(p.join(extDir.path, 'camerawesome')).create(recursive: true);
                        return SingleCaptureRequest(
                          p.join(
                            testDir.path,
                            '${DateTime.now().millisecondsSinceEpoch}.jpg',
                          ),
                          sensors.first,
                        );
                      },
                    ),
      ),
    )*/  
      body: Column(
        children: [
          // Other UI elements
          Padding(
/*            padding: const EdgeInsets.all(16.0),
            child: Text("Live Camera Preview:", style: TextStyle(fontSize: 18)),*/
              padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),//all(20.0),
                child: Text(
              _processedText,
              style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
//            SizedBox(width: 20),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
            // Layer 1: The Live Camera Feed
                Positioned.fill( // suggested by ChatGPT
                  child: /*!_isInitialized
              ? const Center(child: CircularProgressIndicator())
              :*/ CameraAwesomeBuilder.awesome(
                    sensorConfig: SensorConfig.single(
                      sensor: Sensor.position(SensorPosition.back),
                      aspectRatio: CameraAspectRatios.ratio_16_9,
                    ),
  //                  customPreview: (preview) => preview,
              // 2. Listen for the capture event
                    saveConfig: SaveConfig.photoAndVideo(
                      initialCaptureMode: CaptureMode.photo,
                      photoPathBuilder: (sensors) async {
                        final Directory extDir = await getTemporaryDirectory();
                        final testDir = await Directory(p.join(extDir.path, 'camerawesome')).create(recursive: true);
                        return SingleCaptureRequest(
                          p.join(
                            testDir.path,
                            '${DateTime.now().millisecondsSinceEpoch}.jpg',
                          ),
                          sensors.first,
                        );
                      },
                    ),
            onMediaCaptureEvent: (event) {
                      if (event.status == MediaCaptureStatus.success && 
                          event.isPicture) {
                  // Retrieve the file path from the capture request
                        event.captureRequest.when(
                          single: (single) async {
                            final capturedImage = single.file;
                            if (capturedImage != null) {
                              getResistorColors(capturedImage);
                            }
                          }
                        );
                      }
                    },
                    previewFit: CameraPreviewFit.cover,
                  ),
                ),
                Container(
                  width: 100,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.red, 
                      width: 3.0,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Container(
                  width: 3,
                  height: 400,
                  color: Colors.purple,
                ),
                Positioned(
                  top: 10, // Distance from the top
                  left: 0,
                  right: 0,
                  child: Stack(
                    children: [
          // 1. The Outline Text (Stroke)
                      Center(
                        child: ValueListenableBuilder<String>(
                          valueListenable: StatusService.instance.sharedText,
                          builder: (context, currentString, child) {
                            return Text(
                              currentString,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 2
                                ..color = Colors.black, // Outline Color
                              ),
                            );
                          }, // builder
                        ),
                      ),
          // 2. The Main Text (Filled)
                      Center( child: ValueListenableBuilder<String>(
                        valueListenable: StatusService.instance.sharedText,
                        builder: (context, currentString, child) {
                          return Text(
                            currentString,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Fill Color
                            ),
                          );
                        }, // builder
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ), // children
          ),          
          // Action buttons below the camera
        ],
      ),
    );
  }
}

