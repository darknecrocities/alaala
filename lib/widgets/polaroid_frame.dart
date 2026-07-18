import 'package:flutter/material.dart';
import '../models/person.dart';
import '../models/memory.dart';
import 'sparkle_animation.dart';

class PolaroidFrame extends StatefulWidget {
  const PolaroidFrame({
    super.key,
    required this.person,
    required this.latestMemory,
    required this.onTap,
    this.confidence = 0.99,
  });

  final Person person;
  final Memory? latestMemory;
  final VoidCallback onTap;
  final double confidence;

  @override
  State<PolaroidFrame> createState() => _PolaroidFrameState();
}

class _PolaroidFrameState extends State<PolaroidFrame> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _sparkleTrigger = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Trigger sparkle immediately on build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _sparkleTrigger = true;
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFCFAE68);
    const familyColor = Color(0xFFF39C7D);

    return Center(
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gold pulsing outer boundary glow
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final glowIntensity = 8.0 + (_pulseController.value * 12.0);
                return Container(
                  width: 250,
                  height: 340,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: goldColor.withValues(alpha: 0.4 + (_pulseController.value * 0.3)),
                        blurRadius: glowIntensity,
                        spreadRadius: 1.0 + (_pulseController.value * 2.0),
                      ),
                    ],
                  ),
                );
              },
            ),
            // The Polaroid Frame itself
            Container(
              width: 242,
              height: 332,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF9), // cream white card border
                border: Border.all(color: const Color(0xFFE9DFC8), width: 3),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    // Simulated Photo Area (dashed borders or placeholder pattern)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3ECE0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE5D9C0),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(
                                Icons.face_rounded,
                                color: Color(0xFFD6C8AF),
                                size: 84,
                              ),
                            ),
                            // Positioned tiny polaroid star badge
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: goldColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.white, size: 10),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${(widget.confidence * 100).toInt()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Polaroid bottom note area
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '📸 ${widget.person.name}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF383229),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                '❤️ ${widget.person.relationship}',
                                style: const TextStyle(
                                  color: familyColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${widget.person.visits} visits',
                                style: const TextStyle(
                                  color: Color(0xFF8B8276),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          if (widget.person.favoriteFood.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '🥭 Mahilig sa: ${widget.person.favoriteFood}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5A5247),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (widget.latestMemory != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '💬 ${widget.latestMemory!.title}: ${widget.latestMemory!.detail}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF756A5B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // The Sparkle particle layer
            Positioned.fill(
              child: IgnorePointer(
                child: SparkleAnimation(trigger: _sparkleTrigger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
