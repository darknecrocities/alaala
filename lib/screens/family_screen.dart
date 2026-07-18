import 'package:flutter/material.dart';
import '../services/memory_store.dart';
import '../models/person.dart';
import '../models/memory.dart';
import '../widgets/custom_card.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  void _addCaregiverNoteSheet(BuildContext context, Person person) {
    final noteController = TextEditingController();
    final titleController = TextEditingController();
    String selectedCategory = 'Pagbisita';
    final categories = ['Pagbisita', 'Pangako', 'Kalusugan', 'Pamilya'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFDF9), // cream
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Mag-iwan ng Note para kay Lola',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF383229),
                    ),
                  ),
                  Text(
                    'Ito ay babasahin o ipapaalala kay Maria.',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF756A5B)),
                  ),
                  const SizedBox(height: 18),

                  // Title Input
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Pamagat ng Note (hal. Pag-inom ng vitamins)',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFFFFDF9),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Detail Input
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mga detalye (hal. Dinalhan ko si lola ng mangga at pinainom ko siya ng vitamins...)',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFFFFDF9),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  const Text(
                    'Kategorya:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF383229)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() {
                              selectedCategory = cat;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Submit note button
                  FilledButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final note = noteController.text.trim();

                      if (title.isNotEmpty && note.isNotEmpty) {
                        final store = MemoryStore.instance;
                        
                        // 1. Create a memory entry
                        final newMemory = Memory(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: title,
                          detail: note,
                          when: 'Ngayon',
                          category: selectedCategory,
                          personName: person.name,
                          timestamp: DateTime.now(),
                          emotion: 'Masaya',
                        );
                        store.addMemory(newMemory);

                        // 2. Add note details to the person record
                        store.addNoteToPerson(person.name, '$title: $note');

                        // 3. Increment visits since caregiver/person interacted
                        store.incrementVisits(person.name);

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Matagumpay na naidagdag ang caregiver note!'),
                            backgroundColor: Color(0xFF5FA86A),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Paki-fill up lahat ng text box.'),
                            backgroundColor: Color(0xFFD26B6B),
                          ),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFCFAE68), // Gold
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'I-save ang Note',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = MemoryStore.instance;
    final familyColor = const Color(0xFFF39C7D);

    return ListenableBuilder(
      listenable: store,
      builder: (context, child) {
        final people = store.people;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 32),
          children: [
            // Header
            Text(
              'Aking Pamilya',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF383229),
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mga taong malapit sa iyo na tumutulong sa iyong araw-araw.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7C7265),
              ),
            ),
            const SizedBox(height: 24),

            // Family members list
            ...people.map((p) {
              // Highlight label mapping for relationship tags
              String relationTag = p.relationship;
              Color tagColor = familyColor;

              if (p.relationship.toLowerCase().contains('doktor') ||
                  p.relationship.toLowerCase().contains('physician') ||
                  p.relationship.toLowerCase().contains('nurse')) {
                relationTag = '🩺 ${p.relationship}';
                tagColor = const Color(0xFF6FA7E8);
              } else {
                relationTag = '❤️ $relationTag';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  padding: const EdgeInsets.all(12),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: tagColor.withValues(alpha: 0.12),
                      radius: 24,
                      child: Text(
                        p.name[0],
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: tagColor,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: Color(0xFF383229),
                      ),
                    ),
                    subtitle: Text(
                      '$relationTag · ${p.visits} na pagbisita',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B6257),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(color: Color(0xFFE9DFC8)),
                            const SizedBox(height: 6),
                            Text(
                              'Iba pang detalye: ${p.detail}',
                              style: const TextStyle(color: Color(0xFF5A5247), fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            if (p.favoriteFood.isNotEmpty) ...[
                              Text(
                                'Paboritong pagkain: ${p.favoriteFood}',
                                style: const TextStyle(color: Color(0xFF5A5247), fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                            ],
                            
                            // Notes list
                            if (p.notes.isNotEmpty) ...[
                              const Text(
                                'Kamakailang Notes:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF383229)),
                              ),
                              const SizedBox(height: 4),
                              ...p.notes.map((note) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '• $note',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B6257)),
                                    ),
                                  )),
                            ],
                            const SizedBox(height: 14),

                            // Caregiver Action Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _addCaregiverNoteSheet(context, p),
                                  icon: const Icon(Icons.note_add_rounded, size: 16),
                                  label: const Text('Mag-iwan ng Note'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFCFAE68),
                                    side: const BorderSide(color: Color(0xFFCFAE68)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
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
