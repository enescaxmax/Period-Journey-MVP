import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/localization.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'features/auth/auth_gate.dart';
import 'shared/providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PeriodJourneyApp()));
}

class PeriodJourneyApp extends ConsumerWidget {
  const PeriodJourneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(firebaseInitializationProvider); // trigger init early
    final theme = AppTheme();

    return MaterialApp(
      title: 'Period Journey',
      debugShowCheckedModeBanner: false,
      theme: theme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const AuthGate(),
    );
  }
}
