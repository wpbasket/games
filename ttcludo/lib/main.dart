import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/theme/ludo_colors.dart';
import 'ui/theme/app_feedback.dart';
import 'ui/screens/mode_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(LudoColors.systemUiStyle);
  await AppFeedback.init();

  runApp(const LudoApp());
}

class LudoApp extends StatelessWidget {
  const LudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ttcLudo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        fontFamily: 'sans-serif',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: LudoColors.systemUiStyle,
        ),
      ),
      home: const ModeSelectionScreen(),
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Guard against transient near-zero viewports when Chrome DevTools docks or toggles device mode
            if (constraints.maxWidth < 150 || constraints.maxHeight < 150) {
              return const SizedBox.shrink();
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
