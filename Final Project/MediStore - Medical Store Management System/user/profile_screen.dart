import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medistore/login.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? profile;
  bool isLoading = true;
  bool isSaving = false;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser!;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      setState(() {
        profile = data;
        nameCtrl.text = data['full_name'] ?? '';
        phoneCtrl.text = data['phone'] ?? '';
        addressCtrl.text = data['address'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => isSaving = true);
    try {
      final user = supabase.auth.currentUser!;
      await supabase.from('profiles').update({
        'full_name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'address': addressCtrl.text.trim(),
      }).eq('id', user.id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
    setState(() => isSaving = false);
  }

  void _logout() async {
    await supabase.auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final email = user?.email ?? '';
    final name =
        nameCtrl.text.isNotEmpty ? nameCtrl.text : email.split('@')[0];
    final role = profile?['role'] ?? 'user';

    return isLoading
        ?  Center(
            child: CircularProgressIndicator(color: Color(0xFF0F6E56)))
        : SingleChildScrollView(
            padding:  EdgeInsets.all(16),
            child: Column(
              children: [
                 SizedBox(height: 10),
                CircleAvatar(
                  radius: 48,
                  backgroundColor:  Color(0xFF0F6E56),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                 SizedBox(height: 12),
                Text(name,
                    style:  TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(email,
                    style:  TextStyle(color: Colors.grey, fontSize: 14)),
                 SizedBox(height: 6),
                Container(
                  padding:  EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color:  Color(0xFF0F6E56).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style:  TextStyle(
                        color: Color(0xFF0F6E56),
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                 SizedBox(height: 28),
                Container(
                  padding:  EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset:  Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text('Edit Profile',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                       SizedBox(height: 16),
                      _buildField(nameCtrl, 'Full Name', Icons.person),
                       SizedBox(height: 12),
                      _buildField(phoneCtrl, 'Phone Number', Icons.phone,
                          keyboardType: TextInputType.phone),
                       SizedBox(height: 12),
                      _buildField(
                          addressCtrl, 'Address', Icons.location_on,
                          maxLines: 2),
                       SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:  Color(0xFF0F6E56),
                            padding:
                                 EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isSaving ? null : _saveProfile,
                          child: isSaving
                              ?  SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              :  Text('Save Changes',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
                 SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon:  Icon(Icons.logout, color: Colors.red),
                    label:  Text('Logout',
                        style: TextStyle(color: Colors.red, fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      side:  BorderSide(color: Colors.red),
                      padding:  EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _logout,
                  ),
                ),
                 SizedBox(height: 20),
              ],
            ),
          );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color:  Color(0xFF0F6E56)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:  BorderSide(color: Color(0xFF0F6E56), width: 2),
        ),
      ),
    );
  }
}
