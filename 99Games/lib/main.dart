import 'package:flutter/material.dart';
import 'app/app.dart';
import 'di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure dependencies including local storage
  await configureDependencies();

  runApp(const NinetyNineGamesApp());
}
