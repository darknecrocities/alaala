import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person.dart';
import '../models/memory.dart';
import 'ai_client.dart';

enum AppLanguage { tagalog, english }

class MemoryStore extends ChangeNotifier {
  MemoryStore._internal() {
    _loadPresetPeople();
    _loadPresetMemories();
    _loadSavedLanguage();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _syncFromFirestore(user.uid);
      } else {
        _clearUserData();
      }
    });
  }

  static final MemoryStore instance = MemoryStore._internal();

  final List<Person> _people = [];
  final List<Memory> _memories = [];

  // User personalization variables
  String _userName = 'Maria';
  String _role = 'Patient';
  String _cognitiveChallenge = 'Madalas Makalimot (MCI)';
  List<String> _primaryRoutines = ['Uminom ng Gamot', 'Pagbisita ni Anna'];
  String _memoryContext = 'Si Anna Santos ang aking anak na bumibisita linggo-linggo. Si Dr. Cruz naman ang aking doktor.';

  // Selected AI model for RAG response
  AIModel _activeModel = AIModel.local;

  List<Person> get people => List.unmodifiable(_people);
  List<Memory> get memories => List.unmodifiable(_memories);

  String get userName => _userName;
  String get role => _role;
  String get cognitiveChallenge => _cognitiveChallenge;
  List<String> get primaryRoutines => List.unmodifiable(_primaryRoutines);
  String get memoryContext => _memoryContext;
  AIModel get activeModel => _activeModel;

  void setActiveModel(AIModel model) {
    _activeModel = model;
    notifyListeners();
  }

  AppLanguage _language = AppLanguage.tagalog;
  AppLanguage get language => _language;

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('app_language');
      if (saved != null) {
        _language = AppLanguage.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => AppLanguage.tagalog,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', lang.name);
    } catch (_) {}
  }

  String translate({required String tagalog, required String english}) {
    return _language == AppLanguage.tagalog ? tagalog : english;
  }

  void _loadPresetPeople() {
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
  }

  void _loadPresetMemories() {
    _memories.addAll([
      Memory(
        id: 'preset_1',
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
        id: 'preset_2',
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
        id: 'preset_3',
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
        id: 'preset_4',
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

  void _clearUserData() {
    _people.clear();
    _memories.clear();
    _loadPresetPeople();
    _loadPresetMemories();
    _userName = 'Maria';
    _role = 'Patient';
    _cognitiveChallenge = 'Madalas Makalimot (MCI)';
    _primaryRoutines = ['Uminom ng Gamot', 'Pagbisita ni Anna'];
    _memoryContext = 'Si Anna Santos ang aking anak na bumibisita linggo-linggo.';
    notifyListeners();
  }

  Future<void> _syncFromFirestore(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        _userName = data?['name'] ?? 'Maria';
        _role = data?['role'] ?? 'Patient';
        _cognitiveChallenge = data?['cognitiveChallenge'] ?? 'Madalas Makalimot (MCI)';
        _primaryRoutines = List<String>.from(data?['primaryRoutines'] ?? ['Uminom ng Gamot', 'Pagbisita ni Anna']);
        _memoryContext = data?['memoryContext'] ?? '';
      }

      final memoriesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('memories')
          .orderBy('timestamp', descending: true)
          .get();

      if (memoriesSnapshot.docs.isNotEmpty) {
        _memories.clear();
        _loadPresetMemories();
        for (final doc in memoriesSnapshot.docs) {
          if (_memories.any((m) => m.id == doc.id)) continue;
          final d = doc.data();
          _memories.insert(
            0,
            Memory(
              id: doc.id,
              title: d['title'] ?? '',
              detail: d['detail'] ?? '',
              when: d['when'] ?? '',
              category: d['category'] ?? '',
              personName: d['personName'] ?? '',
              timestamp: DateTime.tryParse(d['timestamp'] ?? '') ?? DateTime.now(),
              location: d['location'] ?? '',
              emotion: d['emotion'] ?? '',
            ),
          );
        }
      }

      final peopleSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('people')
          .get();

      if (peopleSnapshot.docs.isNotEmpty) {
        _people.clear();
        _loadPresetPeople();
        for (final doc in peopleSnapshot.docs) {
          final d = doc.data();
          if (_people.any((p) => p.name.toLowerCase() == (d['name'] as String).toLowerCase())) continue;
          _people.add(
            Person(
              name: d['name'] ?? '',
              relationship: d['relationship'] ?? '',
              detail: d['detail'] ?? '',
              favoriteFood: d['favoriteFood'] ?? '',
              birthday: d['birthday'] ?? '',
              visits: d['visits'] ?? 0,
              lastSeen: DateTime.tryParse(d['lastSeen'] ?? ''),
              notes: List<String>.from(d['notes'] ?? []),
              photoPath: d['photoPath'] ?? '',
            ),
          );
        }
      }
      notifyListeners();
    } catch (e) {
      // Offline fallback
    }
  }

  // Update profile and sync to Firestore
  Future<void> saveUserProfile({
    required String name,
    required String userRole,
    required String challenge,
    required List<String> routines,
    required String contextText,
  }) async {
    _userName = name;
    _role = userRole;
    _cognitiveChallenge = challenge;
    _primaryRoutines = routines;
    _memoryContext = contextText;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'role': userRole,
          'cognitiveChallenge': challenge,
          'primaryRoutines': routines,
          'memoryContext': contextText,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        // Ignored for offline support
      }
    }
  }

  // Add a new memory both locally and on Firestore
  Future<void> addMemory(Memory memory) async {
    _memories.insert(0, memory);
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('memories')
            .doc(memory.id)
            .set({
          'title': memory.title,
          'detail': memory.detail,
          'when': memory.when,
          'category': memory.category,
          'personName': memory.personName,
          'timestamp': memory.timestamp.toIso8601String(),
          'location': memory.location,
          'emotion': memory.emotion,
        });
      } catch (e) {
        // Ignored for offline support
      }
    }
  }

  // Wipes all user memory logs from local and Firestore database
  Future<void> clearAllMemories() async {
    _memories.clear();
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('memories')
            .get();
        for (final doc in query.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        // Ignored for offline support
      }
    }
  }

  // Register a new person locally and in Firestore
  Future<void> registerPerson(Person person) async {
    _people.add(person);
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('people')
            .doc(person.name.toLowerCase().replaceAll(' ', '_'))
            .set({
          'name': person.name,
          'relationship': person.relationship,
          'detail': person.detail,
          'favoriteFood': person.favoriteFood,
          'birthday': person.birthday,
          'visits': person.visits,
          'lastSeen': person.lastSeen?.toIso8601String(),
          'notes': person.notes,
          'photoPath': person.photoPath,
        });
      } catch (e) {
        // Ignored for offline support
      }
    }
  }

  Future<void> incrementVisits(String name) async {
    final index = _people.indexWhere((p) => p.name.toLowerCase() == name.toLowerCase());
    if (index != -1) {
      final updated = _people[index].copyWith(
        visits: _people[index].visits + 1,
        lastSeen: DateTime.now(),
      );
      _people[index] = updated;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('people')
              .doc(name.toLowerCase().replaceAll(' ', '_'))
              .update({
            'visits': updated.visits,
            'lastSeen': updated.lastSeen?.toIso8601String(),
          });
        } catch (e) {
          // Ignored
        }
      }
    }
  }

  Future<void> addNoteToPerson(String name, String note) async {
    final index = _people.indexWhere((p) => p.name.toLowerCase() == name.toLowerCase());
    if (index != -1) {
      final updatedNotes = List<String>.from(_people[index].notes)..add(note);
      _people[index] = _people[index].copyWith(notes: updatedNotes);
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('people')
              .doc(name.toLowerCase().replaceAll(' ', '_'))
              .update({
            'notes': updatedNotes,
          });
        } catch (e) {
          // Ignored
        }
      }
    }
  }

  // RAG assistant integrating AI REST client (OpenAI / Gemini / Local)
  Future<Map<String, dynamic>> searchMemories(String query) async {
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

    final matchedMemories = <Memory>[];

    if (queryWords.isEmpty) {
      // Fallback search
      matchedMemories.addAll(_memories.where((m) =>
          m.title.toLowerCase().contains(query.toLowerCase()) ||
          m.detail.toLowerCase().contains(query.toLowerCase())));
    } else {
      final scored = <MapEntry<Memory, double>>[];
      for (final memory in _memories) {
        double score = 0.0;
        final text = '${memory.title} ${memory.detail} ${memory.personName} ${memory.category}'.toLowerCase();
        for (final word in queryWords) {
          if (text.contains(word)) {
            if (memory.personName.toLowerCase().contains(word)) score += 3.0;
            if (memory.title.toLowerCase().contains(word)) score += 2.0;
            score += 1.0;
          }
        }
        if (score > 0.0) {
          scored.add(MapEntry(memory, score));
        }
      }
      scored.sort((a, b) => b.value.compareTo(a.value));
      matchedMemories.addAll(scored.map((e) => e.key));
    }

    // Build context string from the matched memories
    final contextBuffer = StringBuffer();
    for (int i = 0; i < matchedMemories.length && i < 3; i++) {
      final m = matchedMemories[i];
      contextBuffer.writeln('- [${m.category}] ${m.title} kasama si ${m.personName} (${m.when}): ${m.detail}');
    }

    // Call RAG Client
    final answer = await AIClient.instance.askAI(
      query: query,
      context: contextBuffer.toString(),
      userName: _userName,
      challenge: _cognitiveChallenge,
      memoryContext: _memoryContext,
      preferredModel: _activeModel,
    );

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
      'Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo', 
      'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre'
    ];
    final englishDays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final englishMonths = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final dayName = _language == AppLanguage.tagalog 
        ? filipinoDays[today.weekday % 7] 
        : englishDays[today.weekday % 7];
    final monthName = _language == AppLanguage.tagalog 
        ? filipinoMonths[today.month - 1] 
        : englishMonths[today.month - 1];
    final dateString = '$dayName, $monthName ${today.day}, ${today.year}';

    // Map selected routines with icon categories
    final routinesList = <Map<String, dynamic>>[];
    
    // Add default routines if none selected, otherwise map selected ones
    final rawRoutines = _primaryRoutines.isNotEmpty 
        ? _primaryRoutines 
        : ['Uminom ng Gamot', 'Pagbisita ni Anna'];

    int hour = 8;
    for (final r in rawRoutines) {
      String time = '$hour:00 AM';
      String cat = 'Pamilya';
      String translatedTitle = r;

      if (r.toLowerCase().contains('gamot') || r.toLowerCase().contains('med')) {
        cat = 'Kalusugan';
        time = '8:00 AM';
        translatedTitle = _language == AppLanguage.tagalog ? 'Uminom ng Gamot' : 'Take Medication';
      } else if (r.toLowerCase().contains('misa') || r.toLowerCase().contains('simba') || r.toLowerCase().contains('dasal') || r.toLowerCase().contains('church') || r.toLowerCase().contains('prayer')) {
        cat = 'Simbahan';
        time = '10:00 AM';
        translatedTitle = _language == AppLanguage.tagalog ? 'Magsimba o Magdasal' : 'Prayer or church';
      } else if (r.toLowerCase().contains('kain') || r.toLowerCase().contains('almusal') || r.toLowerCase().contains('tanghalian') || r.toLowerCase().contains('hapunan') || r.toLowerCase().contains('meal')) {
        cat = 'Pagkain';
        time = '12:00 PM';
        translatedTitle = _language == AppLanguage.tagalog ? 'Kumain ng Pagkain' : 'Eat Meals';
      } else if (r.toLowerCase().contains('bisita') || r.toLowerCase().contains('anna') || r.toLowerCase().contains('visit')) {
        translatedTitle = _language == AppLanguage.tagalog ? 'Pagbisita ni Anna' : 'Anna\'s Visit';
      }
      
      routinesList.add({
        'time': time,
        'title': translatedTitle,
        'category': cat,
        'done': false,
      });
      hour += 2;
    }

    final String greetingText = _language == AppLanguage.tagalog
        ? 'Magandang umaga, $_userName.'
        : 'Good morning, $_userName.';

    final String summaryText = _language == AppLanguage.tagalog
        ? 'Ngayon ay may ${_primaryRoutines.length} na mga nakatakdang gawain. Ang inyong pamilya ay nais ipaalala: "$_memoryContext"'
        : 'Today you have ${_primaryRoutines.length} scheduled routines. Your family wants to remind you: "$_memoryContext"';

    return {
      'date': dateString,
      'greeting': greetingText,
      'summary': summaryText,
      'routines': routinesList,
    };
  }
}
