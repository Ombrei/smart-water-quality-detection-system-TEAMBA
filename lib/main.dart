import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'splash_page.dart';
import 'ai_assistant_overlay.dart';


// TODO: Uncomment when Firebase is configured
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Uncomment when Firebase is configured
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const SmartPureApp());
}

class SmartPureApp extends StatelessWidget {
  const SmartPureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartPure Home',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashPage(),
   builder: (context, child) {
        return AIAssistantOverlay(child: child!);
      },
    );
  }
}
