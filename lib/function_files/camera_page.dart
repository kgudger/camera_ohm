import 'package:camera_ohm/function_files/calculate_r.dart';
import 'package:flutter/material.dart';
//import 'package:camera/camera.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camera_ohm/main.dart';
import 'package:camera_ohm/function_files/cam_calc.dart';
//import 'package:path_provider/path_provider.dart';
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
//  bool _isInitialized = false;
  var logger = Logger();
  String _processedText = "No image processed yet";
  bool _brightnessSet = false;
  dynamic _cameraState;
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
//      setState(() => _isInitialized = true);
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
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
            // Layer 1: The Live Camera Feed
                SizedBox(
                  width: double.infinity,
                  child: 
                  Center(
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                        child: ClipRect
                        ( // suggested by ChatGPT
                          child: /*!_isInitialized
                  ? const Center(child: CircularProgressIndicator())
                      :*/ CameraAwesomeBuilder.custom(
                            sensorConfig: SensorConfig.single(
                              sensor: Sensor.position(SensorPosition.front), // back for device, front for emulator
                              aspectRatio: CameraAspectRatios.ratio_4_3,
                            ),
          //                  customPreview: (preview) => preview,
                      // 2. Listen for the capture event
                            saveConfig: SaveConfig.photoAndVideo(
                              initialCaptureMode: CaptureMode.photo,
                              photoPathBuilder: (sensors) async {
//                                final Directory extDir = await getTemporaryDirectory();
//                                final testDir = await Directory(p.join(extDir.path, 'camerawesome')).create(recursive: true);
                                  final directory = Directory('/storage/emulated/0/Download/');

                                return SingleCaptureRequest(
                                  p.join(
//                                    testDir.path,
                                      directory.path,
                                    '${DateTime.now().millisecondsSinceEpoch}.jpg',
//                                      'captured_image.png',
                                  ),
                                  sensors.first,
                                );
                              },  // photoPathBuilder
                            ),
                            onMediaCaptureEvent: (event) {
                              if (event.status == MediaCaptureStatus.success && 
                                  event.isPicture) {
                            // Retrieve the file path from the capture request
                                event.captureRequest.when(
                                  single: (single) async {
                                    final capturedImage = single.file;
                                    if (capturedImage != null) {
                                      selectedColor =  await getResistorColors(capturedImage);
                                      calculateR();
                                      StatusService.instance.updateText(" $reString");                          
                                      _processedText = "Image processed";
                                    }
                                  }
                                );
                              }
                            },
                            previewFit: CameraPreviewFit.contain,
                            builder: (state, previewSize) {
                              _cameraState = state;
                              // Works across more CamerAwesome versions
                              if (!_brightnessSet) {
                                  _brightnessSet = true;
                                try {
                                  state.sensorConfig.setBrightness(0.7); // range ~0.0–1.0
                                } catch (e) {
                                  print("Brightness not supported: $e");
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),//end of camerawesome child
                        ),
                      ),
                  ),
                ),
                Container(
                  width: 100,
                  height: 250,
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
                  height: 300,
                  color: Colors.lightGreenAccent,
                ),
                Positioned(
                  top: 0, // Distance from the top
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
                                ..color = Colors.white, // Outline Color
                              ),
                            );
                          }, // builder
                        ),
                      ),
          // 2. The Main Text (Filled)
                      Center( child: 
                      ValueListenableBuilder<String>(
                        valueListenable: StatusService.instance.sharedText,
                          builder: (context, currentString, child) {
                            return Text(
                              currentString,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // Fill Color
                              ),
                            );
                          }, // builder
                        ),
                      ),
                    ], // children
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          _cameraState?.takePhoto();
                        } catch (e) {
                          print("Capture failed: $e");
                        }
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 3),
                        ),
                      ),
                    ),
                  ),
                ),
              ], // children
            ),
          ), 
        ],   // children       
          // Action buttons below the camera
      ),
    ); // Here is where the error 'Expected to find ;' is
  }
}
