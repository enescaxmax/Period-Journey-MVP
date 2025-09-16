import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../cycle/data/models.dart';
import '../../shared/widgets/primary_button.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onCompleted});

  final ValueChanged<CycleSettings> onCompleted;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _cycleController = TextEditingController(text: '28');
  final _periodController = TextEditingController(text: '5');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cycleController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final cycleLength = int.parse(_cycleController.text);
    final periodLength = int.parse(_periodController.text);
    widget.onCompleted(
      CycleSettings(
          averageCycleLength: cycleLength, periodLength: periodLength),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  localization.t('onboarding_title'),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  localization.t('onboarding_subtitle'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _cycleController,
                  decoration: InputDecoration(
                      labelText: localization.t('average_cycle_length_label')),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      _positiveNumberValidator(value, localization),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _periodController,
                  decoration: InputDecoration(
                      labelText: localization.t('period_length_label')),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      _positiveNumberValidator(value, localization),
                ),
                const Spacer(),
                PrimaryButton(
                  label: localization.t('continue_button'),
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _positiveNumberValidator(
      String? value, AppLocalizations localization) {
    if (value == null || value.isEmpty) {
      return localization.t('enter_positive_number');
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return localization.t('enter_positive_number');
    }
    return null;
  }
}
