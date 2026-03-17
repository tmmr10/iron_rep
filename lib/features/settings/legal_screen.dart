import 'package:flutter/material.dart';

import '../../shared/design_system.dart';

class LicensesScreen extends StatelessWidget {
  const LicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: c.card,
        appBarTheme: AppBarTheme(
          backgroundColor: c.background,
          foregroundColor: c.textPrimary,
        ),
      ),
      child: const LicensePage(
        applicationName: 'IronRep',
        applicationVersion: '1.0.0',
        applicationLegalese: '© 2025 tmmr. Alle Rechte vorbehalten.',
      ),
    );
  }
}
