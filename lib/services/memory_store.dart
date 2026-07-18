import 'package:flutter/foundation.dart';
import '../models/person.dart';
import '../models/memory.dart';

class MemoryStore extends ChangeNotifier {
  // Private constructor for singleton pattern
  MemoryStore._internal() {
    _initPresets();
  }

  static final MemoryStore instance = MemoryStore._internal();

  final List<Person> _people = [];
  final List<Memory> _memories = [];

  List<Person> get people => List.unmodifiable(_people);
  List<Memory> get memories => List.unmodifiable(_memories);

  void _initPresets() {
    _people.addAll([
      Person(
        name: 'Anna Santos',
        relationship: 'Anak',
        detail: 'Bumibisita linggo-linggo tuwing Sabado ng hapon.',
        favoriteFood: 'Sariwang Mangga at Tinola',
        birthday: 'Oktubre 12',
        visits: 42,
        lastSeen: DateTime.now().subtract(const Duration(days: 1)),
        notes: [
          'Sasamahan ka niya sa check-up sa Lunes.',
          'Dinala ang paborito mong hinog na mangga kahapon.',
        ],
      ),
      Person(
        name: 'Miguel Santos',
        relationship: 'Apo',
        detail: 'Grade 5 student na mahilig gumuhit ng mga tanawin.',
        favoriteFood: 'Halo-halo na may maraming leche flan',
        birthday: 'Enero 24',
        visits: 18,
        lastSeen: DateTime.now().subtract(const Duration(days: 4)),
        notes: [
          'Ipinakita ang kanyang bagong drowing ng bundok.',
          'Nangakong gagawa ng card para sa kaarawan ni Lola.',
        ],
      ),
      Person(
        name: 'Dr. Cruz',
        relationship: 'Doktor',
        detail: 'Family physician sa Barangay Health Center.',
        favoriteFood: 'Kapeng Barako',
        birthday: 'Marso 5',
        visits: 7,
        lastSeen: DateTime.now().subtract(const Duration(days: 3)),
        notes: [
          'Inabisuhan kang maglakad-lakad tuwing umaga.',
          'Sinuri ang iyong blood pressure at maayos ito.',
        ],
      ),
    ]);

    _memories.addAll([
      Memory(
        id: '1',
        title: 'Pangako ni Anna sa Gamot',
        detail: 'Nangako si Anna na sasamahan ka niya sa iyong check-up at bibili ng gamot para sa high blood sa botika pagkatapos.',
        when: 'Kahapon',
        category: 'Pangako',
        personName: 'Anna Santos',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        location: 'Bahay',
        emotion: 'Masaya',
        tags: ['check-up', 'gamot', 'pangako'],
      ),
      Memory(
        id: '2',
        title: 'Tanghalian kasama si Anna',
        detail: 'Kumain kayo ng mainit na chicken tinola para sa tanghalian. Nagdala siya ng sariwang mangga mula sa palengke.',
        when: 'Kahapon',
        category: 'Pagbisita',
        personName: 'Anna Santos',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        location: 'Kusina',
        emotion: 'Mainit',
        tags: ['tinola', 'mangga', 'tanghalian'],
      ),
      Memory(
        id: '3',
        title: 'Drowing ni Miguel',
        detail: 'Ipinakita ni Miguel ang kanyang drowing ng pamilya na nasa ilalim ng puno ng mangga. Sobrang ganda ng pagkakaguhit.',
        when: 'Noong isang linggo',
        category: 'Pamilya',
        personName: 'Miguel Santos',
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        location: 'Sala',
        emotion: 'Proud',
        tags: ['drowing', 'apo', 'larawan'],
      ),
      Memory(
        id: '4',
        title: 'Huling bilin ni Dr. Cruz',
        detail: 'Uminom ng gamot sa high blood pagkatapos kumain ng almusal. Magbawas sa maaalat at uminom ng maraming tubig.',
        when: 'Hulyo 15',
        category: 'Kalusugan',
        personName: 'Dr. Cruz',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        location: 'Klinika',
        emotion: 'Payapa',
        tags: ['reseta', 'gamot', 'doktor'],
      ),
    ]);
  }

  // Add a new memory
  void addMemory(Memory memory) {
    _memories.insert(0, memory);
    notifyListeners();
  }

  // Register a new person locally
  void registerPerson(Person person) {
    _people.add(person);
    notifyListeners();
  }

  // Increment visit count for a person
  void incrementVisits(String name) {
    final index = _people.indexWhere((p) => p.name.toLowerCase() == name.toLowerCase());
    if (index != -1) {
      _people[index] = _people[index].copyWith(
        visits: _people[index].visits + 1,
        lastSeen: DateTime.now(),
      );
      notifyListeners();
    }
  }

  // Add notes/promises dynamically to a person
  void addNoteToPerson(String name, String note) {
    final index = _people.indexWhere((p) => p.name.toLowerCase() == name.toLowerCase());
    if (index != -1) {
      final updatedNotes = List<String>.from(_people[index].notes)..add(note);
      _people[index] = _people[index].copyWith(notes: updatedNotes);
      notifyListeners();
    }
  }

  // Semantic Memory Search Simulator (Keyword weighting and Jaccard distance approximation)
  Map<String, dynamic> searchMemories(String query) {
    if (query.trim().isEmpty) {
      return {
        'answer': '',
        'sources': <Memory>[],
      };
    }

    final queryWords = query.toLowerCase()
        .replaceAll(RegExp(r'[?.,!@#\$%^&*()_\-+=|\\\[\]{};:\x27"<>\/]'), '')
        .split(' ')
        .where((w) => w.length > 2)
        .toList();

    if (queryWords.isEmpty) {
      // Fallback to basic string match if query is too short
      final simpleMatches = _memories.where((m) =>
        m.title.toLowerCase().contains(query.toLowerCase()) ||
        m.detail.toLowerCase().contains(query.toLowerCase())
      ).toList();

      return {
        'answer': simpleMatches.isNotEmpty 
            ? 'May nahanap akong mga alaala tungkol diyan. Narito ang mga detalye.'
            : 'Hindi ko nahanap ang alaala tungkol diyan. Maaari nating idagdag ito.',
        'sources': simpleMatches,
      };
    }

    final scoredMemories = <MapEntry<Memory, double>>[];

    for (final memory in _memories) {
      double score = 0.0;
      final textToSearch = '${memory.title} ${memory.detail} ${memory.personName} ${memory.category} ${memory.tags.join(" ")}'.toLowerCase();

      for (final word in queryWords) {
        if (textToSearch.contains(word)) {
          // Grant higher points for matching specific fields or tags
          if (memory.personName.toLowerCase().contains(word)) score += 3.0;
          if (memory.title.toLowerCase().contains(word)) score += 2.0;
          score += 1.0;
        }
      }

      if (score > 0.0) {
        scoredMemories.add(MapEntry(memory, score));
      }
    }

    // Sort by score in descending order
    scoredMemories.sort((a, b) => b.value.compareTo(a.value));
    final matchedMemories = scoredMemories.map((e) => e.key).toList();

    // Synthesize response based on top matches
    String answer = '';
    if (matchedMemories.isNotEmpty) {
      final best = matchedMemories.first;
      
      // Let's create smart templates for Taglish conversational responses based on matches
      if (query.toLowerCase().contains('pangako') || query.toLowerCase().contains('promis')) {
        if (best.category == 'Pangako' || best.detail.toLowerCase().contains('pangako') || best.detail.toLowerCase().contains('nangako')) {
          answer = 'Ayon sa aking alaala, nangako si ${best.personName} na: "${best.detail}". Nangyari ito noong ${best.when.toLowerCase()}.';
        } else {
          answer = 'Ito ang pinakamalapit na alaala tungkol sa pangako ni ${best.personName}: "${best.detail}".';
        }
      } else if (query.toLowerCase().contains('gamot') || query.toLowerCase().contains('med')) {
        answer = 'Tungkol sa gamot: ${best.detail} (mula sa alaala kasama si ${best.personName}, ${best.when.toLowerCase()}).';
      } else if (query.toLowerCase().contains('kain') || query.toLowerCase().contains('pagkain') || query.toLowerCase().contains('tinola') || query.toLowerCase().contains('mangga')) {
        answer = 'Ang naaalala ko tungkol sa pagkain ay: ${best.detail} kasama si ${best.personName}.';
      } else if (query.toLowerCase().contains('doctor') || query.toLowerCase().contains('check-up') || query.toLowerCase().contains('cruz')) {
        answer = 'Sabi ni ${best.personName}: "${best.detail}".';
      } else {
        answer = 'Narito ang aking natagpuan tungkol kay ${best.personName}: "${best.detail}" (${best.when}).';
      }
    } else {
      answer = 'Hindi ko nahanap ang alaala tungkol diyan, Maria. Gusto mo bang tanungin natin si Anna o irekord ito bilang bagong alaala?';
    }

    return {
      'answer': answer,
      'sources': matchedMemories,
    };
  }

  // Daily Orientation Generator
  Map<String, dynamic> getDailyOrientation() {
    final today = DateTime.now();
    final filipinoDays = ['Linggo', 'Lunes', 'Martes', 'Miyerkules', 'Huwebes', 'Biyernes', 'Sabado'];
    final filipinoMonths = [
      'Enero', 'Pebreo', 'Marso', 'Abril', 'Mayo', 'Junio', 
      'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre'
    ];

    final dayName = filipinoDays[today.weekday % 7];
    final monthName = filipinoMonths[today.month - 1];
    final dateString = '$dayName, $monthName ${today.day}, ${today.year}';

    // Find the next visits / routine events
    return {
      'date': dateString,
      'greeting': 'Magandang umaga, Maria.',
      'summary': 'Ngayong 3:00 PM, darating si Anna para bisitahin ka at magdadala siya ng paborito mong mangga. Mayroon ka ring nakatakdang check-up kay Dr. Cruz sa Lunes.',
      'routines': [
        {'time': '8:00 AM', 'title': 'Inumin ang gamot sa high blood', 'category': 'Kalusugan', 'done': true},
        {'time': '12:00 PM', 'title': 'Tanghalian (Chicken Adobo at Kanin)', 'category': 'Pagkain', 'done': false},
        {'time': '3:00 PM', 'title': 'Pagbisita ni Anna Santos (iyong anak)', 'category': 'Pamilya', 'done': false},
        {'time': '5:30 PM', 'title': 'Misa sa Parokya (Sunday Mass preparation)', 'category': 'Simbahan', 'done': false},
      ]
    };
  }
}
