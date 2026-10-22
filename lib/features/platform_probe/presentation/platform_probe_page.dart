import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../application/probe_file_codec.dart';
import '../data/probe_database.dart';
import '../data/probe_files.dart';
import '../data/probe_notifications.dart';

final _databaseProvider = FutureProvider<ProbeDatabase>((ref) async {
  final directory = await getApplicationSupportDirectory();
  final database = ProbeDatabase.open(
    File('${directory.path}/platform-probe.sqlite'),
  );
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

class PlatformProbePage extends ConsumerStatefulWidget {
  const PlatformProbePage({super.key});

  @override
  ConsumerState<PlatformProbePage> createState() => _PlatformProbePageState();
}

class _PlatformProbePageState extends ConsumerState<PlatformProbePage> {
  final _notifications = ProbeNotifications();
  bool _busy = false;
  String _message = '尚未运行。验证数据与工时数据分开保存。';

  Future<void> _run(Future<String> Function() operation) async {
    setState(() => _busy = true);
    try {
      final message = await operation();
      if (mounted) setState(() => _message = message);
    } catch (error) {
      if (mounted) setState(() => _message = '验证失败：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('平台验证（开发版）')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('本页只验证平台能力，不写入工资记录。'),
            const SizedBox(height: 16),
            SelectableText(_message, key: const Key('probeResult')),
            const SizedBox(height: 16),
            FilledButton.tonal(
              key: const Key('sqliteProbe'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      final db = await ref.read(_databaseProvider.future);
                      final value = await db.incrementCounter();
                      return 'SQLite 写入及回读成功：$value 次。重启后可继续读取。';
                    }),
              child: const Text('写入并读取 SQLite'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      final db = await ref.read(_databaseProvider.future);
                      return '已持久保存的次数：${await db.readCounter()}';
                    }),
              child: const Text('只读取已保存数据'),
            ),
            FilledButton.tonal(
              key: const Key('fileProbe'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      final db = await ref.read(_databaseProvider.future);
                      final file = await ProbeFiles().createExport(
                        await db.readCounter(),
                      );
                      final value = ProbeFileCodec.decode(
                        await file.readAsBytes(),
                      );
                      return '本地 JSON 写入及回读成功：$value';
                    }),
              child: const Text('验证本地文件往返'),
            ),
            TextButton(
              key: const Key('saveProbe'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      final db = await ref.read(_databaseProvider.future);
                      final uri = await ProbeFiles().saveToUserLocation(
                        await db.readCounter(),
                      );
                      return uri == null ? '已取消保存，现有数据未改变。' : '系统文件保存成功。';
                    }),
              child: const Text('打开系统保存对话框'),
            ),
            TextButton(
              key: const Key('importProbe'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      final value = await ProbeFiles().selectAndRead();
                      return value == null
                          ? '已取消文件选择，现有数据未改变。'
                          : '系统文件选择及读取成功：$value';
                    }),
              child: const Text('选择验证文件并读取'),
            ),
            FilledButton.tonal(
              key: const Key('notificationProbe'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      final zone = await _notifications.initialize();
                      final granted = await _notifications.requestPermission();
                      if (!granted) return '通知未授权，其他记账功能仍可使用。';
                      await _notifications.schedule(
                        delay: const Duration(minutes: 1),
                      );
                      final pending = await _notifications.isPending();
                      return '时区：$zone；待处理验证通知：$pending。'
                          '最早一分钟后提醒，系统可能延迟。';
                    }),
              child: const Text('请求通知权限并安排验证提醒'),
            ),
            TextButton(
              key: const Key('cancelNotificationProbe'),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      await _notifications.initialize();
                      await _notifications.cancel();
                      return '取消后待处理验证通知：${await _notifications.isPending()}';
                    }),
              child: const Text('取消验证提醒并查询'),
            ),
            if (_busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
