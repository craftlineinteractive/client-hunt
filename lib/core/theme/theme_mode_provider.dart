import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the user's theme preference for the session.
///
/// In memory only in A1; persistence arrives in a later prompt. [ThemeMode.system]
/// is the default, so the app follows the device setting.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Applies an explicit preference.
  void set(ThemeMode mode) => state = mode;

  /// Cycles light → dark → system, used by the design gallery.
  void cycle() {
    state = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }
}

/// The single source of truth for the active [ThemeMode].
final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
