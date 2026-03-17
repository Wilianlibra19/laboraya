import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/models/user_model.dart';
import '../../core/services/user_service.dart';
import '../../core/services/notification_service.dart';
import '../../utils/constants.dart';
import '../onboarding/onboarding_screen.dart';
import '../legal/terms_screen.dart';
import '../legal/privacy_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los Términos y Condiciones'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('No se pudo crear el usuario');
      }

      final newUser = UserModel(
        id: credential.user!.uid,
        name: _nameController.text.trim(),
        email: email,
        phone: _phoneController.text.trim(),
        district: 'Lima',
        rating: 0.0,
        completedJobs: 0,
        skills: [],
        availability: 'Disponible',
        description: 'Nuevo usuario',
        documents: [],
        createdAt: DateTime.now(),
      );

      await context.read<UserService>().createUser(newUser);
      await context.read<UserService>().login(newUser.id);
      await NotificationService.saveUserToken(newUser.id);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = 'Error al crear cuenta';
      
      if (e.code == 'weak-password') {
        message = 'La contraseña es muy débil';
      } else if (e.code == 'email-already-in-use') {
        message = 'Ya existe una cuenta con este email';
      } else if (e.code == 'invalid-email') {
        message = 'Email inválido';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              
              // Título
              Text(
                'Únete a LaboraYa',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2C3E50),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Crea tu cuenta y empieza a trabajar',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 28),
              
              // Card de registro
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Crear Cuenta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF2C3E50),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completa tus datos',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Nombre
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nombre completo',
                        hint: 'Juan Pérez',
                        icon: Icons.person_outline,
                        isDark: isDark,
                        validator: (value) => value?.isEmpty ?? true ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 14),
                      
                      // Email
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'tu@email.com',
                        icon: Icons.email_outlined,
                        isDark: isDark,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Ingresa tu email';
                          if (!value!.contains('@')) return 'Email inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      
                      // Teléfono
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Teléfono',
                        hint: '+51 999 999 999',
                        icon: Icons.phone_outlined,
                        isDark: isDark,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Ingresa tu teléfono';
                          if (value!.length < 9) return 'Teléfono inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      
                      // Contraseña
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        isDark: isDark,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Ingresa tu contraseña';
                          if (value!.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      
                      // Confirmar contraseña
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirmar contraseña',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        isDark: isDark,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Confirma tu contraseña';
                          if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Checkbox de términos
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                              activeColor: AppColors.primary,
                              checkColor: Colors.white,
                              side: BorderSide(
                                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12, left: 4),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      height: 1.4,
                                    ),
                                    children: [
                                      const TextSpan(text: 'Acepto los '),
                                      TextSpan(
                                        text: 'Términos y Condiciones',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const TermsScreen()),
                                            );
                                          },
                                      ),
                                      const TextSpan(text: ' y la '),
                                      TextSpan(
                                        text: 'Política de Privacidad',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.underline,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                                            );
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Botón de registro
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF1565C0)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Crear Cuenta',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Ya tienes cuenta
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes cuenta?',
                            style: TextStyle(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Inicia Sesión',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : const Color(0xFF2C3E50),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: isDark ? Colors.grey[500] : Colors.grey[400], size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }
}
