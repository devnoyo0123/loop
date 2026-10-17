import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'data/loop_db.dart';
import 'design/tokens.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/timeline_screen.dart';
import 'services/loop_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LoopNotifications.init();
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  final db = LoopDb(dir)..open();
  runApp(LoopApp(db: db));
}

class LoopApp extends StatelessWidget {
  const LoopApp({super.key, required this.db});

  final LoopDb db;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loop',
      debugShowCheckedModeBanner: false,
      // 폰(시스템) 언어를 따른다. 미지원 언어는 한국어로.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLoopTheme(),
      home: TimelineScreen(db: db),
    );
  }
}
