import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/database_provider.dart';
import '../../providers/settings_providers.dart';
import '../../shared/design_system.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);

    final db = ref.read(databaseProvider);
    await db.settingsDao.setValue('user_name', name);
    ref.invalidate(settingsProvider);

    if (mounted) context.go('/workout');
  }

  void _skip() {
    context.go('/workout');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: IronRepGradients.accent(c),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 40,
                    color: c.background,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 600.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 32),

                // Headline
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [c.accentGradientStart, c.accentGradientEnd],
                  ).createShader(bounds),
                  child: const Text(
                    'Willkommen bei IronRep',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms)
                    .slideY(
                      begin: 0.2,
                      duration: 600.ms,
                      delay: 200.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Wie heißt du?',
                  style: TextStyle(
                    fontSize: 16,
                    color: c.textSecondary,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms),

                const SizedBox(height: 32),

                // Name input
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: c.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Dein Name',
                  ),
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) => setState(() {}),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 500.ms),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _controller.text.trim().isNotEmpty && !_saving
                            ? _submit
                            : null,
                    child: _saving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.background,
                            ),
                          )
                        : const Text("Los geht's"),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 600.ms),

                const SizedBox(height: 12),

                // Skip
                TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Später',
                    style: TextStyle(color: c.textMuted),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
