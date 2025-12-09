import 'package:flutter/material.dart';
import 'package:schedsync_app/home/home_screen.dart';
import 'package:schedsync_app/login/login_screen.dart';
import 'package:schedsync_app/login/signup_screen.dart';
import 'package:schedsync_app/model/base_app_user.dart';
import 'package:horizontal_week_calendar/horizontal_week_calendar.dart';

// SchedSync brand color 
Color defaultColor = const Color(0xFF3A3A3A);

final kColorScheme = ColorScheme.fromSeed(
  seedColor: defaultColor,
  brightness: Brightness.light,
);

final kDarkColorScheme = ColorScheme.fromSeed(
  seedColor: defaultColor,
  brightness: Brightness.dark,
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  BaseAppUser? _currentUser;
  String? _registrationMessage;

  void _switchTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  

  void _onLoginSuccess(BaseAppUser user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _onLogout() {
    setState(() {
      _currentUser = null;
    });
  }

  void _onRegistrationSuccess(String message) {
    setState(() {
      _registrationMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_currentUser != null) {
      content = HomeScreen(
        _switchTheme,
        currentUser: _currentUser!,
        logout: _onLogout,
      );
    } else {
      content = Builder(
        builder: (ctx) {
          return LoginScreen(
            _switchTheme,
            _registrationMessage != null,
            _registrationMessage ?? '',
            goToHome: _onLoginSuccess,
            goToRegister: () {
              Navigator.of(ctx).push(
                MaterialPageRoute(
                  builder: (context) => SignupScreen(
                    _switchTheme,
                    successRegister: (msg) {
                      _onRegistrationSuccess(msg);
                      Navigator.of(context).pop();
                    },
                    cancelRegister: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return MaterialApp(
      title: 'SchedSync',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // LIGHT MODE
      theme: ThemeData().copyWith(
        colorScheme: kColorScheme,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: const Color.fromARGB(151, 255, 255, 255)

        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
          )
        ),
         textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
           foregroundColor: Colors.black,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white70,
            foregroundColor: Colors.black,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        textTheme: TextTheme(
           bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 14),
        ),
      ),

      // DARK MODE
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: kDarkColorScheme,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1C1C),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: const Color.fromARGB(165, 0, 0, 0)
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
           foregroundColor: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white70,
            foregroundColor: Colors.black,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
          )
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),

        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 14),
        ),
      ),

      home: content,
    );
  }
}
