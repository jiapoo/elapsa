import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elapsa/core/theme.dart';
import 'package:elapsa/data/document_repository.dart';
import 'package:elapsa/ui/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await container.read(notificationServiceProvider).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ElapsaApp(),
    ),
  );
}

class ElapsaApp extends StatelessWidget {
  const ElapsaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elapsa',
      debugShowCheckedModeBanner: false,
      theme: ElapsaTheme.light(),
      darkTheme: ElapsaTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _ResyncOnResume(child: HomeScreen()),
    );
  }
}

/// Rebuilds the reminder schedule whenever the app comes back to the
/// foreground.
///
/// Two things make this necessary rather than merely tidy: a user who declined
/// the permission prompt and later enabled notifications in Settings would
/// otherwise never get any reminders, and the rolling window of pending
/// notifications needs topping up as earlier ones fire and fall away.
class _ResyncOnResume extends ConsumerStatefulWidget {
  const _ResyncOnResume({required this.child});

  final Widget child;

  @override
  ConsumerState<_ResyncOnResume> createState() => _ResyncOnResumeState();
}

class _ResyncOnResumeState extends ConsumerState<_ResyncOnResume>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Also on cold start: a launch is not a "resume", so without this an app
    // opened fresh would never rebuild a schedule that had been lost.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentRepositoryProvider).resync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(documentRepositoryProvider).resync();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
