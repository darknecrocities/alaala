import 'dart:io';
import 'package:flutter/material.dart';
import '../services/memory_store.dart';
import '../models/person.dart';
import '../models/memory.dart';
import '../widgets/custom_card.dart';
import '../widgets/app_header.dart';
import '../widgets/fade_in_slide.dart';
import 'ml_face_scanner_screen.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  void _addCaregiverNoteSheet(BuildContext context, Person person) {
    final noteController = TextEditingController();
    final titleController = TextEditingController();
    String selectedCategory = 'Pagbisita';
    final categories = ['Pagbisita', 'Pangako', 'Kalusugan', 'Pamilya'];
    final store = MemoryStore.instance;

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
                    store.translate(tagalog: 'Mag-iwan ng Note para kay Lola', english: 'Leave a Note for Grandma'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF383229),
                    ),
                  ),
                  Text(
                    store.translate(tagalog: 'Ito ay babasahin o ipapaalala kay Maria.', english: 'This will be read or reminded to Maria.'),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF756A5B)),
                  ),
                  const SizedBox(height: 18),

                  // Title Input
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: store.translate(tagalog: 'Pamagat ng Note (hal. Pag-inom ng vitamins)', english: 'Note Title (e.g., Take vitamins)'),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: const Color(0xFFFFFDF9),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Detail Input
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: store.translate(tagalog: 'Mga detalye (hal. Dinalhan ko si lola ng mangga...)', english: 'Details (e.g., Brought grandma mangoes...)'),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: const Color(0xFFFFFDF9),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  Text(
                    store.translate(tagalog: 'Kategorya:', english: 'Category:'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF383229)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      
                      String catLabel = cat;
                      if (cat == 'Pagbisita') {
                        catLabel = store.translate(tagalog: 'Pagbisita', english: 'Visit');
                      } else if (cat == 'Pangako') {
                        catLabel = store.translate(tagalog: 'Pangako', english: 'Promise');
                      } else if (cat == 'Kalusugan') {
                        catLabel = store.translate(tagalog: 'Kalusugan', english: 'Health');
                      } else if (cat == 'Pamilya') {
                        catLabel = store.translate(tagalog: 'Pamilya', english: 'Family');
                      }

                      return ChoiceChip(
                        label: Text(catLabel),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setSheetState(() {
                              selectedCategory = cat;
                            });
                          }
                        },
                        selectedColor: const Color(0xFFD4A359).withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF2C1E1B) : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  FilledButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final note = noteController.text.trim();

                      if (title.isNotEmpty && note.isNotEmpty) {
                        final memory = Memory(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          personName: person.name,
                          title: title,
                          detail: note,
                          category: selectedCategory,
                          when: store.translate(tagalog: 'Kamakailan', english: 'Recently'),
                          timestamp: DateTime.now(),
                          location: store.translate(tagalog: 'Tahanan', english: 'Home'),
                          emotion: store.translate(tagalog: 'Masaya', english: 'Happy'),
                        );

                        // Save Note both locally and in Firestore
                        store.addMemory(memory);
                        store.addNoteToPerson(person.name, '$title: $note');
                        store.incrementVisits(person.name);

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              store.translate(
                                tagalog: 'Matagumpay na naidagdag ang caregiver note!',
                                english: 'Successfully added caregiver note!',
                              ),
                            ),
                            backgroundColor: const Color(0xFF5FA86A),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              store.translate(
                                tagalog: 'Paki-fill up lahat ng text box.',
                                english: 'Please fill up all text fields.',
                              ),
                            ),
                            backgroundColor: const Color(0xFFD26B6B),
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
                    child: Text(
                      store.translate(tagalog: 'I-save ang Note', english: 'Save Note'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            const AppHeader(),

            // Header info details
            FadeInSlide(
              delay: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.translate(tagalog: 'Aking Pamilya', english: 'My Family'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF383229),
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.translate(
                      tagalog: 'Mga taong malapit sa iyo na tumutulong sa iyong araw-araw.',
                      english: 'People close to you helping you every day.',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7C7265),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Register New Face AR scanner card
            FadeInSlide(
              delay: 80,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: CustomCard(
                  color: const Color(0xFFFFF6E5), // soft gold card
                  border: Border.all(color: const Color(0xFFFFE3A5), width: 1.5),
                  padding: const EdgeInsets.all(16),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MLFaceScannerScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Row(
                      children: [
                        // Circle Icon with scanner laser style
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCFAE68).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.face_retouching_natural_rounded,
                            color: Color(0xFFCFAE68),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.translate(
                                  tagalog: 'Mag-scan ng Bagong Mukha',
                                  english: 'Scan & Register New Face',
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2C1E1B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                store.translate(
                                  tagalog: 'Kumuha ng litrato at i-save ang impormasyon.',
                                  english: 'Take a photo and link their profile details.',
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7C7265),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFFCFAE68),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            ...people.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;

              final isMedical = p.relationship.toLowerCase().contains('doktor') ||
                  p.relationship.toLowerCase().contains('physician') ||
                  p.relationship.toLowerCase().contains('nurse') ||
                  p.relationship.toLowerCase().contains('doctor');
              
              final tagColor = isMedical ? const Color(0xFF6FA7E8) : familyColor;
              final relationIcon = isMedical ? Icons.medical_services_rounded : Icons.favorite_rounded;

              // Localized relationship label
              String displayRelation = p.relationship;
              if (p.relationship.toLowerCase() == 'anak') {
                displayRelation = store.translate(tagalog: 'Anak', english: 'Child');
              } else if (p.relationship.toLowerCase() == 'doktor' || p.relationship.toLowerCase() == 'doctor') {
                displayRelation = store.translate(tagalog: 'Doktor', english: 'Doctor');
              } else if (p.relationship.toLowerCase() == 'caregiver') {
                displayRelation = store.translate(tagalog: 'Tagapag-alaga', english: 'Caregiver');
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FadeInSlide(
                  delay: 150 + (index * 60), // Staggered delays
                  child: CustomCard(
                    padding: const EdgeInsets.all(12),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: tagColor.withValues(alpha: 0.12),
                        radius: 24,
                        backgroundImage: p.photoPath.isNotEmpty
                            ? FileImage(File(p.photoPath))
                            : null,
                        child: p.photoPath.isEmpty
                            ? Text(
                                p.name[0],
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: tagColor,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: Color(0xFF2C1E1B),
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(relationIcon, size: 14, color: tagColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              store.translate(
                                tagalog: '$displayRelation · ${p.visits} na pagbisita',
                                english: '$displayRelation · ${p.visits} visits',
                              ),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B6257),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                                store.translate(
                                  tagalog: 'Iba pang detalye: ${p.detail}',
                                  english: 'Key details: ${p.detail}',
                                ),
                                style: const TextStyle(color: Color(0xFF5A5247), fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              if (p.favoriteFood.isNotEmpty) ...[
                                Text(
                                  store.translate(
                                    tagalog: 'Paboritong pagkain: ${p.favoriteFood}',
                                    english: 'Favorite food: ${p.favoriteFood}',
                                  ),
                                  style: const TextStyle(color: Color(0xFF5A5247), fontSize: 13),
                                ),
                                const SizedBox(height: 6),
                              ],
                              
                              if (p.notes.isNotEmpty) ...[
                                Text(
                                  store.translate(tagalog: 'Kamakailang Notes:', english: 'Recent Notes:'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2C1E1B)),
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

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () => _addCaregiverNoteSheet(context, p),
                                    icon: const Icon(Icons.note_add_rounded, size: 16),
                                    label: Text(
                                      store.translate(tagalog: 'Mag-iwan ng Note', english: 'Leave a Note'),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFD4A359),
                                      side: const BorderSide(color: Color(0xFFD4A359)),
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
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
