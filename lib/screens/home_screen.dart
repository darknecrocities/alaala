import 'package:flutter/material.dart';
import '../services/memory_store.dart';
import '../widgets/custom_card.dart';
import '../widgets/routine_item.dart';
import '../widgets/app_header.dart';
import '../widgets/fade_in_slide.dart';

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

  String _getFormattedDate() {
    final now = DateTime.now();
    final store = MemoryStore.instance;
    final weekdaysTagalog = [
      'LINGGO',
      'LUNES',
      'MARTES',
      'MIYERKULES',
      'HUWEBES',
      'BIYERNES',
      'SABADO'
    ];
    final weekdaysEnglish = [
      'SUNDAY',
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY'
    ];
    final monthsTagalog = [
      'ENE',
      'PEB',
      'MAR',
      'ABR',
      'MAY',
      'HUN',
      'HUL',
      'AGO',
      'SET',
      'OKT',
      'NOB',
      'DIS'
    ];
    final monthsEnglish = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    
    final isTagalog = store.language == AppLanguage.tagalog;
    final weekday = isTagalog ? weekdaysTagalog[now.weekday % 7] : weekdaysEnglish[now.weekday % 7];
    final month = isTagalog ? monthsTagalog[now.month - 1] : monthsEnglish[now.month - 1];
    return '$weekday, $month ${now.day}';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final store = MemoryStore.instance;
    final name = store.userName;
    if (hour < 12) {
      return store.translate(
        tagalog: 'Magandang umaga, $name!',
        english: 'Good morning, $name!',
      );
    } else if (hour < 18) {
      return store.translate(
        tagalog: 'Magandang hapon, $name!',
        english: 'Good afternoon, $name!',
      );
    } else {
      return store.translate(
        tagalog: 'Magandang gabi, $name!',
        english: 'Good evening, $name!',
      );
    }
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
        return const Color(0xFFD4A359); // ochre gold
      default:
        return const Color(0xFF8B8276);
    }
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFD4A359);
    const darkWood = Color(0xFF2C1E1B);
    final store = MemoryStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, child) {
        // Recalculate orientation data dynamically when language changes
        _orientationData = store.getDailyOrientation();

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            const AppHeader(),

            // Greeting & Orientation
            FadeInSlide(
              delay: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getFormattedDate(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFF8B8276),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        '⛅ 29°C · Manila',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B8276),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: darkWood,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sleep & Health Highlight Card
            FadeInSlide(
              delay: 120,
              child: CustomCard(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.translate(tagalog: 'Magandang pahinga', english: 'Good rest'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: darkWood,
                            ),
                          ),
                          Text(
                            store.translate(tagalog: 'Nakatulog ka ng 8 oras kagabi.', english: 'You slept 8 hours last night.'),
                            style: const TextStyle(
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
            ),
            const SizedBox(height: 16),

            // Daily Orient Card
            FadeInSlide(
              delay: 190,
              child: CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_rounded, color: goldColor, size: 26),
                        const SizedBox(width: 8),
                        Text(
                          store.translate(tagalog: 'Iyong araw ngayon', english: 'Your day today'),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: darkWood,
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
                    InkWell(
                      onTap: widget.onCameraTap,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: darkWood,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: darkWood.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.white24,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.center_focus_weak_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store.translate(tagalog: 'Sino ang aking kasama?', english: 'Who is with me?'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    store.translate(tagalog: 'I-tap upang buksan ang scanner lens', english: 'Tap to open scanner lens'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white54,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Daily Routines Checklist Header
            FadeInSlide(
              delay: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        store.translate(tagalog: 'Mga Routine Ngayon', english: 'Today\'s Routines'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: darkWood,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _orientationData = store.getDailyOrientation();
                          });
                        },
                        child: Text(store.translate(tagalog: 'I-refresh', english: 'Refresh')),
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy Lock Card
            FadeInSlide(
              delay: 330,
              child: CustomCard(
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
                          Text(
                            store.translate(tagalog: 'Pribado at Ligtas', english: 'Private & Secure'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: darkWood,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            store.translate(
                              tagalog: 'Ang lahat ng mukha, boses, at personal na alaala ay ligtas na nakaimbak lamang sa loob ng iyong device.',
                              english: 'All faces, voices, and personal memories are securely stored only inside your device.',
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: darkWood.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
