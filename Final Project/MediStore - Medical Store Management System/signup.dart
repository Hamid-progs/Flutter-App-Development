import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medistore/login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool flag = false;
  bool _obscurePassword = true;
  final SignupObject = Supabase.instance.client;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  SignupFunction() async {
    if (_emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _nameCtrl.text.trim().isEmpty) {
      _showError('All fields are required');
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    setState(() => flag = true);
    try {
      final result = await SignupObject.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        data: {'full_name': _nameCtrl.text.trim()},
      );
      if (result.user != null) {
        await SignupObject.from('profiles').insert({
          'id': result.user!.id,
          'email': _emailCtrl.text.trim(),
          'full_name': _nameCtrl.text.trim(),
          'role': 'user',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        flag=false;
      });
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:  Color(0xFF0F6E56),
        leading: IconButton(
          icon:  Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title:  Text(
          'Create Account',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:  EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             SizedBox(height: 30),
             Text(
              'Join MediStore',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
             Text(
              'Create your account to get started',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
             SizedBox(height: 28),
             Text(
              'Full Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
             SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                prefixIcon:  Icon(
                  Icons.person_outline,
                  color: Color(0xFF0F6E56),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:  BorderSide(
                    color: Color(0xFF0F6E56),
                    width: 2,
                  ),
                ),
              ),
            ),
             SizedBox(height: 16),
             Text(
              'Email',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
             SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                prefixIcon:  Icon(
                  Icons.email_outlined,
                  color: Color(0xFF0F6E56),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:  BorderSide(
                    color: Color(0xFF0F6E56),
                    width: 2,
                  ),
                ),
              ),
            ),
             SizedBox(height: 16),
             Text(
              'Password',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
             SizedBox(height: 6),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Min. 6 characters',
                prefixIcon:  Icon(
                  Icons.lock_outline,
                  color: Color(0xFF0F6E56),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF0F6E56),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: flag
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0F6E56),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: SignupFunction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F6E56),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    color: Color(0xFF0F6E56),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
