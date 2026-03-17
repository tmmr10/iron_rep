import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/settings_providers.dart';
import '../services/plan_sharing_service.dart';
import '../shared/design_system.dart';
import 'router.dart';

final _deepLinkProvider = Provider<void>((ref) {
  final appLinks = AppLinks();
  final router = ref.watch(routerProvider);

  final sub = appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'ironrep' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'plan' &&
        uri.pathSegments.length > 1) {
      final data = uri.pathSegments[1];
      final plan = PlanSharingService.decodePlan(data);
      if (plan != null) {
        router.go('/import-plan', extra: plan);
      }
    }
  });

  ref.onDispose(() => sub.cancel());
});

class IronRepApp extends ConsumerWidget {
  const IronRepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);
    ref.watch(_deepLinkProvider);

    return MaterialApp.router(
      title: 'IronRep',
      theme: IronRepTheme.lightTheme,
      darkTheme: IronRepTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
