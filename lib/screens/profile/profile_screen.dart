import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/theme_service.dart';
import '../../core/services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../auth/welcome_screen.dart';
import '../favorites/favorites_screen.dart';
import '../legal/privacy_screen.dart';
import '../legal/terms_screen.dart';
import '../referrals/referral_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/earnings_stats_screen.dart';
import '../verification/verify_identity_screen.dart';
import 'edit_profile_screen.dart';
import 'history_screen.dart';
import 'my_documents_screen.dart';
import 'my_jobs_screen.dart';
import 'reviews_screen.dart';
import 'work_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserService>().refreshCurrentUser();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<UserService>().refreshCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>().currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(context, user, isDark),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(user, isDark),
                  const SizedBox(height: 16),
                  _buildEarningsCard(user, isDark),
                  const SizedBox(height: 16),
                  _buildAboutCard(user, isDark),
                  const SizedBox(height: 16),
                  _buildSkillsCard(user, isDark),
                  const SizedBox(height: 16),
                  _buildAvailabilityCard(user, isDark),
                  const SizedBox(height: 20),
                  _buildMenuSection(
                    context,
                    isDark,
                    title: 'Mi actividad',
                    items: [
                      _MenuItemData(
                        icon: Icons.work_outline_rounded,
                        title: 'Mis Trabajos',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyJobsScreen()),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.folder_outlined,
                        title: 'Mis Documentos',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyDocumentsScreen()),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.favorite_border_rounded,
                        title: 'Favoritos',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.history_rounded,
                        title: 'Historial',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.work_history_outlined,
                        title: 'Trabajos Completados',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WorkHistoryScreen()),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.bar_chart_rounded,
                        title: 'Estadísticas',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EarningsStatsScreen(),
                            ),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.people_alt_outlined,
                        title: 'Referidos',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ReferralScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMenuSection(
                    context,
                    isDark,
                    title: 'Cuenta y preferencias',
                    items: [
                      _MenuItemData(
                        icon: Icons.brightness_6_outlined,
                        title: 'Modo Oscuro',
                        trailing: Consumer<ThemeService>(
                          builder: (context, themeService, child) {
                            return Switch(
                              value: themeService.isDarkMode,
                              onChanged: (_) {
                                themeService.toggleTheme();
                              },
                              activeColor: AppColors.primary,
                            );
                          },
                        ),
                        onTap: () {
                          context.read<ThemeService>().toggleTheme();
                        },
                      ),
                      if (!user.isVerified)
                        _MenuItemData(
                          icon: Icons.verified_user_outlined,
                          title: 'Verificar Identidad',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VerifyIdentityScreen(),
                              ),
                            );
                          },
                        ),
                      _MenuItemData(
                        icon: Icons.settings_outlined,
                        title: 'Configuración',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.description_outlined,
                        title: 'Términos y Condiciones',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TermsScreen()),
                          );
                        },
                      ),
                      _MenuItemData(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Política de Privacidad',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildLogoutCard(context, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic user, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.88),
            const Color(0xFF67C4FF),
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
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mi perfil',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              _HeaderIconButton(
                icon: Icons.refresh_rounded,
                onTap: () {
                  context.read<UserService>().refreshCurrentUser();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Perfil actualizado'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                icon: Icons.edit_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          CircleAvatar(
            radius: 48,
            backgroundColor: Colors.white,
            backgroundImage: user.photo != null && user.photo!.isNotEmpty
                ? NetworkImage(user.photo!)
                : null,
            child: user.photo == null || user.photo!.isEmpty
                ? Text(
                    Helpers.getInitials(user.name),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 4),
              Text(
                user.district,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              if (user.isVerified)
                _HeaderPill(
                  icon: Icons.verified_rounded,
                  text: 'Verificado',
                ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewsScreen(
                        userId: user.id,
                        userName: user.name,
                        rating: user.rating,
                        totalReviews: user.totalReviews,
                      ),
                    ),
                  );
                },
                child: _HeaderPill(
                  icon: Icons.star_rounded,
                  text:
                      '${user.rating.toStringAsFixed(1)} · ${user.totalReviews} reseñas',
                ),
              ),
              _HeaderPill(
                icon: Icons.work_history_outlined,
                text: '${user.completedJobs} trabajos',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(dynamic user, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            isDark: isDark,
            icon: Icons.star_rounded,
            color: Colors.amber,
            title: 'Rating',
            value: user.rating.toStringAsFixed(1),
            subtitle: '${user.totalReviews} reseñas',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            isDark: isDark,
            icon: Icons.check_circle_outline_rounded,
            color: Colors.green,
            title: 'Completados',
            value: '${user.completedJobs}',
            subtitle: 'Trabajos hechos',
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsCard(dynamic user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success,
            AppColors.success.withOpacity(0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _MiniIconBubble(
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.white,
                backgroundOpacity: 0.18,
              ),
              SizedBox(width: 12),
              Text(
                'Ganancias',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _EarningBlock(
                  label: 'Este mes',
                  value: Helpers.formatCurrency(user.monthlyEarnings),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _EarningBlock(
                  label: 'Total',
                  value: Helpers.formatCurrency(user.totalEarnings),
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(dynamic user, bool isDark) {
    return _ProfileCard(
      isDark: isDark,
      title: 'Sobre mí',
      icon: Icons.description_outlined,
      iconColor: AppColors.primary,
      child: Text(
        (user.description == null || user.description.toString().trim().isEmpty)
            ? 'Aún no agregaste una descripción.'
            : user.description,
        style: TextStyle(
          fontSize: 14.5,
          height: 1.6,
          color: isDark ? Colors.white70 : const Color(0xFF536171),
        ),
      ),
    );
  }

  Widget _buildSkillsCard(dynamic user, bool isDark) {
    final skills = (user.skills as List).cast<String>();

    return _ProfileCard(
      isDark: isDark,
      title: 'Habilidades',
      icon: Icons.star_outline_rounded,
      iconColor: Colors.orange,
      child: skills.isEmpty
          ? Text(
              'No agregaste habilidades todavía.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : const Color(0xFF708090),
              ),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildAvailabilityCard(dynamic user, bool isDark) {
    return _ProfileCard(
      isDark: isDark,
      title: 'Disponibilidad',
      icon: Icons.calendar_today_outlined,
      iconColor: Colors.purple,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: Colors.purple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.availability,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF162033),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    bool isDark, {
    required String title,
    required List<_MenuItemData> items,
  }) {
    return _ProfileCard(
      isDark: isDark,
      title: title,
      icon: Icons.grid_view_rounded,
      iconColor: AppColors.primary,
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              _PremiumMenuTile(
                icon: item.icon,
                title: item.title,
                onTap: item.onTap,
                trailing: item.trailing,
              ),
              if (index != items.length - 1)
                Divider(
                  height: 18,
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFE8EEF6),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EEF6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cerrar Sesión'),
                content: const Text(
                  '¿Estás seguro que deseas cerrar sesión?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Cerrar Sesión'),
                  ),
                ],
              ),
            );

            if (shouldLogout == true && context.mounted) {
              await context.read<UserService>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            }
          },
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _MiniIconBubble(
                  icon: Icons.logout_rounded,
                  color: Colors.red,
                  backgroundColor: Color(0xFFFFF1F1),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _ProfileCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EEF6),
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
          Row(
            children: [
              _MiniIconBubble(
                icon: icon,
                color: iconColor,
                backgroundColor: iconColor.withOpacity(0.10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          width: 42,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIconBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final double backgroundOpacity;

  const _MiniIconBubble({
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.backgroundOpacity = 0.10,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withOpacity(backgroundOpacity);

    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _StatCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE8EEF6),
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
          _MiniIconBubble(
            icon: icon,
            color: color,
            backgroundColor: color.withOpacity(0.10),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white60 : const Color(0xFF708090),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF162033),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : const Color(0xFF5B6878),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _EarningBlock({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        const Text(
          ' ',
          style: TextStyle(fontSize: 0),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _PremiumMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const _PremiumMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              _MiniIconBubble(
                icon: icon,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF162033),
                  ),
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white54 : const Color(0xFF8190A5),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });
}