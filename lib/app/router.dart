import 'package:flutter/material.dart';

import '../features/cycle/presentation/log_day_page.dart';

class AppRouter {
  static const logDay = '/log-day';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case logDay:
        final args = settings.arguments;
        DateTime? date;
        if (args is DateTime) {
          date = args;
        }
        return MaterialPageRoute(
          builder: (_) => LogDayPage(date: date),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const UnknownRoutePage(),
          settings: settings,
        );
    }
  }
}

class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Page not found',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
