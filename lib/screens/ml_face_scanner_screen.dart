import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import '../models/person.dart';
import '../services/memory_store.dart';

class MLFaceScannerScreen extends StatefulWidget {
  const MLFaceScannerScreen({super.key});

  @override
  State<MLFaceScannerScreen> createState() => _MLFaceScannerScreenState();
}

class _MLFaceScannerScreenState extends State<MLFaceScannerScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  double _scanProgress = 0.0;
  late AnimationController _scannerController;
  
  // Camera Shutter Properties
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  XFile? _capturedPhoto;
  bool _isAnalyzing = false;

  // Registration Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _detailController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _foodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initializeCamera();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _cameraController?.dispose();
    _nameController.dispose();
    _relationshipController.dispose();
    _detailController.dispose();
    _birthdayController.dispose();
    _foodController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Prefer front camera for self face scan if possible
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Scanner camera init error: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _scanProgress = 0.1;
    });

    try {
      final photo = await _cameraController!.takePicture();

      // Laser analysis pulse animation feedback
      for (double p = 0.1; p <= 1.0; p += 0.15) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _scanProgress = p.clamp(0.0, 1.0);
          });
        }
      }

      if (mounted) {
        setState(() {
          _capturedPhoto = photo;
          _isScanning = false;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint('Capture face photo error: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _scanProgress = 0.0;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final person = Person(
        name: _nameController.text.trim(),
        relationship: _relationshipController.text.trim(),
        detail: _detailController.text.trim(),
        favoriteFood: _foodController.text.trim(),
        birthday: _birthdayController.text.trim(),
        photoPath: _capturedPhoto?.path ?? '',
      );

      await MemoryStore.instance.registerPerson(person);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2C1E1B),
            content: Text(
              MemoryStore.instance.translate(
                tagalog: 'Matagumpay na nairehistro ang mukha ni ${person.name}!',
                english: 'Successfully registered face of ${person.name}!',
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
        Navigator.of(context).pop(person);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4A359);
    const darkWood = Color(0xFF2C1E1B);
    const capizCream = Color(0xFFFAF7F0);
    final store = MemoryStore.instance;

    return Scaffold(
      backgroundColor: _isScanning ? const Color(0xFF130E0C) : capizCream,
      appBar: AppBar(
        title: Text(
          store.translate(tagalog: 'ML Face Registration', english: 'ML Face Registration'),
          style: GoogleFonts.cormorantGaramond(
            fontWeight: FontWeight.bold,
            color: _isScanning ? Colors.white : darkWood,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _isScanning ? Colors.white : darkWood),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: _isScanning
            ? _buildScannerView(goldColor)
            : _buildRegistrationForm(darkWood, goldColor),
      ),
    );
  }

  Widget _buildScannerView(Color accentColor) {
    final store = MemoryStore.instance;
    return Container(
      key: const ValueKey('scanner'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            store.translate(tagalog: 'ISALANG ANG MUKHA SA VIEWPORT', english: 'ALIGN FACE IN VIEWPORT'),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Glowing Lens Camera Bounding Box
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 2),
                  borderRadius: BorderRadius.circular(130),
                ),
              ),
              // Pulse scanning frame
              AnimatedBuilder(
                animation: _scannerController,
                builder: (context, child) {
                  return Container(
                    width: 240 + (_scannerController.value * 12),
                    height: 240 + (_scannerController.value * 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.4 + (_scannerController.value * 0.4)),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(125),
                    ),
                  );
                },
              ),
              // Circular camera preview
              ClipRRect(
                borderRadius: BorderRadius.circular(130),
                child: Container(
                  width: 250,
                  height: 250,
                  color: Colors.black,
                  child: _isCameraInitialized && _cameraController != null
                      ? CameraPreview(_cameraController!)
                      : const Icon(
                          Icons.face_retouching_natural_rounded,
                          color: Colors.white38,
                          size: 90,
                        ),
                ),
              ),

              // Scanning laser line
              AnimatedBuilder(
                animation: _scannerController,
                builder: (context, child) {
                  return Positioned(
                    top: 20 + (_scannerController.value * 220),
                    child: Container(
                      width: 220,
                      height: 4,
                      decoration: BoxDecoration(
                        color: accentColor,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Percentage indicator
          Text(
            '${(_scanProgress * 100).toInt()}%',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isAnalyzing
                ? store.translate(
                    tagalog: 'Sinusuri ang facial features sa camera...',
                    english: 'Analyzing facial features in camera feed...',
                  )
                : store.translate(
                    tagalog: 'Itapat ang camera sa mukha at pindutin ang shutter upang kumuha.',
                    english: 'Point camera at the face and press shutter to capture.',
                  ),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 140,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white10,
              value: _scanProgress,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 24),
          
          if (!_isAnalyzing)
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ),
            )
          else
            Text(
              store.translate(tagalog: 'Kinukunan...', english: 'Scanning face...'),
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(Color darkWood, Color accentColor) {
    final store = MemoryStore.instance;
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _capturedPhoto != null
                  ? Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: 3),
                        image: DecorationImage(
                          image: FileImage(File(_capturedPhoto!.path)),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_user_rounded,
                        color: accentColor,
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                store.translate(tagalog: 'Mukha ay Na-detect!', english: 'Face Detected!'),
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: darkWood,
                ),
              ),
            ),
            Center(
              child: Text(
                store.translate(
                  tagalog: 'Ilagay ang mga impormasyon upang mairehistro siyas.',
                  english: 'Fill up fields to register this person.',
                ),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),

            // Name
            _buildTextField(
              controller: _nameController,
              label: store.translate(tagalog: 'Pangalan', english: 'Full Name'),
              hint: 'Juan Dela Cruz',
              icon: Icons.person,
              validator: (v) => v == null || v.trim().isEmpty ? 'Isulat ang pangalan' : null,
            ),
            const SizedBox(height: 16),

            // Relationship
            _buildTextField(
              controller: _relationshipController,
              label: store.translate(tagalog: 'Relasyon', english: 'Relationship'),
              hint: store.translate(tagalog: 'Kapatid, Anak, Caregiver...', english: 'Daughter, Son, Nurse...'),
              icon: Icons.family_restroom,
              validator: (v) => v == null || v.trim().isEmpty ? 'Isulat ang relasyon' : null,
            ),
            const SizedBox(height: 16),

            // Details/Memories
            _buildTextField(
              controller: _detailController,
              label: store.translate(tagalog: 'Mga Detalye o Memorya', english: 'Description or Key Details'),
              hint: store.translate(
                tagalog: 'Siya ang nagdadala ng prutas tuwing Sabado...',
                english: 'He frequently visits and brings fresh flowers...',
              ),
              icon: Icons.auto_stories,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Birthday
            _buildTextField(
              controller: _birthdayController,
              label: store.translate(tagalog: 'Kaarawan (Opsyonal)', english: 'Birthday (Optional)'),
              hint: 'Enero 12, 1985',
              icon: Icons.cake,
            ),
            const SizedBox(height: 16),

            // Favorite Food
            _buildTextField(
              controller: _foodController,
              label: store.translate(tagalog: 'Paboritong Pagkain', english: 'Favorite Foods'),
              hint: 'Pancit Canton, Adobo',
              icon: Icons.restaurant,
            ),
            const SizedBox(height: 32),

            // Submit Button
            FilledButton(
              onPressed: _submitForm,
              style: FilledButton.styleFrom(
                backgroundColor: darkWood,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                store.translate(tagalog: 'I-save ang Mukha at Impormasyon', english: 'Save Registered Face'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    const darkWood = Color(0xFF2C1E1B);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: darkWood, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF8B8276)),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF756A5B), fontSize: 13),
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE9DFC8), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD4A359), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
