import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/memory_store.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const _ink = Color(0xFF2C211C);
  static const _gold = Color(0xFFC99A4A);
  static const _cream = Color(0xFFFFFCF6);
  static const _muted = Color(0xFF776E64);

  int _activeStep = 0;
  final _accountFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _contextController = TextEditingController();
  String _selectedRole = 'Patient';
  String _selectedChallenge = 'Mild cognitive impairment (MCI)';
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _errorMessage = '';

  final List<String> _challenges = const [
    'Memory loss (Alzheimer’s / dementia)',
    'Mild cognitive impairment (MCI)',
    'Stroke recovery (aphasia / physical recovery)',
    'Normal age-related memory changes',
  ];

  final List<String> _routineOptions = const [
    'Take medication',
    'Prayer or church',
    'Exercise or take a walk',
    'Talk with family (call or visit)',
    'Read a newspaper or book',
  ];
  final List<bool> _routineChecked = [true, true, false, true, false];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _continueFromAccount() {
    if (!_accountFormKey.currentState!.validate()) return;
    setState(() {
      _errorMessage = '';
      _activeStep = 1;
    });
  }

  Future<void> _finishSetup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final routines = <String>[
      for (var index = 0; index < _routineOptions.length; index++)
        if (_routineChecked[index]) _routineOptions[index],
    ];

    try {
      // Account creation happens after every onboarding choice is collected.
      // This prevents the root auth listener from replacing this wizard mid-flow.
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await MemoryStore.instance.saveUserProfile(
        name: _nameController.text.trim(),
        userRole: _selectedRole,
        challenge: _selectedChallenge,
        routines: routines,
        contextText: _contextController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (error) {
      setState(() {
        if (error.message != null && error.message!.contains('CONFIGURATION_NOT_FOUND')) {
          _errorMessage = 'Firebase Config Error: Siguraduhing ENABLED ang Email/Password provider sa Firebase Console > Authentication > Sign-in method. Gayundin, pumunta sa Authentication > Settings > User actions at i-DISABLE ang reCAPTCHA Enterprise Email/Password protection para sa local development.';
        } else {
          _errorMessage = switch (error.code) {
            'email-already-in-use' =>
              'An account already uses this email address.',
            'weak-password' => 'Use a password with at least 6 characters.',
            'invalid-email' => 'Check your email address and try again.',
            _ => error.message ?? 'We could not finish creating your account.',
          };
        }
      });
    } catch (_) {
      setState(() {
        _errorMessage =
            'We could not save your setup. Please try again when you are online.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goBack() {
    if (_activeStep == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _activeStep--);
  }

  @override
  Widget build(BuildContext context) {
    final step = _activeStep + 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2E9),
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: _activeStep == 0
                                ? 'Go back'
                                : 'Previous step',
                            onPressed: _goBack,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: _ink,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'SETUP $step OF 4',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProgressIndicator(activeStep: _activeStep),
                            const SizedBox(height: 30),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position:
                                          Tween<Offset>(
                                            begin: const Offset(0, .035),
                                            end: Offset.zero,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            ),
                                          ),
                                      child: child,
                                    ),
                                  ),
                              child: KeyedSubtree(
                                key: ValueKey(_activeStep),
                                child: _buildStep(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() => switch (_activeStep) {
    0 => _accountStep(),
    1 => _challengeStep(),
    2 => _routineStep(),
    _ => _memoryStep(),
  };

  Widget _accountStep() {
    return Form(
      key: _accountFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _StepIntro(
            eyebrow: 'WELCOME TO ALA-ALA',
            title: 'Create an\naccount that’s yours.',
            description:
                'We’ll prepare a safe, personal space for your memories.',
          ),
          const SizedBox(height: 26),
          _Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  controller: _nameController,
                  label: 'Full name',
                  hint: 'e.g. Maria Santos',
                  icon: Icons.person_outline_rounded,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your name.'
                      : null,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _emailController,
                  label: 'Email address',
                  hint: 'name@example.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Enter a valid email address.'
                      : null,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'At least 6 characters',
                  icon: Icons.lock_outline_rounded,
                  obscureText: !_isPasswordVisible,
                  onTogglePasswordVisibility: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  },
                  validator: (value) => value == null || value.length < 6
                      ? 'Use 6 or more characters.'
                      : null,
                ),
                const SizedBox(height: 26),
                const Text(
                  'How will you use Ala-ala?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _ink,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                _RoleOption(
                  selected: _selectedRole == 'Patient',
                  icon: Icons.face_retouching_natural_rounded,
                  title: 'For myself',
                  subtitle: 'I’ll use it to support my day-to-day memories.',
                  onTap: () => setState(() => _selectedRole = 'Patient'),
                ),
                const SizedBox(height: 10),
                _RoleOption(
                  selected: _selectedRole == 'Caregiver',
                  icon: Icons.favorite_outline_rounded,
                  title: 'For someone I care for',
                  subtitle: 'I’ll help them remember and stay connected.',
                  onTap: () => setState(() => _selectedRole = 'Caregiver'),
                ),
              ],
            ),
          ),
          _ErrorMessage(message: _errorMessage),
          const SizedBox(height: 22),
          _PrimaryButton(label: 'Continue', onPressed: _continueFromAccount),
          const SizedBox(height: 14),
          const Text(
            'You can update these details anytime.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _challengeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepIntro(
          eyebrow: 'PERSONALIZE YOUR SUPPORT',
          title: 'What would\nhelp most?',
          description:
              'Choose what feels closest to your needs. You can update this later.',
        ),
        const SizedBox(height: 26),
        _Surface(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              for (final challenge in _challenges) ...[
                _SelectionRow(
                  label: challenge,
                  selected: _selectedChallenge == challenge,
                  onTap: () => setState(() => _selectedChallenge = challenge),
                ),
                if (challenge != _challenges.last)
                  const Divider(height: 1, color: Color(0xFFE9E1D4)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        _PrimaryButton(
          label: 'Continue',
          onPressed: () => setState(() => _activeStep = 2),
        ),
      ],
    );
  }

  Widget _routineStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepIntro(
          eyebrow: 'YOUR DAILY RHYTHM',
          title: 'What would you\nlike to remember?',
          description:
              'Choose the routines that matter. You can add more after setup.',
        ),
        const SizedBox(height: 26),
        _Surface(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              for (var index = 0; index < _routineOptions.length; index++) ...[
                _SelectionRow(
                  label: _routineOptions[index],
                  selected: _routineChecked[index],
                  multiSelect: true,
                  onTap: () => setState(
                    () => _routineChecked[index] = !_routineChecked[index],
                  ),
                ),
                if (index != _routineOptions.length - 1)
                  const Divider(height: 1, color: Color(0xFFE9E1D4)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        _PrimaryButton(
          label: 'Continue',
          onPressed: () => setState(() => _activeStep = 3),
        ),
      ],
    );
  }

  Widget _memoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepIntro(
          eyebrow: 'A GENTLE START',
          title: 'One thing\nthat matters.',
          description:
              'Leave a short note about a person or detail you would like to remember.',
        ),
        const SizedBox(height: 26),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'First memory',
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'For example: a child’s name, a doctor, or an important reminder.',
                style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contextController,
                minLines: 5,
                maxLines: 7,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Write it here...',
                  hintStyle: const TextStyle(color: Color(0xFF9B9287)),
                  filled: true,
                  fillColor: const Color(0xFFF9F6EF),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE2D8C9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE2D8C9)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: _gold, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        _ErrorMessage(message: _errorMessage),
        const SizedBox(height: 22),
        _PrimaryButton(
          label: 'Finish setup',
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _finishSetup,
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    VoidCallback? onTogglePasswordVisibility,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _muted),
        suffixIcon: onTogglePasswordVisibility == null
            ? null
            : IconButton(
                tooltip: obscureText ? 'Show password' : 'Hide password',
                onPressed: onTogglePasswordVisibility,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _muted,
                ),
              ),
        labelStyle: const TextStyle(color: _muted),
        hintStyle: const TextStyle(color: Color(0xFF9B9287)),
        filled: true,
        fillColor: const Color(0xFFF9F6EF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2D8C9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2D8C9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -80,
            child: Container(
              width: 310,
              height: 310,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _SignupScreenState._gold.withValues(alpha: .13),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF0D8A8).withValues(alpha: .35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.activeStep});
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (index) {
        final complete = index <= activeStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 3 ? 0 : 7),
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: complete
                  ? _SignupScreenState._gold
                  : const Color(0xFFE2D9CB),
            ),
          ),
        );
      }),
    );
  }
}

class _StepIntro extends StatelessWidget {
  const _StepIntro({
    required this.eyebrow,
    required this.title,
    required this.description,
  });
  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: _SignupScreenState._gold,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cormorant Garamond',
            color: _SignupScreenState._ink,
            fontSize: 34,
            height: 1.08,
            letterSpacing: -1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(
            color: _SignupScreenState._muted,
            fontSize: 15,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _SignupScreenState._cream.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: .85)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x162C211C),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : _SignupScreenState._ink;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: selected
                  ? _SignupScreenState._ink
                  : const Color(0xFFF9F6EF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? _SignupScreenState._ink
                    : const Color(0xFFE2D8C9),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? const Color(0xFFF2CD88)
                      : _SignupScreenState._gold,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: foreground.withValues(alpha: .74),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: foreground,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionRow extends StatelessWidget {
  const _SelectionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.multiSelect = false,
  });
  final String label;
  final bool selected;
  final bool multiSelect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          child: Row(
            children: [
              Icon(
                selected
                    ? (multiSelect
                          ? Icons.check_box_rounded
                          : Icons.radio_button_checked_rounded)
                    : (multiSelect
                          ? Icons.check_box_outline_blank_rounded
                          : Icons.radio_button_off_rounded),
                color: selected
                    ? _SignupScreenState._gold
                    : const Color(0xFF9A9084),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: _SignupScreenState._ink,
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _SignupScreenState._ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _SignupScreenState._ink.withValues(
            alpha: .55,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB54848),
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}
