import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../core/models/message_model.dart';
import '../../core/models/user_model.dart';
import '../../core/services/message_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/cloudinary_service.dart';
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
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedImagePath;
  bool _isTyping = false;
  bool _isSending = false;
  UserModel? _otherUser;
  List<MessageModel>? _cachedMessages;

  @override
  void initState() {
    super.initState();
    _initialize();
    
    // Detectar cuando el usuario está escribiendo
    _messageController.addListener(() {
      final isTyping = _messageController.text.isNotEmpty;
      if (isTyping != _isTyping) {
        setState(() => _isTyping = isTyping);
      }
    });
  }

  Future<void> _initialize() async {
    // Cargar todo en paralelo sin bloquear la UI
    _loadOtherUser();
    _loadInitialMessages();
    _markAsReadDelayed();
  }

  Future<void> _loadInitialMessages() async {
    final messageRepo = FirebaseMessageRepository();
    try {
      print('⏳ Cargando mensajes iniciales...');
      final startTime = DateTime.now();
      
      final messages = await messageRepo.getMessages(widget.jobId);
      
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      print('✅ Mensajes cargados en ${loadTime}ms: ${messages.length} mensajes');
      
      if (mounted) {
        setState(() {
          _cachedMessages = messages;
        });
      }
    } catch (e) {
      print('❌ Error cargando mensajes iniciales: $e');
      if (mounted) {
        setState(() {
          _cachedMessages = [];
        });
      }
    }
  }

  Future<void> _loadOtherUser() async {
    try {
      final userService = context.read<UserService>();
      final user = await userService.getUserById(widget.otherUserId);
      if (mounted) {
        setState(() {
          _otherUser = user;
        });
      }
    } catch (e) {
      print('❌ Error cargando usuario: $e');
    }
  }

  void _markAsReadDelayed() {
    // Marcar como leídos después de un pequeño delay para asegurar que los mensajes se cargaron
    Future.delayed(const Duration(milliseconds: 500), () {
      final currentUser = context.read<UserService>().currentUser;
      if (currentUser != null && mounted) {
        final messageRepo = context.read<MessageService>().repository;
        if (messageRepo is FirebaseMessageRepository) {
          messageRepo.markMessagesAsRead(widget.jobId, currentUser.id);
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
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  Future<void> _sendMessage() async {
    // Prevenir envíos múltiples
    if (_isSending) return;
    
    if (_messageController.text.trim().isEmpty && _selectedImagePath == null) {
      return;
    }

    setState(() => _isSending = true);

    final currentUser = context.read<UserService>().currentUser;
    if (currentUser == null) {
      setState(() => _isSending = false);
      return;
    }

    try {
      // Subir imagen a Cloudinary si existe
      String? imageUrl;
      if (_selectedImagePath != null) {
        print('📤 Subiendo imagen del chat a Cloudinary...');
        imageUrl = await CloudinaryService.uploadImage(
          imagePath: _selectedImagePath!,
          folder: 'laboraya/messages',
        );
        print('✅ Imagen subida: $imageUrl');
      }

      final message = MessageModel(
        id: const Uuid().v4(),
        jobId: widget.jobId,
        senderId: currentUser.id,
        receiverId: widget.otherUserId, // ID del receptor
        text: _messageController.text.trim(),
        image: imageUrl, // URL de Cloudinary
        createdAt: DateTime.now(),
        isRead: false, // Mensaje no leído inicialmente
      );

      await context.read<MessageService>().sendMessage(message);
      _messageController.clear();
      setState(() => _selectedImagePath = null);

      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      print('Error enviando mensaje: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // Limpiar el número de teléfono
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
    _makePhoneCall(_otherUser!.phone);
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.block, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Bloquear usuario'),
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
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_otherUser?.name} ha sido bloqueado'),
                  backgroundColor: Colors.orange,
                  action: SnackBarAction(
                    label: 'Deshacer',
                    textColor: Colors.white,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bloqueo cancelado'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              );
              // Aquí se implementaría el bloqueo real en Firebase
              // await _blockUser(_otherUser!.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        title: Row(
          children: [
            const Icon(Icons.flag, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Reportar usuario'),
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
              // Aquí se implementaría el reporte real
              // Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(...)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserService>().currentUser;
    final messageRepo = context.read<MessageService>().repository as FirebaseMessageRepository;

    return Scaffold(
      appBar: AppBar(
        title: _otherUser != null
            ? GestureDetector(
                onTap: () {
                  if (_otherUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(user: _otherUser!),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      backgroundImage: _otherUser?.photo != null
                          ? NetworkImage(_otherUser!.photo!)
                          : null,
                      child: _otherUser?.photo == null && _otherUser != null
                          ? Text(
                              Helpers.getInitials(_otherUser!.name),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _otherUser?.name ?? 'Cargando...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_otherUser != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: AppColors.urgent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_otherUser!.rating.toStringAsFixed(1)} • ${_otherUser!.completedJobs} trabajos',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : const Text('Chat'),
        actions: [
          if (_otherUser != null)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: _showCallDialog,
              tooltip: 'Llamar',
            ),
          if (_otherUser != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'block') {
                  _showBlockDialog();
                } else if (value == 'report') {
                  _showReportDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Bloquear usuario'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: Colors.orange, size: 20),
                      SizedBox(width: 12),
                      Text('Reportar'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: messageRepo.getMessagesStream(widget.jobId),
              initialData: _cachedMessages, // Usar mensajes cargados como datos iniciales
              builder: (context, snapshot) {
                // Si tenemos datos (de caché o stream), mostrarlos inmediatamente
                if (snapshot.hasData) {
                  final messages = snapshot.data!;
                  
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay mensajes aún',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¡Envía el primer mensaje!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(AppSizes.paddingMedium),
                    itemCount: messages.length,
                    cacheExtent: 500,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isMe = message.senderId == currentUser?.id;

                      return _MessageBubble(
                        message: message,
                        isMe: isMe,
                        key: ValueKey(message.id),
                      );
                    },
                  );
                }

                // Solo mostrar loading si NO tenemos datos en absoluto
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando mensajes...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  print('❌ Error cargando mensajes: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Error al cargar mensajes'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                // Fallback
                return const SizedBox.shrink();
              },
            ),
          ),
          // Preview de imagen seleccionada
          if (_selectedImagePath != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[200],
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_selectedImagePath!),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Imagen seleccionada'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() => _selectedImagePath = null);
                    },
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: _pickImage,
                    color: AppColors.primary,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[500]
                              : Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.borderRadius),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _isTyping || _selectedImagePath != null
                          ? Icons.send
                          : Icons.send_outlined,
                    ),
                    onPressed: _isSending ? null : _sendMessage, // Deshabilitar si está enviando
                    color: _isSending ? AppColors.grey : AppColors.primary,
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

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({
    super.key, // Agregado key
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe 
              ? AppColors.primary 
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar imagen si existe
            if (message.image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: message.image!.startsWith('http')
                    ? Image.network(
                        message.image!,
                        width: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 150,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 150,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      )
                    : Image.file(
                        File(message.image!),
                        width: 200,
                        fit: BoxFit.cover,
                      ),
              ),
              if (message.text.isNotEmpty) const SizedBox(height: 8),
            ],
            // Mostrar texto si existe
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(
                  color: isMe 
                      ? AppColors.white 
                      : (isDark ? Colors.white : AppColors.black),
                  fontSize: 15,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              Helpers.formatTime(message.createdAt),
              style: TextStyle(
                color: isMe
                    ? AppColors.white.withOpacity(0.7)
                    : AppColors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
