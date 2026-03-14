import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/message_service.dart';
import '../../core/services/user_service.dart';
import '../../core/services/job_service.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  Future<void> _loadConversations() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    final currentUser = context.read<UserService>().currentUser;
    if (currentUser != null) {
      print('🔄 Cargando conversaciones para: ${currentUser.id}');
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

    print('📱 Conversaciones en pantalla: ${conversations.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
      ),
      body: currentUser == null
          ? const Center(child: Text('Inicia sesión para ver tus mensajes'))
          : conversations.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: AppColors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No tienes conversaciones',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final jobId = conversations.keys.elementAt(index);
                      final messages = conversations[jobId]!;
                      final lastMessage = messages.last;

                      return FutureBuilder(
                        future: context.read<JobService>().getJobById(jobId),
                        builder: (context, AsyncSnapshot<dynamic> jobSnapshot) {
                          if (!jobSnapshot.hasData) {
                            return const ListTile(
                              leading: CircleAvatar(
                                child: CircularProgressIndicator(),
                              ),
                              title: Text('Cargando...'),
                            );
                          }

                          final job = jobSnapshot.data;
                          if (job == null) return const SizedBox.shrink();

                          // Determinar el otro usuario de forma más robusta
                          // Primero intentar usar acceptedBy si existe
                          String otherUserId;
                          if (job.acceptedBy != null && job.acceptedBy!.isNotEmpty) {
                            // Si hay un trabajador aceptado
                            if (job.createdBy == currentUser.id) {
                              // El usuario actual es el creador, el otro es el trabajador
                              otherUserId = job.acceptedBy!;
                            } else {
                              // El usuario actual es el trabajador, el otro es el creador
                              otherUserId = job.createdBy;
                            }
                          } else {
                            // Si no hay trabajador aceptado, buscar en los mensajes
                            final otherMessage = messages.firstWhere(
                              (msg) => msg.senderId != currentUser.id,
                              orElse: () => messages.first,
                            );
                            otherUserId = otherMessage.senderId == currentUser.id 
                                ? (otherMessage.receiverId ?? job.createdBy)
                                : otherMessage.senderId;
                          }

                          print('💬 Conversación $jobId: otro usuario = $otherUserId');

                          return FutureBuilder(
                            future: context.read<UserService>().getUserById(otherUserId),
                            builder: (context, AsyncSnapshot<dynamic> userSnapshot) {
                              if (!userSnapshot.hasData) {
                                return const ListTile(
                                  leading: CircleAvatar(
                                    child: CircularProgressIndicator(),
                                  ),
                                  title: Text('Cargando...'),
                                );
                              }

                              final otherUser = userSnapshot.data;

                              // Contar mensajes no leídos en esta conversación
                              final unreadCount = messages.where((msg) => 
                                msg.receiverId == currentUser.id && !msg.isRead
                              ).length;

                              return ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primary,
                                      backgroundImage: otherUser?.photo != null
                                          ? NetworkImage(otherUser!.photo!)
                                          : null,
                                      child: otherUser?.photo == null
                                          ? Text(
                                              otherUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                                              style: const TextStyle(color: AppColors.white),
                                            )
                                          : null,
                                    ),
                                    // Badge de mensajes no leídos
                                    if (unreadCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 20,
                                            minHeight: 20,
                                          ),
                                          child: Text(
                                            unreadCount > 99 ? '99+' : '$unreadCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  otherUser?.name ?? 'Usuario',
                                  style: TextStyle(
                                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job.title,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      lastMessage.text.isNotEmpty 
                                          ? lastMessage.text 
                                          : '📷 Imagen',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      Helpers.getTimeAgo(lastMessage.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        jobId: jobId,
                                        otherUserId: otherUserId,
                                      ),
                                    ),
                                  );
                                  // Recargar conversaciones después de volver del chat
                                  _loadConversations();
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
