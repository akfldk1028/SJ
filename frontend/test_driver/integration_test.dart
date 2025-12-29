import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (screenshotName, screenshotBytes, [args]) async {
      final file = File('L:/SJ/SJ/screenshots/$screenshotName.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(screenshotBytes);
      print('Screenshot saved: ${file.path}');
      return true;
    },
  );
}
