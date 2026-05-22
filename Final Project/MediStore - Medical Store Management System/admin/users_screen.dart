import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        users = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _toggleRole(String id, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    try {
      await supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', id);
      _showSuccess('Role updated to $newRole');
      _loadUsers();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF0F6E56)))
        : users.isEmpty
            ? const Center(
                child: Text('No users found',
                    style: TextStyle(color: Colors.grey, fontSize: 16)))
            : RefreshIndicator(
                onRefresh: _loadUsers,
                color: const Color(0xFF0F6E56),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  itemBuilder: (_, i) {
                    final u = users[i];
                    final role = u['role'] ?? 'user';
                    final isAdmin = role == 'admin';
                    final email = u['email'] ?? 'N/A';
                    final name = u['full_name'] ?? email.split('@')[0];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: isAdmin
                              ? const Color(0xFF0F6E56)
                              : Colors.blue.shade100,
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: isAdmin ? Colors.white : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? const Color(0xFF0F6E56)
                                        .withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  color: isAdmin
                                      ? const Color(0xFF0F6E56)
                                      : Colors.blue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'toggle') {
                              _confirmToggleRole(
                                  u['id'].toString(), role);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    isAdmin
                                        ? Icons.person_remove
                                        : Icons.admin_panel_settings,
                                    color: isAdmin
                                        ? Colors.red
                                        : const Color(0xFF0F6E56),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(isAdmin
                                      ? 'Remove Admin'
                                      : 'Make Admin'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
  }

  void _confirmToggleRole(String id, String currentRole) {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Role'),
        content:
            Text('Change this user\'s role to "$newRole"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F6E56)),
            onPressed: () {
              Navigator.pop(context);
              _toggleRole(id, currentRole);
            },
            child: const Text('Confirm',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
