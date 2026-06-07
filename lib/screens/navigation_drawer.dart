import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/currency_helper.dart';

class CustomNavigationDrawer extends StatelessWidget {
  const CustomNavigationDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final user = authProv.user;
    final isDark = themeProv.isDarkMode;

    // Resolve user avatar
    final hasPic = user?.profilePicUrl != null && user!.profilePicUrl!.startsWith('http');
    final avatar = CircleAvatar(
      radius: 32,
      backgroundColor: Colors.white.withOpacity(0.25),
      backgroundImage: hasPic ? NetworkImage(user!.profilePicUrl!) : null,
      child: !hasPic
          ? Text(
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'G',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            )
          : null,
    );

    return Drawer(
      child: Container(
        color: isDark ? const Color(0xFF0F2027) : Colors.white,
        child: Column(
          children: [
            // 1. Beautiful Custom Drawer Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 20,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
                      : [const Color(0xFF1A237E), const Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatar,
                      // Theme Toggle IconButton (Sun/Moon)
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        onPressed: () {
                          themeProv.toggleTheme();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Guest User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          user?.email ?? 'guest@local.device',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Perfectly Aligned Currency Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Text(
                          CurrencyHelper.getSymbol(authProv.defaultCurrency),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 2. Drawer Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    routeName: '/home',
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    title: 'Transactions History',
                    routeName: '/records',
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.schedule_outlined,
                    title: 'Planned Payments',
                    routeName: '/planned-payments',
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.handshake_outlined,
                    title: 'Debts (Lent)',
                    routeName: '/debts',
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.monetization_on_outlined,
                    title: 'Credits (Borrowed)',
                    routeName: '/credits',
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.grid_view_outlined,
                    title: 'Categories',
                    routeName: '/categories',
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.copy_all_outlined,
                    title: 'Templates',
                    routeName: '/templates',
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.publish_outlined,
                    title: 'Import CSV/Excel',
                    routeName: '/import',
                    isDark: isDark,
                  ),
                  Divider(color: isDark ? Colors.white12 : Colors.black12, height: 16),
                  _buildDrawerTile(
                    context: context,
                    icon: Icons.manage_accounts_outlined,
                    title: 'Settings & Cloud Backup',
                    routeName: '/profile/edit',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // 3. Sign Out Row
            SafeArea(
              top: false,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFEF5350)),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await authProv.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/auth');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String routeName,
    required bool isDark,
  }) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isSelected = currentRoute == routeName;

    Color tileColor = Colors.transparent;
    Color iconColor = isDark ? Colors.white70 : const Color(0xFF37474F);
    Color textColor = isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF263238);

    if (isSelected) {
      tileColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFF1A237E).withOpacity(0.08);
      iconColor = isDark ? const Color(0xFF2196F3) : const Color(0xFF1A237E);
      textColor = isDark ? Colors.white : const Color(0xFF1A237E);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        trailing: isSelected 
            ? Icon(Icons.chevron_right, color: iconColor)
            : null,
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, routeName);
          }
        },
      ),
    );
  }
}
