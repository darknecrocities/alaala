import 'package:flutter/material.dart';
import '../services/memory_store.dart';
import '../widgets/custom_card.dart';
import '../widgets/routine_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onCameraTap});
  final VoidCallback onCameraTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Map<String, dynamic> _orientationData;

  @override
  void initState() {
    super.initState();
    _orientationData = MemoryStore.instance.getDailyOrientation();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Kalusugan':
        return Icons.medication_rounded;
      case 'Pagkain':
        return Icons.restaurant_rounded;
      case 'Pamilya':
        return Icons.favorite_rounded;
      case 'Simbahan':
        return Icons.church_rounded;
      default:
        return Icons.calendar_today_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Kalusugan':
        return const Color(0xFF6FA7E8); // health blue
      case 'Pagkain':
        return const Color(0xFF5FA86A); // success/food green
      case 'Pamilya':
        return const Color(0xFFF39C7D); // family coral
      case 'Simbahan':
        return const Color(0xFFCFAE68); // gold
      default:
        return const Color(0xFF8B8276);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goldColor = const Color(0xFFCFAE68);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
      children: [
        // Greeting & Orientation
        Text(
          _orientationData['greeting'] as String,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF383229),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          _orientationData['date'] as String,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7C7265),
          ),
        ),
        const SizedBox(height: 20),

        // Sleep & Health Highlight Card
        CustomCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6FA7E8).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  color: Color(0xFF6FA7E8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Magandang pahinga',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF383229),
                      ),
                    ),
                    Text(
                      'Nakatulog ka ng 8 oras kagabi.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF756A5B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Daily Orient Card
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_sunny_rounded, color: goldColor, size: 26),
                  const SizedBox(width: 8),
                  const Text(
                    'Iyong araw ngayon',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF383229),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _orientationData['summary'] as String,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFF5A5247),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: widget.onCameraTap,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Sino ang kasama ko ngayon?'),
                style: FilledButton.styleFrom(
                  backgroundColor: goldColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Daily Routines Checklist Header
        Row(
          children: [
            const Text(
              'Mga Routine Ngayon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF383229),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Refresh orientation / routine state
                setState(() {
                  _orientationData = MemoryStore.instance.getDailyOrientation();
                });
              },
              child: const Text('I-refresh'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Routines Checklist
        ...(_orientationData['routines'] as List).map((r) {
          final item = r as Map<String, dynamic>;
          final category = item['category'] as String;
          return RoutineItem(
            time: item['time'] as String,
            title: item['title'] as String,
            category: category,
            color: _getCategoryColor(category),
            icon: _getCategoryIcon(category),
            isInitialDone: item['done'] as bool,
          );
        }),

        const SizedBox(height: 16),

        // Privacy Lock Card
        CustomCard(
          color: const Color(0xFFF3ECE0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.security_rounded,
                color: Color(0xFF5FA86A),
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pribado at Ligtas',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF383229),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ang lahat ng mukha, boses, at personal na alaala ay ligtas na nakaimbak lamang sa loob ng iyong device.',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF383229).withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
