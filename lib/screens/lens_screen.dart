import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/person.dart';
import '../models/memory.dart';
import '../services/memory_store.dart';
import '../widgets/polaroid_frame.dart';
import '../widgets/custom_card.dart';
import '../services/ai_client.dart';
import 'ml_face_scanner_screen.dart';

class LensScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const LensScreen({super.key, this.onNavigateToTab});

  @override
  State<LensScreen> createState() => _LensScreenState();
}

class _LensScreenState extends State<LensScreen> {
  Person? _lockedPerson;
  Timer? _faceLostTimer;

  final Set<String> _generatedPeople = {};
  bool _isGeneratingMemory = false;

  // Real Camera & ML Kit Bounding Box Properties
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  Rect? _detectedFaceRect;
  Size? _cameraImageSize;

  @override
  void initState() {
    super.initState();
    _initializeCameraAndDetector();
  }

  @override
  void dispose() {
    _faceLostTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  Future<void> _initializeCameraAndDetector() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No available cameras found.');
        return;
      }

      // Default to back camera for viewing people, otherwise front
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableTracking: true,
        ),
      );

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }

      // Stream frames to process detected faces
      _cameraController!.startImageStream((CameraImage image) {
        _processCameraFrame(image);
      });
    } catch (e) {
      debugPrint('Camera/ML Kit Initialization Error: $e');
    }
  }

  Uint8List _convertYUV420ToNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    
    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;
    
    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    
    final uRowStride = uPlane.bytesPerRow;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    
    final vRowStride = vPlane.bytesPerRow;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;
    
    final outSize = width * height + (width * height) ~/ 2;
    final out = Uint8List(outSize);
    
    var outOffset = 0;
    for (var y = 0; y < height; y++) {
      var rowOffset = y * yRowStride;
      for (var x = 0; x < width; x++) {
        out[outOffset++] = yBuffer[rowOffset + x * yPixelStride];
      }
    }
    
    final uvWidth = width ~/ 2;
    final uvHeight = height ~/ 2;
    
    for (var y = 0; y < uvHeight; y++) {
      var uRowOffset = y * uRowStride;
      var vRowOffset = y * vRowStride;
      for (var x = 0; x < uvWidth; x++) {
        out[outOffset++] = vBuffer[vRowOffset + x * vPixelStride];
        out[outOffset++] = uBuffer[uRowOffset + x * uPixelStride];
      }
    }
    
    return out;
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    if (_isDetecting || _faceDetector == null || !mounted) return;
    _isDetecting = true;

    try {
      final bytes = _convertYUV420ToNV21(image);
      final sensorOrientation = _cameraController!.description.sensorOrientation;
      
      final InputImageMetadata metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation90deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );

      final List<Face> faces = await _faceDetector!.processImage(inputImage);

      if (mounted) {
        setState(() {
          _cameraImageSize = Size(image.width.toDouble(), image.height.toDouble());
          if (faces.isNotEmpty) {
            _detectedFaceRect = faces.first.boundingBox;
            _faceLostTimer?.cancel();
            _faceLostTimer = null;

            // Only generate memory for the explicitly user-identified person.
            // We do NOT auto-assign anyone — ML Kit only tells us a face exists,
            // not who the person is.
            if (_lockedPerson != null) {
              _checkAndGenerateMemory(_lockedPerson!);
            }
          } else {
            _detectedFaceRect = null;
            // Grace period: keep card visible for 2s after face disappears
            _faceLostTimer ??= Timer(const Duration(milliseconds: 2000), () {
              if (mounted) {
                setState(() {
                  _lockedPerson = null;
                  _generatedPeople.clear(); // Allow re-generating memory next visit
                  _faceLostTimer = null;
                });
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Face detection parsing error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _checkAndGenerateMemory(Person person) async {
    if (_generatedPeople.contains(person.name) || _isGeneratingMemory) return;

    setState(() {
      _isGeneratingMemory = true;
    });

    try {
      final store = MemoryStore.instance;
      final rawResponse = await AIClient.instance.generateMemoryForPerson(
        personName: person.name,
        relationship: person.relationship,
        details: person.detail.isNotEmpty ? person.detail : person.favoriteFood,
        userName: store.userName,
        preferredModel: store.activeModel,
      );

      // Clean markdown code blocks from LLM if any
      String cleaned = rawResponse.trim();
      if (cleaned.startsWith('```')) {
        final lines = cleaned.split('\n');
        if (lines.length > 2) {
          cleaned = lines.sublist(1, lines.length - 1).join('\n').trim();
        }
      }

      final Map<String, dynamic> data = jsonDecode(cleaned);
      
      final newMemory = Memory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        personName: person.name,
        title: data['title'] ?? 'Magandang alaala',
        detail: data['detail'] ?? 'Isang masayang alaala kasama si ${person.name}.',
        category: data['category'] ?? 'Pamilya',
        when: 'Ngayong araw',
        timestamp: DateTime.now(),
        location: data['location'] ?? 'Tahanan',
        emotion: data['emotion'] ?? 'Masaya',
        tags: List<String>.from(data['tags'] ?? ['pamilya']),
      );

      await store.addMemory(newMemory);
    } catch (e) {
      debugPrint('Memory generation error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingMemory = false;
          _generatedPeople.add(person.name);
        });
      }
    }
  }



  void _showTimelineSheet(BuildContext context, Person person, List<Memory> personMemories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFDF9), // cream
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9DFC8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${person.name} (${person.relationship})',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2C1E1B),
                            ),
                          ),
                          Text(
                            'Mga pinagsaluhang alaala · ${person.visits} na pagbisita',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8B8276),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onNavigateToTab != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A359),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.people_rounded, size: 16),
                        label: Text(
                          MemoryStore.instance.translate(tagalog: 'Tingnan ang Profile', english: 'View Profile'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // close sheet
                          widget.onNavigateToTab!(3); // switch to Family Profile tab!
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (personMemories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Wala pang nakatalang alaala sa taong ito.',
                        style: TextStyle(color: Color(0xFF8B8276)),
                      ),
                    ),
                  )
                else
                  ...personMemories.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (m.category == 'Kalusugan'
                                            ? const Color(0xFF6FA7E8)
                                            : const Color(0xFFF39C7D))
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    m.category,
                                    style: TextStyle(
                                      color: m.category == 'Kalusugan'
                                          ? const Color(0xFF6FA7E8)
                                          : const Color(0xFFF39C7D),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  m.when,
                                  style: const TextStyle(
                                    color: Color(0xFF8B8276),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              m.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C1E1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              m.detail,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF5A5247),
                                height: 1.4,
                              ),
                            ),
                            if (m.location.isNotEmpty || m.emotion.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (m.location.isNotEmpty) ...[
                                    const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF8B8276)),
                                    const SizedBox(width: 4),
                                    Text(
                                      m.location,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF8B8276)),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  if (m.emotion.isNotEmpty) ...[
                                    const Icon(Icons.mood_rounded, size: 14, color: Color(0xFF8B8276)),
                                    const SizedBox(width: 4),
                                    Text(
                                      m.emotion,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF8B8276)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRegistrationSheet(BuildContext context) async {
    final result = await Navigator.of(context).push<Person>(
      MaterialPageRoute(builder: (_) => const MLFaceScannerScreen()),
    );

    if (result != null && context.mounted) {
      setState(() {
        _lockedPerson = result;
        _generatedPeople.clear();
      });
      _checkAndGenerateMemory(result);
    }
  }



  @override
  Widget build(BuildContext context) {
    final store = MemoryStore.instance;

    // Determine current person from stable face lock
    final activePerson = _lockedPerson;

    final latestMemory = (activePerson != null && store.memories.isNotEmpty)
        ? store.memories.firstWhere((m) => m.personName == activePerson.name, orElse: () => store.memories.first)
        : null;

    final personMemories = activePerson != null
        ? store.memories.where((m) => m.personName == activePerson.name).toList()
        : <Memory>[];

    final displayRelation = (activePerson != null) ? () {
      final rel = activePerson.relationship.toLowerCase();
      if (rel == 'anak') {
        return store.translate(tagalog: 'Anak', english: 'Child');
      } else if (rel == 'doktor' || rel == 'doctor') {
        return store.translate(tagalog: 'Doktor', english: 'Doctor');
      } else if (rel == 'caregiver') {
        return store.translate(tagalog: 'Tagapag-alaga', english: 'Caregiver');
      }
      return activePerson.relationship;
    }() : '';

    return ListenableBuilder(
      listenable: store,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        
        double cardLeft;
        double cardTop;
        
        if (_detectedFaceRect != null && _cameraImageSize != null) {
          final imageSize = _cameraImageSize!;
          final sensorOrientation = _cameraController?.description.sensorOrientation ?? 90;
          
          final isRotated = sensorOrientation == 90 || sensorOrientation == 270;
          final double srcWidth = isRotated ? imageSize.height : imageSize.width;
          final double srcHeight = isRotated ? imageSize.width : imageSize.height;

          final double scaleX = screenSize.width / srcWidth;
          final double scaleY = screenSize.height / srcHeight;

          double left = _detectedFaceRect!.left * scaleX;
          double top = _detectedFaceRect!.top * scaleY;
          double width = _detectedFaceRect!.width * scaleX;
          double height = _detectedFaceRect!.height * scaleY;

          if (_cameraController?.description.lensDirection == CameraLensDirection.front) {
            left = screenSize.width - left - width;
          }

          final centerX = left + (width / 2);
          final centerY = top + (height / 2);

          // Center exactly on the face center without clamps
          cardLeft = centerX - 121;
          cardTop = centerY - 95;
        } else {
          // If no face is detected, set default position (not rendered, but initialized)
          cardLeft = (screenSize.width - 242) / 2;
          cardTop = (screenSize.height - 332) / 2 - 30;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // Live Camera View / Dark Camera View Simulator Background
            _isCameraInitialized && _cameraController != null
                ? CameraPreview(_cameraController!)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF4C453C), // Warm charcoal
                          Color(0xFF1E1A16), // Dark brownish black
                        ],
                      ),
                    ),
                  ),

            // Simulated Camera Grid Lines (Apple style overlay)
            Opacity(
              opacity: 0.1,
              child: GridPaper(
                color: Colors.white,
                divisions: 2,
                interval: 160,
                subdivisions: 1,
              ),
            ),

            // Bottom camera feedback instructions
            Positioned(
              top: 70,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/applogo.png',
                        width: 18,
                        height: 18,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'MemoryLens AR Mode'.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          letterSpacing: 2,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    store.translate(
                      tagalog: 'Itaas ang camera sa tapat ng mukha ng pamilya',
                      english: 'Point camera at your family member\'s face',
                    ),
                    style: const TextStyle(
                      color: Color(0xFFFFFDF9),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            // Pulsing target scanner overlay when no face is active
            if (_detectedFaceRect == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.15),
                      duration: const Duration(seconds: 1),
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD4A359).withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFD4A359).withValues(alpha: 0.25),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        store.translate(
                          tagalog: 'Naghahanap ng mukha...',
                          english: 'Scanning for face...',
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Orbiting Info Cards + Bounding Frame Area positioned dynamically around the detected face
            if (_detectedFaceRect != null)
              Positioned(
                left: cardLeft,
                top: cardTop,
                width: 242,
                child: activePerson != null
                    // ── KNOWN PERSON: show full Polaroid card ──
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isGeneratingMemory) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4A359).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFD4A359), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4A359)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    store.translate(tagalog: 'Lumilikha ng alaala...', english: 'Creating memory...'),
                                    style: const TextStyle(
                                      color: Color(0xFFD4A359),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          // The Custom Polaroid Bounding Box
                          PolaroidFrame(
                            person: activePerson,
                            latestMemory: latestMemory,
                            onTap: () => _showTimelineSheet(context, activePerson, personMemories),
                          ),
                          const SizedBox(height: 8),
                          // Unlock button to clear the locked person
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _lockedPerson = null;
                                _generatedPeople.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    store.translate(tagalog: 'I-clear', english: 'Clear'),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Orbiting Information Indicators (Apple Vision Pro inspired)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              _OrbitCard(
                                icon: Icons.star,
                                color: const Color(0xFFCFAE68),
                                label: displayRelation,
                              ),
                              if (activePerson.birthday.isNotEmpty)
                                _OrbitCard(
                                  icon: Icons.cake,
                                  color: const Color(0xFFF39C7D),
                                  label: store.translate(
                                    tagalog: 'Kaarawan: ${activePerson.birthday}',
                                    english: 'Birthday: ${activePerson.birthday}',
                                  ),
                                ),
                              _OrbitCard(
                                icon: Icons.restaurant_menu,
                                color: const Color(0xFF5FA86A),
                                label: store.translate(
                                    tagalog: 'Gusto: ${activePerson.favoriteFood}',
                                    english: 'Likes: ${activePerson.favoriteFood}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    // ── UNKNOWN FACE: show 'Who is this?' selector ──
                    : _WhoIsThisSelector(
                        people: store.people,
                        onSelect: (person) {
                          setState(() {
                            _lockedPerson = person;
                            _generatedPeople.clear();
                          });
                          _checkAndGenerateMemory(person);
                        },
                        onRegister: () => _showRegistrationSheet(context),
                        store: store,
                      ),
              ),



            // Bottom controls removed to run purely dynamically on live face detection
          ],
        );
      },
    );
  }
}

// Small floating information chips surrounding the Polaroid
class _OrbitCard extends StatelessWidget {
  const _OrbitCard({required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xDCFFFDF9), // high opacity glassmorphism
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C1E1B),
            ),
          ),
        ],
      ),
    );
  }
}

// "Who is this?" picker – shown when ML Kit detects a face but we don't know who.
// The user selects the person manually; AR then locks to that person's profile.
class _WhoIsThisSelector extends StatelessWidget {
  const _WhoIsThisSelector({
    required this.people,
    required this.onSelect,
    required this.onRegister,
    required this.store,
  });

  final List<Person> people;
  final void Function(Person) onSelect;
  final VoidCallback onRegister;
  final MemoryStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 242,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xF2FFFDF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCFAE68), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon + heading
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFCFAE68).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.face_unlock_rounded,
              size: 36,
              color: Color(0xFFCFAE68),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            store.translate(tagalog: 'Sino ito?', english: 'Who is this?'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2C1E1B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            store.translate(
              tagalog: 'Piliin ang tao mula sa listahan',
              english: 'Select this person from your list',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8C7B6E),
            ),
          ),
          const SizedBox(height: 14),
          // List of registered people
          if (people.isEmpty)
            Text(
              store.translate(
                tagalog: 'Walang naka-rehistro pa',
                english: 'No registered people yet',
              ),
              style: const TextStyle(fontSize: 12, color: Color(0xFF8C7B6E)),
            )
          else
            ...people.map((p) => GestureDetector(
                  onTap: () => onSelect(p),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE9DFC8), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFCFAE68).withValues(alpha: 0.2),
                          backgroundImage: p.photoPath.isNotEmpty
                              ? FileImage(File(p.photoPath))
                              : null,
                          child: p.photoPath.isEmpty
                              ? Text(
                                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFCFAE68),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C1E1B),
                                ),
                              ),
                              Text(
                                p.relationship,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8C7B6E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFFCFAE68), size: 20),
                      ],
                    ),
                  ),
                )),
          const SizedBox(height: 4),
          // Register new person button
          GestureDetector(
            onTap: onRegister,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFCFAE68).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCFAE68), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_rounded, color: Color(0xFFCFAE68), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    store.translate(tagalog: 'Bagong Tao', english: 'Register New'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFCFAE68),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Step-by-step angle calibration registration bottom sheet
class RegistrationBottomSheet extends StatefulWidget {
  const RegistrationBottomSheet({super.key});

  @override
  State<RegistrationBottomSheet> createState() => _RegistrationBottomSheetState();
}

class _RegistrationBottomSheetState extends State<RegistrationBottomSheet> {
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _favoriteController = TextEditingController();
  final _birthdayController = TextEditingController();

  int _step = 0; // 0 = Calibration, 1 = Form
  bool _isCalibrating = false;
  int _activeAngle = 0; // 0=Front, 1=Left, 2=Right, 3=Smile
  final List<bool> _anglesCompleted = [false, false, false, false];
  final List<String> _angleLabels = ['Harap', 'Kaliwa', 'Kanan', 'Ngiti'];

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _favoriteController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  void _startCalibrationSim() {
    setState(() {
      _isCalibrating = true;
    });

    // Simulate scanning each angle in sequence with 1.2-second intervals
    Timer.periodic(const Duration(milliseconds: 1100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _anglesCompleted[_activeAngle] = true;
        if (_activeAngle < 3) {
          _activeAngle++;
        } else {
          timer.cancel();
          _isCalibrating = false;
          _step = 1; // proceed to info inputs
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = const Color(0xFFCFAE68);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE9DFC8),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (_step == 0) ...[
            // Angle calibration view
            const Icon(
              Icons.face_retouching_natural_rounded,
              size: 54,
              color: Color(0xFFCFAE68),
            ),
            const SizedBox(height: 12),
            const Text(
              'Magrehistro ng Mukha',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C1E1B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'I-scan natin ang iba\'t ibang anggulo ng mukha upang mas makilala siya nang maayos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B6257),
              ),
            ),
            const SizedBox(height: 24),

            // Calibration Angles Indicator Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                final completed = _anglesCompleted[index];
                final active = _activeAngle == index && _isCalibrating;

                return Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed
                            ? const Color(0xFF5FA86A)
                            : active
                                ? goldColor.withValues(alpha: 0.2)
                                : const Color(0xFFF3ECE0),
                        border: Border.all(
                          color: completed
                              ? const Color(0xFF5FA86A)
                              : active
                                  ? goldColor
                                  : const Color(0xFFE9DFC8),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: completed
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                            : active
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                                    ),
                                  )
                                : const Icon(Icons.photo_camera_front_rounded, color: Color(0xFF8B8276)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _angleLabels[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: completed || active ? FontWeight.bold : FontWeight.normal,
                        color: completed
                            ? const Color(0xFF5FA86A)
                            : active
                                ? goldColor
                                : const Color(0xFF8B8276),
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _isCalibrating ? null : _startCalibrationSim,
              style: FilledButton.styleFrom(
                backgroundColor: goldColor,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isCalibrating ? 'Sini-simulate ang scan...' : 'Simulan ang Face Scan',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            // Form information view
            const Text(
              'Pagkakakilanlan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C1E1B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'I-save natin ang kanyang impormasyon para sa iyong memorya.',
              style: TextStyle(fontSize: 13, color: Color(0xFF756A5B)),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Pangalan (hal. Anna Santos)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFFFFDF9),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relasyon sa iyo (hal. Anak, Doktor, Kapitbahay)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFFFFDF9),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _favoriteController,
              decoration: const InputDecoration(
                labelText: 'Paboritong Pagkain o Regalo (hal. Halo-halo)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFFFFDF9),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _birthdayController,
              decoration: const InputDecoration(
                labelText: 'Kaarawan (hal. Oktubre 12)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFFFFFDF9),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: () {
                final name = _nameController.text.trim();
                final relation = _relationshipController.text.trim();
                final fav = _favoriteController.text.trim();
                final birthday = _birthdayController.text.trim();

                if (name.isNotEmpty && relation.isNotEmpty) {
                  Navigator.pop(
                    context,
                    Person(
                      name: name,
                      relationship: relation,
                      detail: 'Bagong rehistradong miyembro ng pamilya.',
                      favoriteFood: fav.isEmpty ? 'Kuwentuhan' : fav,
                      birthday: birthday,
                      visits: 1,
                      lastSeen: DateTime.now(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Punan ang Pangalan at Relasyon.'),
                      backgroundColor: Color(0xFFD26B6B),
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5FA86A), // Success green
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'I-save sa Device',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
