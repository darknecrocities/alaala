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
  bool _isExpanded = false; // Controls Polaroid AR card detail expansion

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

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
    const goldColor = Color(0xFFD4A359);
    const darkWood = Color(0xFF2C1E1B);
    const familyColor = Color(0xFFF39C7D);

    return Stack(
      alignment: Alignment.center,
        children: [
          // pulsing boundary glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final glowIntensity = 8.0 + (_pulseController.value * 12.0);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 250,
                height: _isExpanded ? 460 : 340,
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

          // Custom Polaroid Photo Frame (Tactile / Heritage Style)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: CustomPaint(
              painter: PolaroidCardPainter(isExpanded: _isExpanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 242,
                height: _isExpanded ? 450 : 332,
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      // Fixed Height Viewfinder Area (Transparent cutout for live face framing)
                      Container(
                        height: 170,
                        width: double.infinity,
                        color: Colors.transparent,
                        child: Stack(
                          children: [
                            // Translucent target reticle
                            Center(
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: goldColor.withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.center_focus_weak_rounded,
                                    color: goldColor.withValues(alpha: 0.35),
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                            // Star recognition rating badge
                            Positioned(
                              top: 8,
                              right: 8,
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
                      const SizedBox(height: 8),

                      // Expandable Text details area
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.photo_camera_rounded, size: 16, color: darkWood),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.person.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: darkWood,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.favorite_rounded, size: 14, color: familyColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.person.relationship,
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
                              const SizedBox(height: 4),

                              // If expanded, show full long description details!
                              if (_isExpanded) ...[
                                const Divider(height: 12, color: Color(0xFFE9DFC8)),
                                Text(
                                  widget.person.detail,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: darkWood,
                                    height: 1.45,
                                  ),
                                ),
                              ],

                              // Favorite details row
                              if (widget.person.favoriteFood.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(Icons.restaurant_rounded, size: 12, color: Color(0xFF5A5247)),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Paborito: ${widget.person.favoriteFood}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF5A5247),
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: _isExpanded ? null : 1,
                                        overflow: _isExpanded ? null : TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // Latest Memory logs row
                              if (widget.latestMemory != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(Icons.chat_bubble_outline_rounded, size: 11, color: Color(0xFF756A5B)),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Bilin: ${widget.latestMemory!.title} - ${widget.latestMemory!.detail}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF756A5B),
                                          height: 1.4,
                                        ),
                                        maxLines: _isExpanded ? null : 1,
                                        overflow: _isExpanded ? null : TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Expand indicator chevron arrow (elegant design anchor)
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: goldColor,
                      ),
                    ],
                  ),
                ),
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
      );
  }
}

class PolaroidCardPainter extends CustomPainter {
  final bool isExpanded;
  PolaroidCardPainter({required this.isExpanded});

  @override
  void paint(Canvas canvas, Size size) {
    const creamColor = Color(0xFFFFFDF9);
    const borderColor = Color(0xFFE9DFC8);

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(24),
    );

    // 1. Draw Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(cardRect.shift(const Offset(0, 6)), shadowPaint);

    // 2. Draw Card Body Cream background with a cutout hole
    final bodyPaint = Paint()
      ..color = creamColor
      ..style = PaintingStyle.fill;
    
    // Viewfinder cutout fits padding 10 left/top/right, height 170
    final path = Path()
      ..addRRect(cardRect)
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(10, 10, size.width - 10, 180),
          const Radius.circular(16),
        ),
      );
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, bodyPaint);

    // 3. Draw Card Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(cardRect, borderPaint);

    // 4. Draw Inner Viewfinder Border
    final innerBorderPaint = Paint()
      ..color = const Color(0xFFD4A359).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(10, 10, size.width - 10, 180),
        const Radius.circular(16),
      ),
      innerBorderPaint,
    );
  }

  @override
  bool shouldRepaint(PolaroidCardPainter oldDelegate) {
    return oldDelegate.isExpanded != isExpanded;
  }
}
