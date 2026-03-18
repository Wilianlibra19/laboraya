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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  final int _totalSteps = 6;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();

    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          _showMessage('Ingresa tu nombre completo', isError: true);
          return;
        }
        break;
      case 1:
        final email = _emailController.text.trim();
        if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
          _showMessage('Ingresa un correo válido', isError: true);
          return;
        }
        break;
      case 2:
        final phone = _phoneController.text.trim();
        if (phone.isEmpty || phone.replaceAll(RegExp(r'[^\d]'), '').length < 9) {
          _showMessage('Ingresa un teléfono válido', isError: true);
          return;
        }
        break;
      case 3:
        if (_passwordController.text.trim().length < 6) {
          _showMessage('La contraseña debe tener mínimo 6 caracteres', isError: true);
          return;
        }
        break;
      case 4:
        if (_confirmPasswordController.text.trim() != _passwordController.text.trim()) {
          _showMessage('Las contraseñas no coinciden', isError: true);
          return;
        }
        break;
      case 5:
        if (!_acceptedTerms) {
          _showMessage('Debes aceptar los términos y la privacidad', isError: true);
          return;
        }
        _register();
        return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _register() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
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
        description: 'Nuevo usuario en LaboraYa',
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
      String message = 'Error al crear cuenta';

      if (e.code == 'weak-password') {
        message = 'La contraseña es muy débil';
      } else if (e.code == 'email-already-in-use') {
        message = 'Ya existe una cuenta con este correo';
      } else if (e.code == 'invalid-email') {
        message = 'Correo inválido';
      } else if (e.code == 'too-many-requests') {
        message = 'Demasiados intentos. Intenta más tarde';
      }

      if (mounted) {
        _showMessage(message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Ocurrió un problema al crear tu cuenta', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        color: isDark ? const Color(0xFF0E1116) : const Color(0xFFF5F8FC),
        child: Stack(
          children: [
            _RegisterBackground(isDark: isDark),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(isDark),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 470),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildBrandTop(isDark),
                              const SizedBox(height: 24),
                              _buildStepCard(isDark),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildBottomAction(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: _currentStep > 0 ? _previousStep : () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFE8EEF6),
                    ),
                  ),
                  child: Icon(
                    _currentStep > 0 ? Icons.arrow_back_ios_new_rounded : Icons.close_rounded,
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xFF182234),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Paso ${_currentStep + 1} de $_totalSteps',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF667085),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              minHeight: 7,
              backgroundColor: isDark ? Colors.white12 : Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandTop(bool isDark) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF64B5F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.32),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            size: 42,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Crear cuenta',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF182234),
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Empieza en LaboraYa y conecta con nuevas oportunidades',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.45,
            color: isDark ? Colors.white70 : const Color(0xFF667085),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
            blurRadius: 36,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentStep),
          child: _buildStepContent(isDark),
        ),
      ),
    );
  }

  Widget _buildBottomAction(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF1565C0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.30),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _currentStep == _totalSteps - 1
                                ? Icons.check_circle_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _currentStep == _totalSteps - 1
                                ? 'Crear cuenta'
                                : 'Continuar',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tu información se usará para crear tu perfil de LaboraYa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white38 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildNameStep(isDark);
      case 1:
        return _buildEmailStep(isDark);
      case 2:
        return _buildPhoneStep(isDark);
      case 3:
        return _buildPasswordStep(isDark);
      case 4:
        return _buildConfirmPasswordStep(isDark);
      case 5:
        return _buildTermsStep(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNameStep(bool isDark) {
    return _StepLayout(
      icon: Icons.badge_outlined,
      title: '¿Cómo te llamas?',
      subtitle: 'Tu nombre será visible en tu perfil dentro de la app.',
      child: _ModernRegisterInput(
        controller: _nameController,
        label: 'Nombre completo',
        hint: 'Juan Pérez',
        icon: Icons.person_outline_rounded,
        isDark: isDark,
        autofocus: true,
      ),
    );
  }

  Widget _buildEmailStep(bool isDark) {
    return _StepLayout(
      icon: Icons.alternate_email_rounded,
      title: '¿Cuál es tu correo?',
      subtitle: 'Lo usaremos para iniciar sesión y recuperar tu cuenta.',
      child: _ModernRegisterInput(
        controller: _emailController,
        label: 'Correo electrónico',
        hint: 'tu@email.com',
        icon: Icons.email_outlined,
        isDark: isDark,
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
      ),
    );
  }

  Widget _buildPhoneStep(bool isDark) {
    return _StepLayout(
      icon: Icons.phone_android_rounded,
      title: 'Tu número de teléfono',
      subtitle: 'Ayuda a que puedan contactarte más rápido.',
      child: _ModernRegisterInput(
        controller: _phoneController,
        label: 'Teléfono',
        hint: '+51 999 999 999',
        icon: Icons.phone_outlined,
        isDark: isDark,
        keyboardType: TextInputType.phone,
        autofocus: true,
      ),
    );
  }

  Widget _buildPasswordStep(bool isDark) {
    return _StepLayout(
      icon: Icons.lock_outline_rounded,
      title: 'Crea una contraseña',
      subtitle: 'Usa una contraseña segura de al menos 6 caracteres.',
      child: Column(
        children: [
          _ModernRegisterInput(
            controller: _passwordController,
            label: 'Contraseña',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            isDark: isDark,
            obscureText: _obscurePassword,
            autofocus: true,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _PasswordTipBox(isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordStep(bool isDark) {
    return _StepLayout(
      icon: Icons.verified_user_outlined,
      title: 'Confirma tu contraseña',
      subtitle: 'Escribe nuevamente la contraseña para continuar.',
      child: _ModernRegisterInput(
        controller: _confirmPasswordController,
        label: 'Confirmar contraseña',
        hint: '••••••••',
        icon: Icons.lock_person_outlined,
        isDark: isDark,
        obscureText: _obscureConfirmPassword,
        autofocus: true,
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
          icon: Icon(
            _obscureConfirmPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
      ),
    );
  }

  Widget _buildTermsStep(bool isDark) {
    return _StepLayout(
      icon: Icons.verified_outlined,
      title: 'Acepta para continuar',
      subtitle: 'Revisa la información legal antes de crear tu cuenta.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2430) : const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFE8EEF6),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _acceptedTerms,
              onChanged: (value) {
                setState(() => _acceptedTerms = value ?? false);
              },
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: isDark ? Colors.white70 : const Color(0xFF667085),
                    ),
                    children: [
                      const TextSpan(text: 'Acepto los '),
                      TextSpan(
                        text: 'Términos y Condiciones',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsScreen(),
                              ),
                            );
                          },
                      ),
                      const TextSpan(text: ' y la '),
                      TextSpan(
                        text: 'Política de Privacidad',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyScreen(),
                              ),
                            );
                          },
                      ),
                      const TextSpan(
                        text: ' para usar LaboraYa.',
                      ),
                    ],
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

class _StepLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _StepLayout({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF182234),
            letterSpacing: -0.8,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.5,
            color: isDark ? Colors.white60 : const Color(0xFF667085),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        child,
      ],
    );
  }
}

class _ModernRegisterInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool autofocus;
  final Widget? suffixIcon;

  const _ModernRegisterInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType,
    this.obscureText = false,
    this.autofocus = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        fontSize: 16,
        color: isDark ? Colors.white : const Color(0xFF182234),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? const Color(0xFF1F2430) : const Color(0xFFF8FAFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : const Color(0xFFE8EEF6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    );
  }
}

class _PasswordTipBox extends StatelessWidget {
  final bool isDark;

  const _PasswordTipBox({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Te recomendamos combinar letras y números para una contraseña más segura.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark ? Colors.white70 : const Color(0xFF475467),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterBackground extends StatelessWidget {
  final bool isDark;

  const _RegisterBackground({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          right: -30,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(isDark ? 0.11 : 0.10),
            ),
          ),
        ),
        Positioned(
          top: 180,
          left: -70,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF64B5F6).withOpacity(isDark ? 0.08 : 0.10),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -50,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(isDark ? 0.07 : 0.07),
            ),
          ),
        ),
      ],
    );
  }
}