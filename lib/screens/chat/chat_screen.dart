import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/message_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/cloudinary_service.dart';
import '../../core/services/message_service.dart';
import '../../core/services/user_service.dart';
import '../../data/firebase/firebase_message_repository.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../profile/user_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String jobId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.jobId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedImagePath;
  bool _isTyping = false;
  bool _isSending = false;
  UserModel? _otherUser;
  List<MessageModel>? _cachedMessages;

  @override
  void initState() {
    super.initState();
    _initialize();

    _messageController.addListener(() {
      final isTypingNow = _messageController.text.trim().isNotEmpty;
      if (isTypingNow != _isTyping) {
        setState(() => _isTyping = isTypingNow);
      }
    });
  }

  Future<void> _initialize() async {
    _loadOtherUser();
    _loadInitialMessages();
    _markAsReadDelayed();
  }

  Future<void> _loadInitialMessages() async {
    final messageRepo = FirebaseMessageRepository();

    try {
      final messages = await messageRepo.getMessages(widget.jobId);
      if (mounted) {
        setState(() => _cachedMessages = messages);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _cachedMessages = []);
      }
    }
  }

  Future<void> _loadOtherUser() async {
    try {
      final userService = context.read<UserService>();
      final user = await userService.getUserById(widget.otherUserId);
      if (mounted) {
        setState(() => _otherUser = user);
      }
    } catch (_) {}
  }

  void _markAsReadDelayed() {
    Future.delayed(const Duration(milliseconds: 500), () {
      final currentUser = context.read<UserService>().currentUser;
      if (currentUser != null && mounted) {
        final repo = context.read<MessageService>().repository;
        if (repo is FirebaseMessageRepository) {
          repo.markMessagesAsRead(widget.jobId, currentUser.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      setState(() => _selectedImagePath = image.path);
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    if (_messageController.text.trim().isEmpty && _selectedImagePath == null) {
      return;
    }

    final currentUser = context.read<UserService>().currentUser;
    if (currentUser == null) return;

    setState(() => _isSending = true);

    try {
      String? imageUrl;

      if (_selectedImagePath != null) {
        imageUrl = await CloudinaryService.uploadImage(
          imagePath: _selectedImagePath!,
          folder: 'laboraya/messages',
        );
      }

      final message = MessageModel(
        id: const Uuid().v4(),
        jobId: widget.jobId,
        senderId: currentUser.id,
        receiverId: widget.otherUserId,
        text: _messageController.text.trim(),
        image: imageUrl,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await context.read<MessageService>().sendMessage(message);

      _messageController.clear();
      setState(() {
        _selectedImagePath = null;
        _isTyping = false;
      });

      await Future.delayed(const Duration(milliseconds: 120));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar mensaje'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede realizar la llamada'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al llamar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCallDialog() {
    if (_otherUser == null || _otherUser!.phone.isEmpty) return;
    _makePhoneCall(_otherUser!.phone);
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Row(
          children: const [
            Icon(Icons.block_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Bloquear usuario'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Bloquear a ${_otherUser?.name}?'),
            const SizedBox(height: 12),
            const Text(
              'Esta persona no podrá:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text('• Enviarte mensajes'),
            const Text('• Ver tus trabajos publicados'),
            const Text('• Aplicar a tus trabajos'),
            const SizedBox(height: 12),
            const Text(
              'Podrás desbloquearlo desde Configuración > Usuarios bloqueados',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final currentUser = context.read<UserService>().currentUser;
              if (currentUser == null || _otherUser == null) return;

              try {
                await FirebaseFirestore.instance.collection('blocked_users').add({
                  'blockerId': currentUser.id,
                  'blockedUserId': _otherUser!.id,
                  'blockedAt': Timestamp.now(),
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_otherUser!.name} ha sido bloqueado'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al bloquear: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Row(
          children: const [
            Icon(Icons.flag_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reportar usuario'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Reportar a ${_otherUser?.name}?'),
            const SizedBox(height: 12),
            const Text(
              'Nuestro equipo revisará este reporte.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reporte enviado. Gracias por tu colaboración.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserService>().currentUser;
    final messageRepo =
        context.read<MessageService>().repository as FirebaseMessageRepository;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      body: Column(
        children: [
          _ChatHeader(
            otherUser: _otherUser,
            onBack: () => Navigator.pop(context),
            onOpenProfile: () {
              if (_otherUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(user: _otherUser!),
                  ),
                );
              }
            },
            onCall: _otherUser != null ? _showCallDialog : null,
            onBlock: _otherUser != null ? _showBlockDialog : null,
            onReport: _otherUser != null ? _showReportDialog : null,
          ),
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: messageRepo.getMessagesStream(widget.jobId),
              initialData: _cachedMessages,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final messages = snapshot.data!;

                  if (messages.isEmpty) {
                    return _EmptyChatState(isDark: isDark);
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                    itemCount: messages.length,
                    cacheExtent: 600,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isMe = message.senderId == currentUser?.id;

                      return _MessageBubble(
                        key: ValueKey(message.id),
                        message: message,
                        isMe: isMe,
                      );
                    },
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 14),
                        const Text('Error al cargar mensajes'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
          if (_selectedImagePath != null)
            _SelectedImagePreview(
              imagePath: _selectedImagePath!,
              onRemove: () {
                setState(() => _selectedImagePath = null);
              },
            ),
          _ChatInputBar(
            controller: _messageController,
            isTyping: _isTyping,
            isSending: _isSending,
            hasImage: _selectedImagePath != null,
            onPickImage: _pickImage,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final UserModel? otherUser;
  final VoidCallback onBack;
  final VoidCallback onOpenProfile;
  final VoidCallback? onCall;
  final VoidCallback? onBlock;
  final VoidCallback? onReport;

  const _ChatHeader({
    required this.otherUser,
    required this.onBack,
    required this.onOpenProfile,
    required this.onCall,
    required this.onBlock,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 52, 14, 18),
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
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: otherUser != null ? onOpenProfile : null,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    backgroundImage:
                        otherUser?.photo != null && otherUser!.photo!.isNotEmpty
                            ? NetworkImage(otherUser!.photo!)
                            : null,
                    child: (otherUser?.photo == null ||
                            otherUser!.photo!.isEmpty)
                        ? Text(
                            otherUser != null
                                ? Helpers.getInitials(otherUser!.name)
                                : '...',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: otherUser == null
                        ? const Text(
                            'Cargando...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                otherUser!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 13,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${otherUser!.rating.toStringAsFixed(1)} • ${otherUser!.completedJobs} trabajos',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (onCall != null)
            _GlassIconButton(
              icon: Icons.phone_rounded,
              onTap: onCall!,
            ),
          if (onBlock != null && onReport != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                if (value == 'block') {
                  onBlock!();
                } else if (value == 'report') {
                  onReport!();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block_rounded, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Text('Bloquear usuario'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_rounded, color: Colors.orange, size: 20),
                      SizedBox(width: 10),
                      Text('Reportar'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
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
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  final bool isDark;

  const _EmptyChatState({
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1E22) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFE8EEF6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.14),
                    AppColors.primary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No hay mensajes aún',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF162033),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Empieza la conversación y coordina los detalles del trabajo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.5,
                color: isDark ? Colors.white70 : const Color(0xFF5D6A79),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRemove;

  const _SelectedImagePreview({
    required this.imagePath,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(imagePath),
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Imagen lista para enviar',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF162033),
              ),
            ),
          ),
          Material(
            color: Colors.red.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onRemove,
              child: const SizedBox(
                height: 40,
                width: 40,
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final bool isSending;
  final bool hasImage;
  final VoidCallback onPickImage;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.isTyping,
    required this.isSending,
    required this.hasImage,
    required this.onPickImage,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111315) : const Color(0xFFF6F8FC),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Material(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onPickImage,
                  child: const SizedBox(
                    height: 42,
                    width: 42,
                    child: Icon(
                      Icons.image_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: 5,
                  minLines: 1,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  gradient: (isTyping || hasImage)
                      ? const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                        )
                      : null,
                  color: (isTyping || hasImage)
                      ? null
                      : Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: (isTyping || hasImage)
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.24),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: isSending ? null : onSend,
                    child: SizedBox(
                      height: 46,
                      width: 46,
                      child: Center(
                        child: isSending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: (isTyping || hasImage)
                                    ? Colors.white
                                    : Colors.grey[700],
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: EdgeInsets.all(
                (message.image != null && message.image!.isNotEmpty) ? 8 : 14,
              ),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe
                    ? null
                    : (isDark ? const Color(0xFF1B1E22) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.16 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.image != null && message.image!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: message.image!.startsWith('http')
                          ? Image.network(
                              message.image!,
                              width: 220,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  width: 220,
                                  height: 150,
                                  alignment: Alignment.center,
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 220,
                                  height: 150,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.error_outline_rounded,
                                  ),
                                );
                              },
                            )
                          : Image.file(
                              File(message.image!),
                              width: 220,
                              fit: BoxFit.cover,
                            ),
                    ),
                    if (message.text.isNotEmpty) const SizedBox(height: 10),
                  ],
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white
                            : (isDark ? Colors.white : const Color(0xFF162033)),
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                Helpers.formatTime(message.createdAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}