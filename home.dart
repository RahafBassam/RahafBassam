import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  late File _image;
  late List _output;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {});
    });
  }

  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/classifier.tflite",
        labels: "assets/labels.txt",
        numThreads: 1,
        isAsset: true,
        useGpuDelegate: false,
      );

    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  Future<void> detectImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 3,
      threshold: 0.6,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    setState(() {
      loading = false;
      _output = output ?? []; // Set _output to an empty list if output is null
      if (_output.isNotEmpty) { // Check if _output is not empty
        _output = _output.sublist(0, _output.length < 3 ? _output.length : 3);
      }
    });

  }
  @override
  Future<void> dispose() async {
    await Tflite.close();
    super.dispose();
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedImage = await picker.pickImage(source: source);
    if (pickedImage != null) {
      File? croppedFile = await _cropImage(File(pickedImage.path));
      if (croppedFile != null) {
        setState(() {
          _image = croppedFile; // Assigning to a File? variable
          loading = true;
        });
        detectImage(croppedFile); // Passing the croppedFile to detectImage
      }
    }
  }


  Future<File?> _cropImage(File file) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9,
      ],
    );
    if (croppedFile != null) {
      // Convert CroppedFile to File
      return File(croppedFile.path);
    } else {
      return null;
    }
  }




  @override
  Widget build(BuildContext context) {
    var h = MediaQuery.of(context).size.height;
    var w = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Breast Cancer Classifier',
          style: GoogleFonts.roboto(),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              Container(
                height: 150,
                width: 150,
                padding: EdgeInsets.all(10),
                child: Image.asset('assets/Breast.jpeg'), // Placeholder image
              ),
              SizedBox(height: 20),
              Text(
                'Breast Cancer Biopsy Classifier',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: () => _getImage(ImageSource.camera),
                style: ElevatedButton.styleFrom(
                  primary: Colors.pink[300],
                ),
                child: Text(
                  'Capture',
                  style: GoogleFonts.roboto(fontSize: 18),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _getImage(ImageSource.gallery),
                style: ElevatedButton.styleFrom(
                  primary: Colors.pink[300],
                ),
                child: Text(
                  'Gallery',
                  style: GoogleFonts.roboto(fontSize: 18),
                ),
              ),
              SizedBox(height: 20),
              loading != true
                  ? Column(
                children: [
                  Container(
                    height: 220,
                    padding: EdgeInsets.all(15),
                    child: Image.file(_image),
                  ),
                  SizedBox(height: 20),
                  if (_output != null && _output.isNotEmpty) // Check if _output is not null and not empty
                    Text(
                      _output[0]['label'].toString().substring(2),
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        color: _output[0]['label']
                            .toString()
                            .contains('Grade 1')
                            ? Colors.green
                            : _output[0]['label']
                            .toString()
                            .contains('Grade 2')
                            ? Colors.yellow
                            : Colors.red,
                      ),
                    ),
                  SizedBox(height: 10),
                  if (_output != null && _output.isNotEmpty) // Check if _output is not null and not empty
                    Text(
                      'Confidence: ' +
                          _output[0]['confidence'].toString(),
                      style: GoogleFonts.roboto(fontSize: 18),
                    )
                ],
              )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

}
