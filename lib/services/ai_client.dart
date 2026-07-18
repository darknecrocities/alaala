import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

enum AIModel { local, gemini, openai }

class AIClient {
  AIClient._internal();
  static final AIClient instance = AIClient._internal();

  String _geminiApiKey = '';
  String _openaiApiKey = '';
  bool _isInitialized = false;

  String get geminiApiKey => _geminiApiKey;
  String get openaiApiKey => _openaiApiKey;
  bool get hasGemini => _geminiApiKey.isNotEmpty;
  bool get hasOpenAI => _openaiApiKey.isNotEmpty;

  // Initialize the keys from the .env asset
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final envData = await rootBundle.loadString('.env');
      final lines = const LineSplitter().convert(envData);
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final parts = trimmed.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final val = parts.sublist(1).join('=').trim();
          if (key == 'GEMINI_API_KEY') {
            _geminiApiKey = val;
          } else if (key == 'OPENAI_API_KEY') {
            _openaiApiKey = val;
          }
        }
      }
      _isInitialized = true;
    } catch (e) {
      // If asset loading fails (e.g. testing), print and continue using local fallback
      // ignore: avoid_print
      print('AIClient initialization warning: $e');
    }
  }

  // Orchestrate the RAG prompt and call the selected API
  Future<String> askAI({
    required String query,
    required String context,
    required String userName,
    required String challenge,
    required String memoryContext,
    required AIModel preferredModel,
  }) async {
    await initialize();

    // RAG Prompt Construction
    final prompt = '''
You are "Ala-ala", a warm, comforting, and extremely caring AI memory assistant designed for $userName, a Filipino senior citizen.
$userName's cognitive profile / challenge: $challenge.
Initial memory background context provided by family: $memoryContext.

Below is the matching memory context retrieved from the user's local database:
---
$context
---

The user is asking you this question: "$query"

Guidelines:
1. Speak in warm, polite Taglish (Tagalog-English mix) using Filipino honorifics like "po" and "opo".
2. Keep your sentences short, simple, and very easy to understand (especially suitable for elderly adults with cognitive challenges).
3. Do NOT make up or hallucinate any facts. If the answer cannot be found or inferred from the memory context or background, say gently that you don't remember it yet, and suggest adding it as a note or asking their daughter Anna.
4. Focus on comforting and reducing anxiety. Never say "You forgot". Say "I'll help you remember" or "Narito po ang aking naaalala".
5. Give a natural, conversational response directly answering their question. Do not include labels like "Answer:" or "AI:".
''';

    // Model selection logic
    AIModel activeModel = preferredModel;
    if (activeModel == AIModel.gemini && !hasGemini) {
      activeModel = hasOpenAI ? AIModel.openai : AIModel.local;
    } else if (activeModel == AIModel.openai && !hasOpenAI) {
      activeModel = hasGemini ? AIModel.gemini : AIModel.local;
    }

    switch (activeModel) {
      case AIModel.gemini:
        return _callGemini(prompt);
      case AIModel.openai:
        return _callOpenAI(prompt);
      case AIModel.local:
        return _runLocalModel(query, context, userName);
    }
  }

  // REST Call to Gemini API (v1beta/gemini-1.5-flash)
  Future<String> _callGemini(String prompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 300,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
      return 'Pasensya na po, nagkaroon ako ng maliit na problema sa pagkonekta. ${_runLocalModelShort()}';
    } catch (e) {
      return 'Hindi ko po maabot ang aking cloud server ngayon. ${_runLocalModelShort()}';
    }
  }

  // REST Call to OpenAI Chat Completion API (gpt-4o-mini)
  Future<String> _callOpenAI(String prompt) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openaiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
      return 'Pasensya na po, nagkaroon ng error sa OpenAI completion. ${_runLocalModelShort()}';
    } catch (e) {
      return 'Hindi po makakonekta sa OpenAI server ngayon. ${_runLocalModelShort()}';
    }
  }

  // Fallback Rule-Based Taglish AI simulator when offline or API keys are missing
  String _runLocalModel(String query, String context, String userName) {
    if (context.isEmpty) {
      return 'Pasensya na po, $userName. Wala akong nakitang tala tungkol diyan sa aking alaala. Gusto niyo po ba nating itanong kay Anna pagbisita niya?';
    }

    final lowerQuery = query.toLowerCase();
    
    // Look up items in matching context lines
    if (lowerQuery.contains('gamot') || lowerQuery.contains('med')) {
      if (context.contains('gamot') || context.contains('reseta')) {
        return 'Opo, $userName. Ayon sa ating alaala, uminom po ng gamot pagkatapos kumain ng almusal. Iyon po ang bilin ni Dr. Cruz.';
      }
      return 'Naaalala ko po na mayroon kayong gamot na iniinom sa umaga, ngunit mas mabuti po na tingnan natin ang listahan sa pamilya o magtanong kay Anna.';
    }

    if (lowerQuery.contains('anak') || lowerQuery.contains('anna')) {
      return 'Si Anna po ang inyong anak. Bumibisita siya tuwing Sabado ng hapon at nagdadala po siya ng paborito ninyong sariwang mangga.';
    }

    if (lowerQuery.contains('doctor') || lowerQuery.contains('check-up') || lowerQuery.contains('cruz')) {
      return 'Mayroon po kayong check-up kay Dr. Cruz sa Lunes ng umaga sa Barangay Health Center.';
    }

    // Default return parsing best matched sentence in context
    final sentences = context.split(RegExp(r'[.!?]'));
    final matchedSentence = sentences.firstWhere(
      (s) => s.trim().length > 10,
      orElse: () => 'Naaalala ko po na may ginawa kayo kamakailan kasama ang pamilya.',
    );

    return 'Narito po ang aking naaalala: ${matchedSentence.trim()}. Iyan po ang ating nakatala.';
  }

  String _runLocalModelShort() {
    return 'Gagamitin ko muna ang aking lokal na memorya para tulungan kayo.';
  }

  // Generates a heartwarming JSON memory log about a person using AI
  Future<String> generateMemoryForPerson({
    required String personName,
    required String relationship,
    required String details,
    required String userName,
    required AIModel preferredModel,
  }) async {
    await initialize();
    
    final prompt = '''
Create a heartwarming, nostalgic, and personalized memory log about $personName ($relationship) for $userName.
About $personName: $details.
Generate a short 1-2 sentence memory details in warm Taglish (polite, comforting, using 'po' and 'opo' if caregiver, or simple sweet memories if family).
Make it sound like an amazing, memorable event or promise that they shared together.

Format the response as a valid JSON object matching this structure EXACTLY (do not wrap in markdown or any other prefix/suffix):
{
  "title": "A short beautiful title of the memory (e.g., Pagsasalong tanghalian sa tabing-dagat)",
  "detail": "Heartwarming details describing the memory...",
  "category": "Pamilya",
  "location": "The location where the memory might have happened (e.g. Quezon City)",
  "emotion": "The emotion associated with it (e.g. Maligaya)",
  "tags": ["kapanatagan", "pag-ibig"]
}
''';

    // Model selection logic
    AIModel activeModel = preferredModel;
    if (activeModel == AIModel.gemini && !hasGemini) {
      activeModel = hasOpenAI ? AIModel.openai : AIModel.local;
    } else if (activeModel == AIModel.openai && !hasOpenAI) {
      activeModel = hasGemini ? AIModel.gemini : AIModel.local;
    }

    switch (activeModel) {
      case AIModel.gemini:
        return _callGemini(prompt);
      case AIModel.openai:
        return _callOpenAI(prompt);
      case AIModel.local:
        return _generateLocalMockMemory(personName, relationship);
    }
  }

  String _generateLocalMockMemory(String personName, String relationship) {
    return jsonEncode({
      "title": "Masayang tawanan kasama si $personName",
      "detail": "Naaalala ko ang iyong matamis na ngiti at pagmamahal bilang aking $relationship habang nagkukuwentuhan tungkol sa inyong pamilya.",
      "category": "Pamilya",
      "location": "Tahanan",
      "emotion": "Masaya",
      "tags": ["kapanatagan", "pamilya"]
    });
  }
}
