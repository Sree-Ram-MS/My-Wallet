import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/wallet_provider.dart';
import '../../models/category.dart';
import '../navigation_drawer.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedColor = '0xFF9C27B0'; // Purple default
  String _selectedIcon = 'category';

  final List<String> _colors = const [
    '0xFFC62828', // Red
    '0xFFAD1457', // Pink
    '0xFF6A1B9A', // Purple
    '0xFF1A237E', // Indigo
    '0xFF0277BD', // Blue
    '0xFF009688', // Teal
    '0xFF2E7D32', // Green
    '0xFFD84315', // Orange
    '0xFF37474F', // Grey
  ];

  final List<Map<String, dynamic>> _icons = const [
    {'name': 'category', 'icon': Icons.category},
    {'name': 'restaurant', 'icon': Icons.restaurant},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag},
    {'name': 'directions_car', 'icon': Icons.directions_car},
    {'name': 'sports_esports', 'icon': Icons.sports_esports},
    {'name': 'electrical_services', 'icon': Icons.electrical_services},
    {'name': 'monetization_on', 'icon': Icons.monetization_on},
    {'name': 'work', 'icon': Icons.work},
    {'name': 'flight', 'icon': Icons.flight},
    {'name': 'medical_services', 'icon': Icons.medical_services},
    {'name': 'school', 'icon': Icons.school},
    {'name': 'fitness_center', 'icon': Icons.fitness_center},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  IconData _getIconData(String name) {
    final match = _icons.where((item) => item['name'] == name);
    return match.isNotEmpty ? match.first['icon'] as IconData : Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final walletProv = Provider.of<WalletProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const CustomNavigationDrawer(),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        title: Text(
          'Categories Manager',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: walletProv.categories.isEmpty
          ? const Center(child: Text('No categories loaded.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: walletProv.categories.length,
              itemBuilder: (context, idx) {
                final cat = walletProv.categories[idx];
                Color color;
                try {
                  color = Color(int.parse(cat.color));
                } catch (_) {
                  color = Colors.grey;
                }

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconData(cat.icon),
                          color: color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          cat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddSheet(context, walletProv),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WalletProvider walletProv) {
    _nameController.clear();
    _selectedColor = '0xFF9C27B0';
    _selectedIcon = 'category';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Custom Category',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(hintText: 'Category Name e.g., Subscriptions'),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 20),

                      // Color circles
                      const Text('Accent Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _colors.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final colStr = _colors[i];
                            final col = Color(int.parse(colStr));
                            final isSel = _selectedColor == colStr;
                            return GestureDetector(
                              onTap: () => setDialogState(() => _selectedColor = colStr),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                                child: isSel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Icon selectors
                      const Text('Choose Icon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: GridView.builder(
                          shrinkWrap: true,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _icons.length,
                          itemBuilder: (context, i) {
                            final iconItem = _icons[i];
                            final String name = iconItem['name']!;
                            final IconData data = iconItem['icon']!;
                            final isSel = _selectedIcon == name;

                            return GestureDetector(
                              onTap: () => setDialogState(() => _selectedIcon = name),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSel ? Color(int.parse(_selectedColor)) : Colors.grey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(data, color: isSel ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey[700]), size: 20),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final uuid = const Uuid();
                              final newCat = Category(
                                id: uuid.v4(),
                                name: _nameController.text.trim(),
                                color: _selectedColor,
                                icon: _selectedIcon,
                                isArchived: false,
                              );

                              await walletProv.addCategory(newCat);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Custom category added!')),
                                );
                              }
                            }
                          },
                          child: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
