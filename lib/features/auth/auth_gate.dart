import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/localization.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/primary_button.dart';
import '../cycle/data/cycle_repository.dart';
import '../cycle/data/models.dart';
import '../cycle/data/settings_controller.dart';
import '../cycle/presentation/cycle_home_page.dart';
import '../onboarding/onboarding_page.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  // TODO: Support partner sharing once backend endpoints are available.
  bool _showSignIn = false;
  bool _isMigrating = false;
  String? _migratedUserId;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _migrationSnackbar;

  @override
  void initState() {
    super.initState();
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (previous == null && next != null) {
        _migrateLocalData(next);
      }
      if (next == null && mounted) {
        setState(() => _showSignIn = false);
      }
    });
  }

  Future<void> _migrateLocalData(User user) async {
    if (_isMigrating || _migratedUserId == user.uid || !mounted) {
      return;
    }
    final firestoreRepo = ref.read(firestoreCycleRepositoryProvider);
    final mockRepo = ref.read(mockCycleRepositoryProvider);
    if (firestoreRepo == null) {
      return;
    }
    final migrator = ref.read(cycleRepositoryMigratorProvider);
    _isMigrating = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final localization = AppLocalizations.of(context);
      _migrationSnackbar = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.t('migrate_snackbar'))),
      );
    });
    try {
      await migrator.migrate(
          from: mockRepo, to: firestoreRepo, userId: user.uid);
      if (!mounted) {
        return;
      }
      ref.invalidate(cycleSettingsProvider);
      _migratedUserId = user.uid;
    } catch (_) {
      // keep guest data untouched on failure
    } finally {
      _migrationSnackbar?.close();
      _isMigrating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final firebaseInit = ref.watch(firebaseInitializationProvider);
    final settingsAsync = ref.watch(cycleSettingsProvider);
    final user = ref.watch(currentUserProvider);
    final firebaseReady = ref.watch(firebaseAvailabilityProvider);

    return firebaseInit.when(
      loading: () => const _LoadingScaffold(),
      error: (_, __) =>
          _ErrorScaffold(message: localization.t('auth_not_available')),
      data: (_) {
        if (settingsAsync.isLoading) {
          return const _LoadingScaffold();
        }
        if (settingsAsync.hasError) {
          return _ErrorScaffold(message: localization.t('error_generic'));
        }
        final settings = settingsAsync.value;
        if (settings == null) {
          return OnboardingPage(
            onCompleted: (cycleSettings) {
              ref
                  .read(cycleSettingsProvider.notifier)
                  .updateSettings(cycleSettings);
            },
          );
        }

        if (_showSignIn && firebaseReady && user == null) {
          return AuthPage(
            onClose: () => setState(() => _showSignIn = false),
            onAuthenticated: () => setState(() => _showSignIn = false),
          );
        }

        return CycleHomePage(
          isGuest: user == null,
          onSignInRequested: firebaseReady && user == null
              ? () => setState(() => _showSignIn = true)
              : null,
        );
      },
    );
  }
}

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({
    super.key,
    required this.onClose,
    required this.onAuthenticated,
  });

  final VoidCallback onClose;
  final VoidCallback onAuthenticated;

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    final auth = ref.read(firebaseAuthProvider);
    if (auth == null) {
      _showMessage(AppLocalizations.of(context).t('auth_not_available'));
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      if (!mounted) {
        return;
      }
      widget.onAuthenticated();
    } on FirebaseAuthException catch (error) {
      _showMessage(
          error.message ?? AppLocalizations.of(context).t('error_generic'));
    } catch (_) {
      _showMessage(AppLocalizations.of(context).t('error_generic'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = ref.read(firebaseAuthProvider);
    if (auth == null) {
      _showMessage(AppLocalizations.of(context).t('auth_not_available'));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await auth.signInWithCredential(credential);
      if (!mounted) {
        return;
      }
      widget.onAuthenticated();
    } on FirebaseAuthException catch (error) {
      _showMessage(
          error.message ?? AppLocalizations.of(context).t('error_generic'));
    } catch (_) {
      _showMessage(AppLocalizations.of(context).t('error_generic'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.t('sign_in_title')),
        leading: IconButton(
          onPressed: widget.onClose,
          icon: const Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration:
                  InputDecoration(labelText: localization.t('email_label')),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration:
                  InputDecoration(labelText: localization.t('password_label')),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isSignUp
                  ? localization.t('signup_button')
                  : localization.t('signin_button'),
              onPressed: _handleEmailAuth,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: localization.t('google_signin_button'),
              onPressed: _handleGoogleSignIn,
              isLoading: _isLoading,
              icon: const Icon(Icons.login),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp
                  ? localization.t('signin_button')
                  : localization.t('signup_button')),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
