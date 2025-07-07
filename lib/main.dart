import 'dart:async';
import 'dart:io';

import 'package:astral/fun/up.dart';
import 'package:astral/fun/reg.dart'; // 添加这行导入
import 'package:astral/k/app_s/log_capture.dart';
import 'package:astral/k/database/app_data.dart';
import 'package:astral/k/mod/window_manager.dart';
import 'package:astral/services/app_links/app_link_registry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:astral/src/rust/frb_generated.dart';
import 'package:astral/app.dart';

void main() async {
  // Linux 下检测是否为 root 权限
  if (!kIsWeb && Platform.isLinux) {
    final env = Platform.environment;
    if (env['USER'] != 'root' &&
        env['SUDO_USER'] == null &&
        env['UID'] != '0') {
      print('请使用 sudo 运行本程序！');
      exit(1);
    }
  }
  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase().init();
  AppInfoUtil.init();
  await RustLib.init();
  await LogCapture().startCapture();
  await UrlSchemeRegistrar.registerUrlScheme();
  await _initAppLinks();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await WindowManagerUtils.initializeWindow();
  }
  runApp(const KevinApp());
}

Future<void> _initAppLinks() async {
  final registry = AppLinkRegistry();
  await registry.initialize();
}
