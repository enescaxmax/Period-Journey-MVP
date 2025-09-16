import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseInitializationProvider = FutureProvider<bool>((ref) async {
  try {
    if (Firebase.apps.isNotEmpty) {
      return true;
    }
    await Firebase.initializeApp();
    return true;
  } on FirebaseException catch (error) {
    debugPrint('Firebase init failed: ${error.code}');
    return false;
  } catch (error) {
    debugPrint('Firebase init failed: $error');
    return false;
  }
});

final firebaseAvailabilityProvider = Provider<bool>((ref) {
  final result = ref.watch(firebaseInitializationProvider);
  return result.maybeWhen(data: (value) => value, orElse: () => false);
});

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  if (!ref.watch(firebaseAvailabilityProvider)) {
    return null;
  }
  return FirebaseAuth.instance;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  if (auth == null) {
    return Stream<User?>.value(null);
  }
  return auth.authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  final asyncUser = ref.watch(authStateChangesProvider);
  return asyncUser.maybeWhen(data: (user) => user, orElse: () => null);
});
