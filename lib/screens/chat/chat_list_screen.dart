import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/job_service.dart';
import '../../core/services/message_service.dart';
import '../../core/services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final currentUser = context.read<UserService>().currentUser;
    if (currentUser != null) {
      await context.read<MessageService>().loadAllConversations(currentUser.id);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageService = context.watch<MessageService>();
    final currentUser = context.watch<UserService>().currentUser;
    final conversations = messageService.conversations;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: Column(
        children: [
          _buildHeader(context, currentUser),
          Expanded(
            child: currentUser == null
                ? _buildLoginRequired(isDark)
                : conversations.isEmpty && !_isLoading
                    ? RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            const SizedBox(height: 80),
                            _EmptyChatState(isDark: isDark),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadConversations,
                        child: _isLoading && conversations.isEmpty
                            ? ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  24,
                                ),
                                children: const [
                                  _ChatSkeletonCard(),
                                  SizedBox(height: 12),
                                  _ChatSkeletonCard(),
                                  SizedBox(height: 12),
                                  _ChatSkeletonCard(),
                                ],
                              )
                            : ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  24,
                                ),
                                children: [
                                  if (_buildFilteredKeys(
                                    conversations,
                                  ).isEmpty) ...[
                                    const SizedBox(height: 60),
                                    _NoSearchResultsState(
                                      query: _searchQuery,
                                      isDark: isDark,
                                    ),
                                  ] else
                                    ..._buildFilteredKeys(conversations).map(
                                      (jobId) {
                                        final messages = conversations[jobId]!;
                                        final lastMessage = messages.last;

                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: FutureBuilder(
                                            future: context
                                                .read<JobService>()
                                                .getJobById(jobId),
                                            builder: (context,
                                                AsyncSnapshot<dynamic>
                                                    jobSnapshot) {
                                              if (!jobSnapshot.hasData) {
                                                return const _ChatSkeletonCard();
                                              }

                                              final job = jobSnapshot.data;
                                              if (job == null) {
                                                return const SizedBox.shrink();
                                              }

                                              String otherUserId;
                                              if (job.acceptedBy != null &&
                                                  job.acceptedBy!
                                                      .isNotEmpty) {
                                                if (job.createdBy ==
                                                    currentUser.id) {
                                                  otherUserId = job.acceptedBy!;
                                                } else {
                                                  otherUserId = job.createdBy;
                                                }
                                              } else {
                                                final otherMessage =
                                                    messages.firstWhere(
                                                  (msg) =>
                                                      msg.senderId !=
                                                      currentUser.id,
                                                  orElse: () => messages.first,
                                                );
                                                otherUserId =
                                                    otherMessage.senderId ==
                                                            currentUser.id
                                                        ? (otherMessage
                                                                .receiverId ??
                                                            job.createdBy)
                                                        : otherMessage.senderId;
                                              }

                                              return FutureBuilder(
                                                future: context
                                                    .read<UserService>()
                                                    .getUserById(otherUserId),
                                                builder: (context,
                                                    AsyncSnapshot<dynamic>
                                                        userSnapshot) {
                                                  if (!userSnapshot.hasData) {
                                                    return const _ChatSkeletonCard();
                                                  }

                                                  final otherUser =
                                                      userSnapshot.data;

                                                  final unreadCount = messages
                                                      .where((msg) =>
                                                          msg.receiverId ==
                                                              currentUser.id &&
                                                          !msg.isRead)
                                                      .length;

                                                  final otherName =
                                                      otherUser?.name ??
                                                          'Usuario';
                                                  final matchesSearch =
                                                      _searchQuery.isEmpty ||
                                                          otherName
                                                              .toLowerCase()
                                                              .contains(
                                                                  _searchQuery) ||
                                                          job.title
                                                              .toLowerCase()
                                                              .contains(
                                                                  _searchQuery);

                                                  if (!matchesSearch) {
                                                    return const SizedBox
                                                        .shrink();
                                                  }

                                                  return _PremiumConversationCard(
                                                    otherUser: otherUser,
                                                    otherUserId: otherUserId,
                                                    jobId: jobId,
                                                    jobTitle: job.title,
                                                    lastMessage:
                                                        lastMessage.text
                                                                .trim()
                                                                .isNotEmpty
                                                            ? lastMessage.text
                                                            : '📷 Imagen',
                                                    messageTime:
                                                        lastMessage.createdAt,
                                                    unreadCount: unreadCount,
                                                    onTap: () async {
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              ChatScreen(
                                                            jobId: jobId,
                                                            otherUserId:
                                                                otherUserId,
                                                          ),
                                                        ),
                                                      );
                                                      _loadConversations();
                                                    },
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  List<String> _buildFilteredKeys(Map<String, dynamic> conversations) {
    return conversations.keys.toList();
  }

  Widget _buildHeader(BuildContext context, dynamic currentUser) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 54, 16, 22),
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
            color: AppColors.primary.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mensajes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tus conversaciones activas',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (currentUser != null)
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.18),
                  backgroundImage:
                      currentUser.photo != null &&
                              currentUser.photo!.isNotEmpty
                          ? NetworkImage(currentUser.photo!)
                          : null,
                  child:
                      currentUser.photo == null ||
                              currentUser.photo!.isEmpty
                          ? Text(
                              Helpers.getInitials(currentUser.name),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            )
                          : null,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Buscar conversación o trabajo...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1E22) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 54,
                color: AppColors.grey,
              ),
              SizedBox(height: 14),
              Text(
                'Inicia sesión para ver tus mensajes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumConversationCard extends StatelessWidget {
  final dynamic otherUser;
  final String otherUserId;
  final String jobId;
  final String jobTitle;
  final String lastMessage;
  final DateTime messageTime;
  final int unreadCount;
  final VoidCallback onTap;

  const _PremiumConversationCard({
    required this.otherUser,
    required this.otherUserId,
    required this.jobId,
    required this.jobTitle,
    required this.lastMessage,
    required this.messageTime,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnread = unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1E22) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasUnread
                  ? AppColors.primary.withOpacity(0.18)
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFE8EEF6)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      backgroundImage:
                          otherUser?.photo != null &&
                                  otherUser!.photo!.isNotEmpty
                              ? NetworkImage(otherUser.photo!)
                              : null,
                      child:
                          otherUser?.photo == null ||
                                  otherUser!.photo!.isEmpty
                              ? Text(
                                  Helpers.getInitials(
                                    otherUser?.name ?? 'Usuario',
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                )
                              : null,
                    ),
                    if (hasUnread)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        otherUser?.name ?? 'Usuario',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.8,
                          fontWeight:
                              hasUnread ? FontWeight.w800 : FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF162033),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jobTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: hasUnread
                              ? (isDark ? Colors.white70 : Colors.black87)
                              : Colors.grey[600],
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Helpers.getTimeAgo(messageTime),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: hasUnread
                            ? AppColors.primary
                            : Colors.grey[500],
                        fontWeight:
                            hasUnread ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey[500],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final bool isDark;

  const _EmptyChatState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1E22) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 72,
              color: AppColors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No tienes conversaciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: AppColors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cuando hables con alguien sobre un trabajo,\naquí aparecerán tus chats.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResultsState extends StatelessWidget {
  final String query;
  final bool isDark;

  const _NoSearchResultsState({
    required this.query,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1E22) : Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 66,
              color: AppColors.grey,
            ),
            const SizedBox(height: 14),
            const Text(
              'No encontramos resultados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: AppColors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay conversaciones que coincidan con "$query".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatSkeletonCard extends StatelessWidget {
  const _ChatSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: base,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 11,
                  width: 180,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
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