import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/route_names.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/language_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
import '../../../../shared/widgets/shared_app_bar.dart';
import '../../data/api/community_api.dart';

class CommunityChatScreen extends ConsumerStatefulWidget {
  final String communityId;
  final String communityName;

  const CommunityChatScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  ConsumerState<CommunityChatScreen> createState() =>
      _CommunityChatScreenState();
}

class _CommunityChatScreenState extends ConsumerState<CommunityChatScreen> {
  late IO.Socket _socket;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  String? _roomId;
  List<Map<String, dynamic>> _messages = [];
  String? _error;
  String _connectionStatus = 'connecting'; // connecting, connected, disconnected

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final authState = ref.read(authControllerProvider);
      if (authState is! Authenticated) {
        throw Exception("Not authenticated");
      }

      final roomsResponse = await CommunityApi().dio.get(
            '${AppConstants.communityEndpoint}/${widget.communityId}/rooms',
          );
      final roomsData = roomsResponse.data['data'] as List;
      
      if (roomsData.isEmpty) {
        throw Exception("No chat rooms found for this community");
      }
      
      _roomId = roomsData.first['id'] as String;
      
      final msgResponse = await CommunityApi().dio.get(
            '${AppConstants.communityEndpoint}/rooms/$_roomId/messages',
          );
      final msgList = msgResponse.data['data'] as List;
      
      if (mounted) {
        setState(() {
          _messages = msgList.map((e) => Map<String, dynamic>.from(e as Map)).toList().reversed.toList();
        });
        _scrollToBottom();
      }

      _setupSocket();
      
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Chat: _initChat error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _setupSocket() async {
    try {
      final token = await SecureStorageService().getToken();
      if (token == null || token.isEmpty) {
        if (mounted) setState(() => _error = "Authentication failed. Please login again.");
        return;
      }

      final socketUrl = AppConstants.baseUrl.replaceAll('/api/v1', '');
      
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'forceNew': true,
        'auth': {'token': token},
      });

      _socket.onConnect((_) {
        if (mounted) setState(() => _connectionStatus = 'connected');
        if (_roomId != null) {
          _socket.emit('join_room', {
            'roomId': _roomId,
            'communityId': widget.communityId,
          });
        }
      });

      _socket.onConnectError((data) {
        if (mounted) setState(() => _connectionStatus = 'disconnected');
      });

      _socket.onReconnect((_) {
        if (mounted) setState(() => _connectionStatus = 'connected');
        if (_roomId != null) {
          _socket.emit('join_room', {
            'roomId': _roomId,
            'communityId': widget.communityId,
          });
        }
      });

      _socket.onDisconnect((_) {
        if (mounted) setState(() => _connectionStatus = 'disconnected');
      });

      _socket.on('new_message', (data) {
        if (!mounted || data == null) return;
        try {
          final Map<String, dynamic> messageData = Map<String, dynamic>.from(data as Map);
          setState(() {
            _messages.insert(0, messageData);
          });
          _scrollToBottom();
        } catch (e) {
          debugPrint('Chat: Error parsing new_message: $e');
        }
      });

      _socket.connect();
    } catch (e) {
      debugPrint('Chat: _setupSocket exception: $e');
    }
  }

  void _retryConnection() {
    setState(() {
      _connectionStatus = 'connecting';
      _error = null;
    });
    _socket.dispose();
    _setupSocket();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty || _roomId == null) return;

    if (_connectionStatus != 'connected') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected / कनेक्ट नहीं है'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _socket.emit('send_message', {
      'roomId': _roomId,
      'communityId': widget.communityId,
      'content': text,
    });

    _msgController.clear();
  }

  @override
  void dispose() {
    if (_roomId != null) {
      _socket.emit('leave_room', {'roomId': _roomId});
    }
    _socket.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currentUserId = authState is Authenticated ? authState.user.id : null;
    final isHindi = ref.watch(languageProvider) == 'hi';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F1),
      body: Column(
        children: [
          SharedHeader(
            title: widget.communityName,
            subtitle: _connectionStatus == 'connected'
                ? (isHindi ? 'ऑनलाइन' : 'Online')
                : (isHindi ? 'कनेक्ट हो रहा है...' : 'Connecting...'),
            paddingBottom: 16,
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildErrorPlaceholder()
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[index];
                                final sender = msg['sender'] as Map<String, dynamic>? ?? {};
                                final isMe = msg['senderId'] == currentUserId;
                                
                                return _buildMessageBubble(msg, sender, isMe);
                              },
                            ),
                          ),
                          _buildInputArea(isHindi),
                        ],
                      ),
          ),
        ],
      ),
    );
  }


  Widget _buildMessageBubble(Map<String, dynamic> msg, Map<String, dynamic> sender, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(20),
            bottomLeft: !isMe ? const Radius.circular(2) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                sender['name']?.toString() ?? 'User',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              msg['content']?.toString() ?? '',
              style: TextStyle(fontSize: 14, height: 1.4, color: isMe ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isHindi) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF1F3F1), borderRadius: BorderRadius.circular(28)),
              child: TextField(
                controller: _msgController,
                decoration: InputDecoration(
                  hintText: isHindi ? 'संदेश लिखें...' : 'Type a message...',
                  hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error ?? 'An error occurred', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
