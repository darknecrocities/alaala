import 'dart:async';
import 'package:flutter/material.dart';
import '../models/person.dart';
import '../models/memory.dart';
import '../services/memory_store.dart';
import '../widgets/polaroid_frame.dart';
import '../widgets/custom_card.dart';

class LensScreen extends StatefulWidget {
  const LensScreen({super.key});

  @override
  State<LensScreen> createState() => _LensScreenState();
}

class _LensScreenState extends State<LensScreen> {
  bool _knownMode = true;
  String _simulatedSpeechResponse = '';
  Timer? _speechResetTimer;
  int _activePersonIndex = 0;

  @override
  void dispose() {
    _speechResetTimer?.cancel();
    super.dispose();
  }

  void _triggerVoiceQuestion(String question, String answer) {
    setState(() {
      _simulatedSpeechResponse = '🗣️ "$question"\n\n🤖 $answer';
    });
    _speechResetTimer?.cancel();
    _speechResetTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) {
        setState(() {
          _simulatedSpeechResponse = '';
        });
      }
    });
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
                Text(
                  '${person.name} (${person.relationship})',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF383229),
                  ),
                ),
                Text(
                  'Mga pinagsaluhang alaala · ${person.visits} na pagbisita',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8B8276),
                  ),
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
                                color: Color(0xFF383229),
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
    final result = await showModalBottomSheet<Person>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFDF9), // cream
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const RegistrationBottomSheet(),
    );

    if (result != null && context.mounted) {
      MemoryStore.instance.registerPerson(result);
      setState(() {
        _knownMode = true;
        _activePersonIndex = MemoryStore.instance.people.length - 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Matagumpay na nairehistro si ${result.name}!'),
          backgroundColor: const Color(0xFF5FA86A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MemoryStore.instance;
    final people = store.people;

    // Determine current person in simulation
    final activePerson = (people.isNotEmpty && _activePersonIndex < people.length)
        ? people[_activePersonIndex]
        : null;

    final latestMemory = activePerson != null
        ? store.memories.firstWhere((m) => m.personName == activePerson.name, orElse: () => store.memories.first)
        : null;

    final personMemories = activePerson != null
        ? store.memories.where((m) => m.personName == activePerson.name).toList()
        : <Memory>[];

    return ListenableBuilder(
      listenable: store,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Dark Camera View Simulator Background
            Container(
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
                      const Icon(Icons.auto_awesome, color: Color(0xFFFFDE8F), size: 18),
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
                  const Text(
                    'Itaas ang camera sa tapat ng mukha ng pamilya',
                    style: TextStyle(
                      color: Color(0xFFFFFDF9),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            // Orbiting Info Cards + Bounding Frame Area
            Center(
              child: _knownMode && activePerson != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // The Custom Polaroid Bounding Box
                        PolaroidFrame(
                          person: activePerson,
                          latestMemory: latestMemory,
                          onTap: () => _showTimelineSheet(context, activePerson, personMemories),
                        ),
                        const SizedBox(height: 24),
                        // Orbiting Information Indicators (Apple Vision Pro inspired)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            _OrbitCard(
                              icon: Icons.star,
                              color: const Color(0xFFCFAE68),
                              label: activePerson.relationship,
                            ),
                            if (activePerson.birthday.isNotEmpty)
                              _OrbitCard(
                                icon: Icons.cake,
                                color: const Color(0xFFF39C7D),
                                label: 'Kaarawan: ${activePerson.birthday}',
                              ),
                            _OrbitCard(
                              icon: Icons.restaurant_menu,
                              color: const Color(0xFF5FA86A),
                              label: 'Gusto: ${activePerson.favoriteFood}',
                            ),
                          ],
                        ),
                      ],
                    )
                  : _UnknownDetector(
                      onRegister: () => _showRegistrationSheet(context),
                    ),
            ),

            // Speech Prompt / Assistant Ballooon Overlay
            if (_simulatedSpeechResponse.isNotEmpty)
              Positioned(
                bottom: 150,
                left: 24,
                right: 24,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 12),
                        child: CustomCard(
                          color: const Color(0xFFFFFDF9),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Text(
                            _simulatedSpeechResponse,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF383229),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Bottom Simulator Bar: Camera Switch / Mode Toggle / Voice trigger
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cycle Person Simulation Button
                  IconButton(
                    onPressed: () {
                      if (people.isNotEmpty) {
                        setState(() {
                          _activePersonIndex = (_activePersonIndex + 1) % people.length;
                          _knownMode = true;
                        });
                      }
                    },
                    icon: const CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: Icon(Icons.people_rounded, color: Colors.white),
                    ),
                    tooltip: 'Magpalit ng Kakilala',
                  ),

                  // Hey Ala-ala Wake Button (Microphone shortcut)
                  GestureDetector(
                    onTap: () {
                      if (activePerson != null) {
                        _triggerVoiceQuestion(
                          'Sino ito?',
                          'Siya si ${activePerson.name}, ang iyong ${activePerson.relationship}. ${activePerson.detail}',
                        );
                      } else {
                        _triggerVoiceQuestion(
                          'Sino ito?',
                          'Hindi ko pa nakikilala ang taong ito. Maaari mo siyang irehistro gamit ang button sa gitna.',
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFAE68), // Gold
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mic, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            activePerson != null ? 'Tukuyin si ${activePerson.name}' : 'Tukuyin ito',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Unknown/Known Switcher
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _knownMode = !_knownMode;
                      });
                    },
                    icon: CircleAvatar(
                      backgroundColor: _knownMode ? Colors.black45 : const Color(0xFFD26B6B),
                      child: Icon(
                        _knownMode ? Icons.face_unlock_rounded : Icons.face_rounded,
                        color: Colors.white,
                      ),
                    ),
                    tooltip: 'Toggle Known/Unknown Sim',
                  ),
                ],
              ),
            ),
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
              color: Color(0xFF383229),
            ),
          ),
        ],
      ),
    );
  }
}

// Bounding box interface for unknown face matches
class _UnknownDetector extends StatelessWidget {
  const _UnknownDetector({required this.onRegister});
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 242,
      height: 332,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xECFFFDF9), // Translucent cream
        border: Border.all(color: const Color(0xFFE9DFC8), width: 4),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.face_retouching_off_rounded,
            size: 64,
            color: Color(0xFFD26B6B), // Danger/unrecognized red
          ),
          const SizedBox(height: 16),
          const Text(
            'Hindi pa Kilala',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF383229),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hindi pa namin kilala ang taong ito. Irehistro sila upang maitala.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF5A5247),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCFAE68), // Gold
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Irehistro ang Tao',
              style: TextStyle(fontWeight: FontWeight.bold),
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
                color: Color(0xFF383229),
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
                color: Color(0xFF383229),
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
