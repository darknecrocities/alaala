import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/lens_screen.dart';
import 'screens/memories_screen.dart';
import 'screens/family_screen.dart';
import 'screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/memory_store.dart';
import 'services/ai_client.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAkFOWKJM3vhCOBSUpdtQ-g79dT4idesio',
      appId: '1:460442138245:android:f394cc09e7792cd2fb9bec',
      messagingSenderId: '460442138245',
      projectId: 'openai-dee53',
      storageBucket: 'openai-dee53.firebasestorage.app',
    ),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const AlaAlaApp());
}

class AlaAlaApp extends StatelessWidget {
  const AlaAlaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const beigeBackground = Color(0xFFFAF7F0); // Capiz Cream
    const goldAccent = Color(0xFFD4A359); // Ochre Gold
    const creamSurface = Color(0xFFFFFDF9); // Cream Card
    const darkText = Color(0xFF2C1E1B); // Narra Brown

    return MaterialApp(
      title: 'Ala-ala',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: beigeBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: goldAccent,
          surface: creamSurface,
        ),
        textTheme: GoogleFonts.cormorantGaramondTextTheme(
          ThemeData.light().textTheme,
        ).apply(
          bodyColor: darkText,
          displayColor: darkText,
        ),
        cardTheme: const CardThemeData(
          color: creamSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const MainAppShell(),
    );
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentTab = 0;
  
  // Domo AI Assistant Fixed State
  bool _isDomoDialogOpen = false;
  AIModel _selectedDomoModel = AIModel.gemini;

  // Domo Chat Dialogue Properties
  List<DomoChatMessage> _domoMessages = [];
  final _domoChatController = TextEditingController();
  final _domoScrollController = ScrollController();
  bool _domoIsTyping = false;

  // TTS Engine
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _checkRememberMeState();
    _initializeDomoWelcomeMessage();
    _initTts();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _domoChatController.dispose();
    _domoScrollController.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("fil-PH");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.78); // Slower, clear voice speed for senior citizens
      _flutterTts.setErrorHandler((msg) {
        debugPrint("TTS Error: $msg");
      });
    } catch (e) {
      debugPrint("TTS Setup Error: $e");
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    if (text.isNotEmpty) {
      // Strips emojis and double asterisks/markdown from speech text for a cleaner spoken response
      final cleanText = text
          .replaceAll(RegExp(r'\*\*'), '')
          .replaceAll(RegExp(r'[\u1f300-\u1f5ff]|[\u1f600-\u1f64f]|[\u1f680-\u1f6ff]|[\u2600-\u26ff]|[\u2700-\u27bf]|[\u1f900-\u1f9ff]|[\u1f1e0-\u1f1ff]|[\ud83c\ud000-\ud83c\udfff]|[\ud83d\ud000-\ud83d\udfff]|[\ud83e\ud000-\ud83e\udfff]'), '');
      await _flutterTts.speak(cleanText);
    }
  }

  void _initializeDomoWelcomeMessage() {
    _domoMessages = [
      DomoChatMessage(
        text: MemoryStore.instance.translate(
          tagalog: "Kumusta po! Ako si Domo, ang inyong AI assistant. Mayroon ba kayong nais itanong tungkol sa inyong pamilya o mga alaala?",
          english: "Hello! I'm Domo, your AI assistant. Do you have any questions about your family or memories today?",
        ),
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  Future<void> _checkRememberMeState() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? true;
    if (!rememberMe) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onCameraTap: () => setState(() => _currentTab = 1)),
      LensScreen(onNavigateToTab: (index) {
        setState(() {
          _currentTab = index;
        });
      }),
      const MemoriesScreen(),
      const FamilyScreen(),
    ];

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // If not logged in, display Login Screen
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAF7F0),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFD4A359))),
          );
        }

        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final store = MemoryStore.instance;
        return Stack(
          children: [
            Scaffold(
              body: IndexedStack(index: _currentTab, children: pages),
              bottomNavigationBar: SafeArea(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C1E1B), // Narra Wood Dark Capsule
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(
                        0,
                        Icons.home_outlined,
                        Icons.home_rounded,
                        MemoryStore.instance.translate(tagalog: 'Tahanan', english: 'Home'),
                      ),
                      _buildNavItem(
                        1,
                        Icons.camera_alt_outlined,
                        Icons.camera_alt_rounded,
                        MemoryStore.instance.translate(tagalog: 'Lens', english: 'Lens'),
                      ),
                      _buildNavItem(
                        2,
                        Icons.auto_stories_outlined,
                        Icons.auto_stories_rounded,
                        MemoryStore.instance.translate(tagalog: 'Alaala', english: 'Memories'),
                      ),
                      _buildNavItem(
                        3,
                        Icons.people_outline,
                        Icons.people_rounded,
                        MemoryStore.instance.translate(tagalog: 'Pamilya', english: 'Family'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Translucent overlay click blocker when Domo is open
            if (_isDomoDialogOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        _isDomoDialogOpen = false;
                      });
                    }
                  },
                  child: Container(
                    color: Colors.black45, // translucent backdrop
                  ),
                ),
              ),

            // Domo Floating Fixed Assistant Button (FAB) right above bottom navigation bar capsule!
            _buildDomoAssistantOverlay(context, store),

            // Slide Up Domo Dialogue Sheet Card Overlay!
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.fastOutSlowIn,
              left: 0,
              right: 0,
              bottom: _isDomoDialogOpen ? 0 : -520,
              height: 500,
              child: _buildDomoModal(context, store),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDomoAssistantOverlay(BuildContext context, MemoryStore store) {
    const goldColor = Color(0xFFD4A359);
    const darkWood = Color(0xFF2C1E1B);

    return Positioned(
      right: 20,
      bottom: 96,
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          onTap: () {
            if (mounted) {
              setState(() {
                _isDomoDialogOpen = true;
              });
            }
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: darkWood,
              shape: BoxShape.circle,
              border: Border.all(color: goldColor, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Image.asset(
                      'assets/images/applogo.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const Positioned(
                    bottom: 2,
                    child: Text(
                      'DOMO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDomoModal(BuildContext context, MemoryStore store) {
    const goldColor = Color(0xFFD4A359);
    const darkWood = Color(0xFF2C1E1B);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF9), // cream background
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: const Color(0xFFE9DFC8), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Chat Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.transparent,
                        backgroundImage: AssetImage('assets/images/applogo.png'),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.translate(tagalog: 'Kausapin si Domo', english: 'Chat with Domo'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: darkWood,
                            ),
                          ),
                          Text(
                            store.translate(tagalog: 'AI memory assistant', english: 'AI memory assistant'),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                    onPressed: () {
                      if (mounted) {
                        setState(() {
                          _isDomoDialogOpen = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE9DFC8)),

            // Model Brain Selector Chips Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    store.translate(tagalog: 'Brain:', english: 'Brain:'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildModelChip(AIModel.local, 'Local'),
                        _buildModelChip(AIModel.gemini, 'Gemini'),
                        _buildModelChip(AIModel.openai, 'OpenAI'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE9DFC8)),

            // Message list
            Expanded(
              child: Container(
                color: const Color(0xFFFAF7F0), // Capiz Cream style content box
                child: ListView.builder(
                  controller: _domoScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: _domoMessages.length + (_domoIsTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _domoMessages.length) {
                      // Typing Indicator Bubble
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10, right: 60),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE9DFC8), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(goldColor),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                store.translate(tagalog: 'Sumasagot si Domo...', english: 'Domo is typing...'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8B8276),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final msg = _domoMessages[index];
                    final isMe = msg.isUser;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: 10,
                          left: isMe ? 40 : 0,
                          right: isMe ? 0 : 40,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? darkWood : const Color(0xFFFFFDF9),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                          ),
                          border: isMe
                              ? null
                              : Border.all(color: const Color(0xFFE9DFC8), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isMe ? Colors.white : darkWood,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                            if (!isMe) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _speak(msg.text),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.volume_up_rounded,
                                              size: 14,
                                              color: goldColor,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Pakinggan',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: goldColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE9DFC8)),

            // Bottom message input row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE9DFC8), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: TextField(
                          controller: _domoChatController,
                          style: const TextStyle(fontSize: 13, color: darkWood, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: store.translate(tagalog: 'Magtanong kay Domo...', english: 'Ask Domo...'),
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (_) => _sendDomoMessage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendDomoMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: goldColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelChip(AIModel model, String label) {
    final isSelected = _selectedDomoModel == model;
    const goldColor = Color(0xFFD4A359);
    const darkWood = Color(0xFF2C1E1B);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (mounted) {
            setState(() {
              _selectedDomoModel = model;
            });
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? goldColor : const Color(0xFFFAF7F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? goldColor : const Color(0xFFE9DFC8),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : darkWood,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendDomoMessage() async {
    final text = _domoChatController.text.trim();
    if (text.isEmpty || _domoIsTyping) return;

    _domoChatController.clear();

    if (mounted) {
      setState(() {
        _domoMessages.add(DomoChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ));
        _domoIsTyping = true;
      });
    }

    _scrollToBottom();

    try {
      final store = MemoryStore.instance;
      // Build full RAG context from DB - include all profile details
      final peopleCtx = store.people.map((p) {
        final notes = p.notes.isNotEmpty ? '\n  Notes: ${p.notes.join('; ')}' : '';
        final birthday = p.birthday.isNotEmpty ? '\n  Birthday: ${p.birthday}' : '';
        final lastSeen = p.lastSeen != null ? '\n  Last seen: ${p.lastSeen!.toLocal().toString().split(' ')[0]}' : '';
        final food = p.favoriteFood.isNotEmpty ? '\n  Favorite food: ${p.favoriteFood}' : '';
        return '- ${p.name} (${p.relationship}): ${p.detail}$food$birthday$lastSeen$notes';
      }).join('\n');

      final memoriesCtx = store.memories.map((m) {
        final tags = m.tags.isNotEmpty ? ' [${m.tags.join(', ')}]' : '';
        return '- [${m.category}] ${m.personName}: "${m.title}" — ${m.detail} (${m.when}, ${m.location})$tags';
      }).join('\n');

      // Incorporate conversation session memory into the RAG context (last 10 messages)
      final recentHistory = _domoMessages.length > 1
          ? _domoMessages.sublist(
              (_domoMessages.length - 10).clamp(0, _domoMessages.length),
              _domoMessages.length,
            ).map((m) => '${m.isUser ? "User" : "Domo"}: ${m.text}').join('\n')
          : '';

      final combinedContext = '''
User Profile: ${store.userName}
Cognitive Profile: ${store.cognitiveChallenge}
Background Context: ${store.memoryContext}

Registered Family & People:
$peopleCtx

Memories Database:
$memoriesCtx

Recent Conversation:
$recentHistory'''.trim();

      // Request AI response using the selected model chip brain
      final reply = await AIClient.instance.askAI(
        query: text,
        context: combinedContext,
        userName: store.userName,
        challenge: store.cognitiveChallenge,
        memoryContext: store.memoryContext,
        preferredModel: _selectedDomoModel,
      );

      if (mounted) {
        setState(() {
          _domoMessages.add(DomoChatMessage(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _domoIsTyping = false;
        });
        // Auto-play the assistant's voice response using Text-To-Speech
        _speak(reply);
      }
    } catch (e) {
      debugPrint('Domo chat generation error: $e');
      if (mounted) {
        setState(() {
          _domoMessages.add(DomoChatMessage(
            text: MemoryStore.instance.translate(
              tagalog: "Paumanhin, may kaunting problema sa aking koneksyon. Pakisubukang muli po.",
              english: "Sorry, I encountered an issue connecting. Please try again.",
            ),
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _domoIsTyping = false;
        });
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_domoScrollController.hasClients) {
        _domoScrollController.animateTo(
          _domoScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }



  Widget _buildNavItem(
    int index,
    IconData outlineIcon,
    IconData solidIcon,
    String label,
  ) {
    final isActive = _currentTab == index;
    const goldAccent = Color(0xFFD4A359);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentTab = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? goldAccent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? solidIcon : outlineIcon,
                color: isActive ? goldAccent : const Color(0xFFE9DFC8),
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? goldAccent : const Color(0xFFE9DFC8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DomoChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  DomoChatMessage({required this.text, required this.isUser, required this.timestamp});
}
