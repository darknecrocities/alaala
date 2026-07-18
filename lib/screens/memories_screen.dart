import 'package:flutter/material.dart';
import '../services/memory_store.dart';
import '../models/memory.dart';
import '../widgets/custom_card.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    setState(() {
      _searchQuery = query;
      _searchResults = MemoryStore.instance.searchMemories(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = MemoryStore.instance;
    final goldColor = const Color(0xFFCFAE68);
    final healthColor = const Color(0xFF6FA7E8);
    final familyColor = const Color(0xFFF39C7D);

    return ListenableBuilder(
      listenable: store,
      builder: (context, child) {
        // If query is empty, we show all memories in the timeline.
        // Otherwise we show the search results.
        final memoriesToDisplay = _searchQuery.isEmpty 
            ? store.memories 
            : (_searchResults['sources'] as List<Memory>);

        final aiAnswer = _searchResults['answer'] as String;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
          children: [
            // Screen Header
            Text(
              'Aking Alaala',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF383229),
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Magtanong tungkol sa iyong mga bilin, pangako, o pagbisita.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7C7265),
              ),
            ),
            const SizedBox(height: 20),

            // AI Search Input Bar
            TextField(
              controller: _searchController,
              onChanged: _runSearch,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFCFAE68)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _runSearch('');
                        },
                      )
                    : null,
                hintText: 'Hal: Ano ang ipinangako ni Anna?',
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
                  borderSide: BorderSide(color: goldColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // AI Answer Assistant Response Bubble
            if (_searchQuery.isNotEmpty) ...[
              CustomCard(
                color: const Color(0xFFFFF6E5), // soft gold highlight
                border: Border.all(color: const Color(0xFFFFE3A5), width: 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: goldColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Ala-ala Assistant'.toUpperCase(),
                          style: TextStyle(
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
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF383229),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      memoriesToDisplay.isNotEmpty
                          ? 'Batay sa natagpuang ${memoriesToDisplay.length} source memory.'
                          : 'Walang nahanap na tugmang alaala sa database.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B8276),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section Label
            Text(
              _searchQuery.isEmpty ? 'Timeline ng mga Alaala' : 'Mga Katugmang Alaala',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF383229),
              ),
            ),
            const SizedBox(height: 12),

            // List of Displayed Memories
            if (memoriesToDisplay.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off_rounded, size: 54, color: goldColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 10),
                    const Text(
                      'Walang mga alaalang nahanap.',
                      style: TextStyle(
                        color: Color(0xFF8B8276),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...memoriesToDisplay.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Indicator line
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
                        // Memory details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    m.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF383229),
                                    ),
                                  ),
                                  const Spacer(),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3ECE0),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '👤 ${m.personName}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B6257),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (m.emotion.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3ECE0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '😊 ${m.emotion}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B6257),
                                        ),
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
                );
              }),
          ],
        );
      },
    );
  }
}
