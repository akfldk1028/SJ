import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  await dotenv.load(fileName: '.env');

  // Hive 초기화
  await Hive.initFlutter();

  // Hive 박스 열기 (채팅 세션용)
  await Hive.openBox('chat_sessions');
  await Hive.openBox('chat_messages');

  runApp(
    const ProviderScope(
      child: MantokApp(),
    ),
  );
}
