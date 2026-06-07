import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/lock_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/account/add_account_screen.dart';
import 'screens/account/edit_account_screen.dart';
import 'screens/account/manage_accounts_screen.dart';
import 'screens/record/add_record_screen.dart';
import 'screens/record/edit_record_screen.dart';
import 'screens/drawer/records_screen.dart';
import 'screens/drawer/planned_payments_screen.dart';
import 'screens/drawer/debts_screen.dart';
import 'screens/drawer/credits_screen.dart';
import 'screens/drawer/category_screen.dart';
import 'screens/drawer/templates_screen.dart';
import 'screens/drawer/import_screen.dart';
import 'screens/drawer/edit_profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyWalletApp());
}

class MyWalletApp extends StatelessWidget {
  const MyWalletApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initTheme()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProv, child) {
          return MaterialApp(
            title: 'My Wallet',
            debugShowCheckedModeBanner: false,
            themeMode: themeProv.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: const Color(0xFF1A237E),
              scaffoldBackgroundColor: const Color(0xFFF5F7FA),
              cardColor: Colors.white,
              dialogBackgroundColor: Colors.white,
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF1A237E),
                secondary: Color(0xFF2196F3),
                surface: Colors.white,
                background: Color(0xFFF5F7FA),
              ),
              fontFamily: 'Inter',
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: Color(0xFF263238)),
                titleTextStyle: TextStyle(color: Color(0xFF263238), fontSize: 20, fontWeight: FontWeight.bold),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFFE0E0E0),
                labelStyle: const TextStyle(color: Color(0xFF263238)),
                hintStyle: const TextStyle(color: Colors.black38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: const Color(0xFF1A237E),
              scaffoldBackgroundColor: const Color(0xFF0F2027),
              cardColor: const Color(0xFF162A35),
              dialogBackgroundColor: const Color(0xFF162A35),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF2196F3),
                secondary: Color(0xFF00E676),
                surface: Color(0xFF162A35),
                background: Color(0xFF0F2027),
              ),
              fontFamily: 'Inter',
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF0F2027),
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF1E333F),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: const TextStyle(color: Colors.white30),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              useMaterial3: true,
            ),
            initialRoute: '/auth',
            routes: {
              '/auth': (context) => const AuthScreen(),
              '/lock': (context) => const LockScreen(),
              '/home': (context) => const HomeScreen(),
              '/accounts': (context) => const ManageAccountsScreen(),
              '/account/add': (context) => const AddAccountScreen(),
              '/account/edit': (context) => const EditAccountScreen(),
              '/record/add': (context) => const AddRecordScreen(),
              '/record/edit': (context) => const EditRecordScreen(),
              '/records': (context) => const RecordsScreen(),
              '/planned-payments': (context) => const PlannedPaymentsScreen(),
              '/debts': (context) => const DebtsScreen(),
              '/credits': (context) => const CreditsScreen(),
              '/categories': (context) => const CategoryScreen(),
              '/templates': (context) => const TemplatesScreen(),
              '/import': (context) => const ImportScreen(),
              '/profile/edit': (context) => const EditProfileScreen(),
            },
          );
        },
      ),
    );
  }
}
