import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/memory_store.dart';
import '../services/ai_client.dart';
import '../screens/ml_face_scanner_screen.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  void _showSettingsDrawer(BuildContext context) {
    const darkWood = Color(0xFF2C1E1B);
    const goldAccent = Color(0xFFD4A359);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFDF9), // Cream surface
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return ListenableBuilder(
          listenable: MemoryStore.instance,
          builder: (context, _) {
            final store = MemoryStore.instance;
            return SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header indicator line
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
                      store.translate(tagalog: 'Mga Setting at Opsyon', english: 'Settings & Options'),
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: darkWood,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE9DFC8)),
                    const SizedBox(height: 8),

                    // Language Selection Title
                    Text(
                      store.translate(tagalog: 'Wika / Language:', english: 'Language / Wika:'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Filipino (Tagalog)'),
                            selected: store.language == AppLanguage.tagalog,
                            onSelected: (selected) {
                              if (selected) {
                                store.setLanguage(AppLanguage.tagalog);
                              }
                            },
                            selectedColor: goldAccent.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: store.language == AppLanguage.tagalog ? darkWood : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('English'),
                            selected: store.language == AppLanguage.english,
                            onSelected: (selected) {
                              if (selected) {
                                store.setLanguage(AppLanguage.english);
                              }
                            },
                            selectedColor: goldAccent.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: store.language == AppLanguage.english ? darkWood : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE9DFC8)),
                    const SizedBox(height: 8),

                    // AI Model Selection Title
                    Text(
                      store.translate(tagalog: 'Paboritong AI Model (RAG):', english: 'Preferred AI Model (RAG):'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Radio Button list for Model selection
                    Column(
                      children: [
                        _buildModelRadio(
                          context: context,
                          model: AIModel.local,
                          title: store.translate(tagalog: 'Lokal AI (Rule-Based Fallback)', english: 'Local AI (Rule-Based Fallback)'),
                          subtitle: store.translate(tagalog: 'Mabilis, gumagana offline nang walang internet.', english: 'Fast, works offline without internet connection.'),
                          currentValue: store.activeModel,
                          onChanged: store.setActiveModel,
                        ),
                        _buildModelRadio(
                          context: context,
                          model: AIModel.gemini,
                          title: store.translate(tagalog: 'Gemini 1.5 Flash (Cloud AI)', english: 'Gemini 1.5 Flash (Cloud AI)'),
                          subtitle: store.translate(tagalog: 'Taglish/English, polite, at personalized via RAG.', english: 'Bilingual, polite, and personalized via RAG.'),
                          currentValue: store.activeModel,
                          onChanged: store.setActiveModel,
                        ),
                        _buildModelRadio(
                          context: context,
                          model: AIModel.openai,
                          title: store.translate(tagalog: 'OpenAI GPT-4o-mini (Cloud AI)', english: 'OpenAI GPT-4o-mini (Cloud AI)'),
                          subtitle: store.translate(tagalog: 'Detalyadong pagsagot gamit ang cloud model.', english: 'Detailed response utilizing the cloud model.'),
                          currentValue: store.activeModel,
                          onChanged: store.setActiveModel,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE9DFC8)),
                    const SizedBox(height: 12),

                    // Register Face Button
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close settings drawer
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MLFaceScannerScreen()),
                        );
                      },
                      icon: const Icon(Icons.face_retouching_natural_rounded, color: goldAccent, size: 20),
                      label: Text(
                        store.translate(tagalog: 'Irehistro ang Bagong Mukha (ML)', english: 'Register New Face (ML)'),
                        style: const TextStyle(color: goldAccent, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE9DFC8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Wipe/Clear memories button
                    OutlinedButton.icon(
                      onPressed: () => _confirmClearMemories(context),
                      icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFD26B6B), size: 20),
                      label: Text(
                        store.translate(tagalog: 'I-clear ang lahat ng Alaala', english: 'Wipe all Memory Logs'),
                        style: const TextStyle(color: Color(0xFFD26B6B), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE9DFC8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Logout Button
                    FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop(); // Close bottom sheet
                        await FirebaseAuth.instance.signOut();
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      label: Text(
                        store.translate(tagalog: 'Mag-logout sa Account', english: 'Sign Out of Account'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: darkWood,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  Widget _buildModelRadio({
    required BuildContext context,
    required AIModel model,
    required String title,
    required String subtitle,
    required AIModel currentValue,
    required ValueChanged<AIModel> onChanged,
  }) {
    final isSelected = model == currentValue;
    const darkWood = Color(0xFF2C1E1B);
    const goldAccent = Color(0xFFD4A359);

    return InkWell(
      onTap: () => onChanged(model),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? goldAccent : const Color(0xFFE9DFC8),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: darkWood,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF756A5B),
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

  void _confirmClearMemories(BuildContext context) {
    const darkWood = Color(0xFF2C1E1B);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFFDF9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'I-clear ang lahat ng Alaala?',
            style: GoogleFonts.cormorantGaramond(fontWeight: FontWeight.bold, fontSize: 22, color: darkWood),
          ),
          content: const Text(
            'Sigurado ka ba na gusto mong burahin ang lahat ng na-save mong memory logs? Hindi na ito maibabalik.',
            style: TextStyle(color: Color(0xFF756A5B), fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kanselahin', style: TextStyle(color: Color(0xFF756A5B))),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close settings drawer
                await MemoryStore.instance.clearAllMemories();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nalinis na ang lahat ng alaala sa logs.'),
                      backgroundColor: darkWood,
                    ),
                  );
                }
              },
              child: const Text('I-delete Lahat', style: TextStyle(color: Color(0xFFD26B6B), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkText = Color(0xFF2C1E1B);

    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/images/applogo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Ala-ala',
              style: GoogleFonts.cormorantGaramond(
                fontWeight: FontWeight.w900,
                fontSize: 26,
                color: darkText,
                letterSpacing: -0.5,
              ),
            ),
            const Spacer(),

            // Elegant settings hamburger button
            IconButton(
              icon: const Icon(
                Icons.menu_rounded,
                color: darkText,
                size: 24,
              ),
              onPressed: () => _showSettingsDrawer(context),
              tooltip: 'Mga Setting at Opsyon',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE9DFC8), width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
