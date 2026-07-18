import 'package:flutter/material.dart';
import '../services/memory_store.dart';
import '../models/memory.dart';
import '../widgets/custom_card.dart';
import '../widgets/app_header.dart';
import '../widgets/fade_in_slide.dart';

class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic> _searchResults = {
    'answer': '',
    'sources': <Memory>[],
  };
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _isSearching = true;
    });

    final results = await MemoryStore.instance.searchMemories(query);
    if (mounted && _searchQuery == query) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MemoryStore.instance;
    const goldColor = Color(0xFFD4A359);       // Ochre Gold
    const darkWood = Color(0xFF2C1E1B);        // Narra Wood Brown
    final healthColor = const Color(0xFF6FA7E8);
    final familyColor = const Color(0xFFF39C7D);

    return ListenableBuilder(
      listenable: store,
      builder: (context, child) {
        final memoriesToDisplay = _searchQuery.isEmpty 
            ? store.memories 
            : (_searchResults['sources'] as List<Memory>);

        final aiAnswer = _searchResults['answer'] as String;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            const AppHeader(),

            // Screen Header details
            FadeInSlide(
              delay: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.translate(tagalog: 'Aking Alaala', english: 'My Memories'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: darkWood,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.translate(tagalog: 'Magtanong tungkol sa iyong mga bilin, pangako, o pagbisita.', english: 'Ask about your family\'s schedules, promises, or visits.'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7C7265),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI Search Input Bar
            FadeInSlide(
              delay: 100,
              child: TextField(
                controller: _searchController,
                onChanged: _runSearch,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded, color: goldColor),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: goldColor),
                          ),
                        )
                      : _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _runSearch('');
                              },
                            )
                          : null,
                  hintText: store.translate(tagalog: 'Hal: Ano ang ipinangako ni Anna?', english: 'e.g., What did Anna promise?'),
                  filled: true,
                  fillColor: const Color(0xFFFFFDF9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE9DFC8), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE9DFC8), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: darkWood, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // AI Answer Assistant Response Bubble
            if (_searchQuery.isNotEmpty && !_isSearching) ...[
              FadeInSlide(
                delay: 150,
                child: CustomCard(
                  color: const Color(0xFFFFF6E5), // soft gold highlight
                  border: Border.all(color: const Color(0xFFFFE3A5), width: 1.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/applogo.png',
                            width: 20,
                            height: 20,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            store.translate(tagalog: 'Ala-ala Assistant', english: 'Ala-ala Assistant').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: goldColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        aiAnswer,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w800,
                          color: darkWood,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        memoriesToDisplay.isNotEmpty
                            ? store.translate(
                                tagalog: 'Batay sa natagpuang ${memoriesToDisplay.length} na tala.',
                                english: 'Based on ${memoriesToDisplay.length} matching memories.',
                              )
                            : store.translate(
                                tagalog: 'Walang nahanap na tugmang alaala sa database.',
                                english: 'No matching memories found in database.',
                              ),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8B8276),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section Label
            FadeInSlide(
              delay: 160,
              child: Text(
                _searchQuery.isEmpty
                    ? store.translate(tagalog: 'Timeline ng mga Alaala', english: 'Memories Timeline')
                    : store.translate(tagalog: 'Mga Katugmang Alaala', english: 'Matching Memories'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: darkWood,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // List of Displayed Memories (Staggered Animations)
            if (memoriesToDisplay.isEmpty)
              FadeInSlide(
                delay: 200,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 54, color: goldColor.withValues(alpha: 0.5)),
                      const SizedBox(height: 10),
                      Text(
                        store.translate(tagalog: 'Walang mga alaalang nahanap.', english: 'No memories found.'),
                        style: const TextStyle(
                          color: Color(0xFF8B8276),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(memoriesToDisplay.length, (index) {
                final m = memoriesToDisplay[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FadeInSlide(
                    delay: 180 + (index * 60), // Staggered delay mapping
                    child: CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 6,
                            height: 72,
                            decoration: BoxDecoration(
                              color: m.category == 'Kalusugan' 
                                  ? healthColor 
                                  : m.category == 'Pangako'
                                      ? goldColor
                                      : familyColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: darkWood,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      m.when,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8B8276),
                                      ),
                                    ),
                                  ],
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
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3ECE0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF6B6257)),
                                          const SizedBox(width: 4),
                                          Text(
                                            m.personName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF6B6257),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (m.emotion.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3ECE0),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.sentiment_satisfied_alt_rounded, size: 12, color: Color(0xFF6B6257)),
                                            const SizedBox(width: 4),
                                            Text(
                                              _translateEmotion(m.emotion, store),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B6257),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  String _translateEmotion(String emotion, MemoryStore store) {
    switch (emotion.toLowerCase()) {
      case 'masaya':
      case 'happy':
        return store.translate(tagalog: 'Masaya', english: 'Happy');
      case 'malungkot':
      case 'sad':
        return store.translate(tagalog: 'Malungkot', english: 'Sad');
      case 'natutuwa':
      case 'glad':
        return store.translate(tagalog: 'Natutuwa', english: 'Glad');
      default:
        return emotion;
    }
  }
}
