import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../router/route_names.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../state/auth_state.dart';

import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/custom_auth_field.dart';
import '../widgets/custom_auth_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;
  UserRole _selectedRole = UserRole.farmer; // Default to farmer
  String _currentLanguage = 'EN'; // Language selector state

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to Terms & Conditions')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (name.isNotEmpty &&
        phone.isNotEmpty &&
        password.isNotEmpty &&
        confirm.isNotEmpty) {
      if (password != confirm) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
        return;
      }
      ref
          .read(authControllerProvider.notifier)
          .signup(
            name: name,
            phone: phone,
            email: email.isEmpty ? null : email,
            password: password,
            role: _selectedRole,
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'EN' ? 'HI' : 'EN';
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next is Authenticated) {
        context.go(RouteNames.disease);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
      }
    });

    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image Layer
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45 + 40,
            child: Image.asset(
              'assets/onboarding/signup_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Back Arrow
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.9),
              radius: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                  size: 20,
                ),
                onPressed:
                    () =>
                        context.canPop()
                            ? context.pop()
                            : context.go(RouteNames.login),
                padding: EdgeInsets.zero,
              ),
            ),
          ),

          // Language Selector
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: _toggleLanguage,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language, size: 16, color: Colors.black87),
                    const SizedBox(width: 4),
                    Text(
                      _currentLanguage,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.70,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Role Selector
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.authBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.divider.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children:
                            UserRole.values.map((role) {
                              final isSelected = _selectedRole == role;
                              return Expanded(
                                child: GestureDetector(
                                  onTap:
                                      () =>
                                          setState(() => _selectedRole = role),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                              : [],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      role.name[0].toUpperCase() +
                                          role.name.substring(1), // capitalize
                                      style: TextStyle(
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                        color:
                                            isSelected
                                                ? AppColors.textPrimary
                                                : AppColors.textHint,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    CustomAuthField(
                      controller: _nameController,
                      hintText: 'Full Name',
                      prefixIcon: CupertinoIcons.person,
                    ),
                    const SizedBox(height: 12),

                    CustomAuthField(
                      controller: _phoneController,
                      hintText: 'Phone Number',
                      prefixIcon: CupertinoIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    CustomAuthField(
                      controller: _emailController,
                      hintText: 'Email (Optional)',
                      prefixIcon: CupertinoIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    CustomAuthField(
                      controller: _passwordController,
                      hintText: 'Create Password',
                      prefixIcon: CupertinoIcons.lock,
                      isPassword: true,
                      suffixIcon: Icon(
                        CupertinoIcons.eye_slash,
                        color: AppColors.authIconColor.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),

                    CustomAuthField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm Password',
                      prefixIcon: CupertinoIcons.lock,
                      isPassword: true,
                      suffixIcon: Icon(
                        CupertinoIcons.eye_slash,
                        color: AppColors.authIconColor.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (val) {
                              setState(() => _agreedToTerms = val ?? false);
                            },
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                            children: [
                              TextSpan(text: 'I agree to '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    CustomAuthButton(
                      text: 'Create Account',
                      onPressed: _signup,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(RouteNames.login),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
