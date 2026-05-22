import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medistore/home.dart';
import 'package:medistore/signup.dart';
import 'package:medistore/admin/admin_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final EmailText = TextEditingController();
  final PasswordText = TextEditingController();
  bool flag = false;
  bool _obscurePassword = true;
  final LoginObject = Supabase.instance.client;

  LoginFunction() async {

    if (EmailText.text.trim().isEmpty ||
        PasswordText.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
        ),
      );

      return;
    }

    setState(() {
      flag = true;
    });

    try {

      final result = await LoginObject.auth.signInWithPassword(
        email: EmailText.text.trim(),
        password: PasswordText.text.trim(),
      );

      final user = result.user;

      if (user != null) {

        // Fetch profile data
        final profileData = await LoginObject
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        String role = profileData['role'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Successful!'),
          ),
        );

        // ADMIN LOGIN
        if (role == 'admin') {

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminPanel(),
            ),
                (route) => false,
          );
        }

        // USER LOGIN
        else {

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const Home(),
            ),
                (route) => false,
          );
        }
      }

    }

    on AuthException catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
        ),
      );
    }

    catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong'),
        ),
      );
    }

    finally {

      setState(() {
        flag = false;
      });
    }
  }


  @override
  void dispose() {
    EmailText.dispose();
    PasswordText.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding:  EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Container(
                        height: 84,
                        width: 84,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          color:  Color(0xFF0F6E56),
                        ),
                        child:  Icon(Icons.local_hospital_rounded,
                            color: Colors.white, size: 50),
                      ),
                       SizedBox(height: 16),
                       Text('MediStore',
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F6E56))),
                       Text('Your Health Our Priority',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                 SizedBox(height: 40),
                 Text('Welcome Back!',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
                 Text('Login to continue',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
                 SizedBox(height: 28),
                 Text('Email',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                 SizedBox(height: 6),
                TextField(
                  controller: EmailText,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon:  Icon(Icons.email_outlined,
                        color: Color(0xFF0F6E56)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:  BorderSide(
                          color: Color(0xFF0F6E56), width: 2),
                    ),
                  ),
                ),
                 SizedBox(height: 16),
                 Text('Password',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                 SizedBox(height: 6),


            TextField(
            controller: PasswordText,
            obscureText: _obscurePassword,

            decoration: InputDecoration(
              hintText: 'Enter your password',

              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFF0F6E56),
              ),

              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.grey,
                ),

                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
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
                              color: Color(0xFF0F6E56)))
                      : ElevatedButton(
                          onPressed: LoginFunction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F6E56),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Login',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.white)),
                        ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: const Text(
                      "Don't have an account? Sign up",
                      style: TextStyle(
                          color: Color(0xFF0F6E56),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
