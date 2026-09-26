import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final languageProvider = StateProvider<String>((ref) => 'en');

final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
