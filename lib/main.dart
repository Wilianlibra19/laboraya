import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'data/local/hive_service.dart';
import 'data/firebase/firebase_job_repository.dart';
import 'data/firebase/firebase_user_repository.dart';
import 'data/firebase/firebase_message_repository.dart';
import 'core/services/job_service.dart';
import 'core/services/user_service.dart';
import 'core/services/message_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/notification_service.dart';
import 'screens/auth/splash_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicializar notificaciones
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();
  
  // Inicializar Hive (solo para tema)
  await HiveService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeService(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserService(FirebaseUserRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => JobService(FirebaseJobRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => MessageService(FirebaseMessageRepository()),
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'LaboraYa',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
