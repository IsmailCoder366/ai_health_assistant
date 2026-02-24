import 'package:ai_healthcare_assistant/screens/chart_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Health Assistant',
      theme : ThemeData(
        fontFamily: 'SF Pro Display',
        primaryColor: Color(0xff00BFA6),
        scaffoldBackgroundColor: Color(0xffF8FFFE),
        colorScheme: ColorScheme.dark(
          primary: Color(0xff00BFA6),
          secondary: Color(0xff4CAF50),
          surface: Colors.white,
          background:Color(0xffF8FFFE)
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Color(0xff00BFA6)
          ),
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600
          ),
        )
      ),

      home: ChartScreen(),
    );
  }
}


