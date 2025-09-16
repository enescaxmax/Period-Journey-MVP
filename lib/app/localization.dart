import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('tr')];

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'app_title': 'Period Journey',
      'onboarding_title': 'Welcome to Period Journey',
      'onboarding_subtitle': 'Let’s personalize your cycle insights.',
      'average_cycle_length_label': 'Average cycle length (days)',
      'period_length_label': 'Typical period length (days)',
      'continue_button': 'Continue',
      'save_button': 'Save',
      'cancel_button': 'Cancel',
      'log_today_action': 'Log today',
      'log_day_title': 'Log your day',
      'is_period_label': 'Period today',
      'flow_label': 'Flow',
      'symptoms_label': 'Symptoms',
      'moods_label': 'Moods',
      'notes_label': 'Notes',
      'log_saved_message': 'Log saved',
      'log_deleted_message': 'Log deleted',
      'calendar_title': 'Calendar',
      'stats_title': 'Insights',
      'home_title': 'Home',
      'log_home_empty_state': 'No entry yet. Log today to get started.',
      'guest_mode_badge': 'Guest mode',
      'sign_in_title': 'Sign in to sync',
      'email_label': 'Email',
      'password_label': 'Password',
      'signin_button': 'Sign in',
      'signup_button': 'Create account',
      'signout_button': 'Sign out',
      'continue_as_guest': 'Continue as guest',
      'google_signin_button': 'Sign in with Google',
      'settings_title': 'Cycle settings',
      'next_period_prediction': 'Next period prediction',
      'average_cycle_length_stat': 'Average cycle length',
      'average_period_length_stat': 'Average period length',
      'today_label': 'Today',
      'predicted_label': 'Predicted',
      'migrate_snackbar': 'Syncing your local history…',
      'error_generic': 'Something went wrong. Please try again.',
      'auth_not_available':
          'Sign in isn’t available right now. You can still use guest mode.',
      'log_date_label': 'Date',
      'delete_log': 'Delete log',
      'enter_positive_number': 'Enter a positive number',
      'recent_logs_title': 'Recent logs',
      'days_unit': 'days',
    },
    'tr': {
      'app_title': 'Period Journey',
      'onboarding_title': 'Period Journey’ye hoş geldin',
      'onboarding_subtitle': 'Döngünü birlikte kişiselleştirelim.',
      'average_cycle_length_label': 'Ortalama döngü süresi (gün)',
      'period_length_label': 'Tipik regl süresi (gün)',
      'continue_button': 'Devam et',
      'save_button': 'Kaydet',
      'cancel_button': 'İptal',
      'log_today_action': 'Bugünü kaydet',
      'log_day_title': 'Bugününü kaydet',
      'is_period_label': 'Bugün regl misin?',
      'flow_label': 'Akış',
      'symptoms_label': 'Belirtiler',
      'moods_label': 'Ruh halleri',
      'notes_label': 'Notlar',
      'log_saved_message': 'Kayıt edildi',
      'log_deleted_message': 'Kayıt silindi',
      'calendar_title': 'Takvim',
      'stats_title': 'İstatistikler',
      'home_title': 'Ana sayfa',
      'log_home_empty_state': 'Henüz kayıt yok. Başlamak için bugünü kaydet.',
      'guest_mode_badge': 'Misafir modu',
      'sign_in_title': 'Senkronize olmak için giriş yap',
      'email_label': 'E-posta',
      'password_label': 'Şifre',
      'signin_button': 'Giriş yap',
      'signup_button': 'Hesap oluştur',
      'signout_button': 'Çıkış yap',
      'continue_as_guest': 'Misafir olarak devam et',
      'google_signin_button': 'Google ile giriş yap',
      'settings_title': 'Döngü ayarları',
      'next_period_prediction': 'Sonraki regl tahmini',
      'average_cycle_length_stat': 'Ortalama döngü süresi',
      'average_period_length_stat': 'Ortalama regl süresi',
      'today_label': 'Bugün',
      'predicted_label': 'Tahmini',
      'migrate_snackbar': 'Yerel geçmişin senkronize ediliyor…',
      'error_generic': 'Bir şeyler ters gitti. Lütfen tekrar dene.',
      'auth_not_available':
          'Giriş şu an kullanılamıyor. Misafir modu ile devam edebilirsin.',
      'log_date_label': 'Tarih',
      'delete_log': 'Kaydı sil',
      'enter_positive_number': 'Pozitif bir sayı gir',
      'recent_logs_title': 'Son kayıtlar',
      'days_unit': 'gün',
    },
  };

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  String t(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(Locale(locale.languageCode));

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
