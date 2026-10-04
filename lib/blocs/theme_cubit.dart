import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  /// Pass the brightness currently on screen so the first tap always flips
  /// it, even while the app is following the system theme.
  void toggle(Brightness current) {
    emit(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
