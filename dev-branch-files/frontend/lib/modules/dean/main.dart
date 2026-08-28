import 'package:flutter/material.dart';
import 'theme.dart';
import 'models/app_state.dart';
import 'screens/main_layout.dart';

void main() {
  runApp(const DeanPortalApp());
}

class DeanPortalApp extends StatefulWidget {
  const DeanPortalApp({super.key});

  @override
  State<DeanPortalApp> createState() => _DeanPortalAppState();
}

class _DeanPortalAppState extends State<DeanPortalApp> {
  late final DeanAppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = DeanAppState();
    _appState.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return DeanAppStateProvider(
      state: _appState,
      child: MaterialApp(
        title: 'Campus OS - Dean Portal',
        debugShowCheckedModeBanner: false,
        theme: DeanTheme.themeData,
        home: const DeanMainLayout(),
      ),
    );
  }
}