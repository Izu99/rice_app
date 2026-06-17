import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app.dart';
import 'core/constants/si_strings.dart';
import 'injection_container.dart' as di;
import 'core/utils/bloc_observer.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Show ALL Flutter errors on screen (not just in console)
      FlutterError.onError = (FlutterErrorDetails details) {
        print('=== FLUTTER ERROR ===');
        print(details.exceptionAsString());
        print(details.stack);
        print('====================');
        // Show the error on screen too
        FlutterError.presentError(details);
      };

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      print('=== STARTUP: initDependencies ===');
      await di.initDependencies();
      print('=== STARTUP: dependencies done ===');

      await SiStrings.initialize();
      print('=== STARTUP: language done ===');

      Bloc.observer = AppBlocObserver();

      print('=== STARTUP: runApp ===');
      runApp(const RiceMillApp());
    },
    (Object error, StackTrace stack) {
      // This catches ALL unhandled async errors
      print('=== UNHANDLED ERROR: $error ===');
      print('TYPE: ${error.runtimeType}');
      print('STACK: $stack');

      // Show a visible error screen
      runApp(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.red[900],
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'APP STARTUP ERROR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${error.runtimeType}:\n$error',
                    style: const TextStyle(color: Colors.yellow, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$stack',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
