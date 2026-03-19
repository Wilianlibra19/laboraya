import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/user_service.dart';
import '../../utils/constants.dart';
import '../auth/welcome_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isDeleting = false;
  bool _confirmDelete = false;

  @override
  void dispose() {
    _passwordController.dispose();
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

  Future<void> _deleteAccount() async {
    if (_isDeleting) return;

    final password = _passwordController.text.trim();

    if (!_confirmDelete) {
      _showMessage('Debes confirmar que deseas eliminar tu cuenta', isError: true);
      return;
    }

    if (password.isEmpty) {
      _showMessage('Ingresa tu contraseña', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isDeleting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Usuario no encontrado');
      }

      final userId = user.uid;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      final firestore = FirebaseFirestore.instance;

      final jobs = await firestore
          .collection('jobs')
          .where('createdBy', isEqualTo: userId)
          .get();
      for (final doc in jobs.docs) {
        await doc.reference.delete();
      }

      final sentMessages = await firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .get();
      for (final doc in sentMessages.docs) {
        await doc.reference.delete();
      }

      final receivedMessages = await firestore
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .get();
      for (final doc in receivedMessages.docs) {
        await doc.reference.delete();
      }

      final notifications = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in notifications.docs) {
        await doc.reference.delete();
      }

      final applications = await firestore
          .collection('job_applications')
          .where('applicantId', isEqualTo: userId)
          .get();
      for (final doc in applications.docs) {
        await doc.reference.delete();
      }

      final favorites = await firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in favorites.docs) {
        await doc.reference.delete();
      }

      final reports = await firestore
          .collection('reports')
          .where('reporterId', isEqualTo: userId)
          .get();
      for (final doc in reports.docs) {
        await doc.reference.delete();
      }

      final reviews = await firestore
          .collection('reviews')
          .where('reviewerId', isEqualTo: userId)
          .get();
      for (final doc in reviews.docs) {
        await doc.reference.delete();
      }

      final blocks = await firestore
          .collection('blocked_users')
          .where('blockerId', isEqualTo: userId)
          .get();
      for (final doc in blocks.docs) {
        await doc.reference.delete();
      }

      final portfolio = await firestore
          .collection('portfolio')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in portfolio.docs) {
        await doc.reference.delete();
      }

      final verifications = await firestore
          .collection('verifications')
          .where('userId', isEqualTo: userId)
          .get();
      for (final doc in verifications.docs) {
        await doc.reference.delete();
      }

      final referrals = await firestore
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .get();
      for (final doc in referrals.docs) {
        await doc.reference.delete();
      }

      await firestore.collection('users').doc(userId).delete();
      await user.delete();

      await context.read<UserService>().logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );

      _showMessage('Cuenta eliminada correctamente');
    } on FirebaseAuthException catch (e) {
      String message = 'Error al eliminar cuenta';

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Contraseña incorrecta';
      } else if (e.code == 'too-many-requests') {
        message = 'Demasiados intentos. Intenta más tarde';
      } else if (e.code == 'requires-recent-login') {
        message = 'Por seguridad, vuelve a iniciar sesión';
      } else if (e.code == 'user-not-found') {
        message = 'Usuario no encontrado';
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }

      _showMessage(message, isError: true);
    } catch (e) {
      _showMessage('No se pudo eliminar la cuenta', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 54, 16, 26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE53935),
                  const Color(0xFFD32F2F),
                  const Color(0xFFEF5350).withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Material(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      height: 42,
                      width: 42,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eliminar cuenta',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Esta acción es permanente y no se puede deshacer',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1E22) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFE8EEF6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.red,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Antes de continuar',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF162033),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Se eliminará toda tu información de LaboraYa. Revisa bien antes de confirmar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _DeleteInfoCard(
                  title: 'Se eliminará',
                  items: const [
                    'Tu perfil y datos personales',
                    'Tus trabajos publicados',
                    'Tus mensajes y notificaciones',
                    'Tus favoritos, reportes y reseñas',
                    'Tu portafolio y verificaciones',
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1E22) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFE8EEF6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirma tu contraseña',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF162033),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Ingresa tu contraseña',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF232831)
                              : const Color(0xFFF8FAFD),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : const Color(0xFFE8EEF6),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _confirmDelete,
                        activeColor: Colors.red,
                        title: const Text(
                          'Entiendo que esta acción es permanente',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'No podré recuperar mi cuenta después',
                        ),
                        onChanged: (value) {
                          setState(() => _confirmDelete = value ?? false);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isDeleting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(color: Colors.grey.withOpacity(0.30)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isDeleting ? null : _deleteAccount,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.delete_forever_rounded),
                    label: Text(
                      _isDeleting ? 'Eliminando cuenta...' : 'Eliminar cuenta',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteInfoCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _DeleteInfoCard({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF162033),
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isDark ? Colors.white70 : Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}