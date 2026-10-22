import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router.dart' show platformProbesEnabled;

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  if (platformProbesEnabled) {
    // Keep the real semantics tree available to native accessibility/UI tools
    // for the lifetime of this explicitly enabled developer build.
    binding.ensureSemantics();
  }
  runApp(const ProviderScope(child: WorktimeApp()));
}
