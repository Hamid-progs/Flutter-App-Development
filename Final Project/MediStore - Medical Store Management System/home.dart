import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medistore/admin/admin_panel.dart';
import 'package:medistore/user/user_panel.dart';
import 'package:medistore/login.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _start(); // call a void function
  }

  void _start() {
    _checkRole(); // call async function from inside void function
  }

  Future<void> _checkRole() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
              (_) => false,
        );
        return;
      }
      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      setState(() {
        isAdmin = response['role'] == 'admin';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return  Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F6E56)),
        ),
      );
    }
    return isAdmin ?  AdminPanel() :  UserPanel();
  }
}
