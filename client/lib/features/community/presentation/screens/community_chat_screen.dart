import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../router/route_names.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/language_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/state/auth_state.dart';
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

      // 1. Fetch rooms
      final roomsResponse = await CommunityApi().dio.get(
            '${AppConstants.communityEndpoint}/${widget.communityId}/rooms',
          );
      final roomsData = roomsResponse.data['data'] as List;
      
      if (roomsData.isEmpty) {
        throw Exception("No chat rooms found for this community");
      }
      
      _roomId = roomsData.first['id'] as String;
      
      // 2. Fetch historical messages
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

      // 3. Setup Socket
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
        debugPrint('Chat: No JWT token found in secure storage');
        if (mounted) {
          setState(() {
            _error = "Authentication failed. Please login again.";
          });
        }
        return;
      }

      final socketUrl = AppConstants.baseUrl.replaceAll('/api/v1', '');
      debugPrint('Chat: Connecting to socket at $socketUrl with JWT');
      
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'forceNew': true, // Correct way to force fresh connection
        'auth': {'token': token},
      });

      _socket.onConnect((_) {
        debugPrint('Chat: Socket connected: ${_socket.id}');
        if (mounted) setState(() => _connectionStatus = 'connected');
        if (_roomId != null) {
          debugPrint('Chat: Joining room $_roomId');
          _socket.emit('join_room', {
            'roomId': _roomId,
            'communityId': widget.communityId,
          });
        }
      });

      _socket.onConnectError((data) {
        debugPrint('Chat: Socket connection error: $data');
        if (mounted) setState(() => _connectionStatus = 'disconnected');
      });

      _socket.onReconnect((_) {
        debugPrint('Chat: Socket reconnected');
        if (mounted) setState(() => _connectionStatus = 'connected');
        if (_roomId != null) {
          _socket.emit('join_room', {
            'roomId': _roomId,
            'communityId': widget.communityId,
          });
        }
      });

      _socket.onDisconnect((_) {
        debugPrint('Chat: Socket disconnected');
        if (mounted) setState(() => _connectionStatus = 'disconnected');
      });

      _socket.on('new_message', (data) {
        debugPrint('Chat: Received new_message event');
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

      _socket.on('error', (err) {
        debugPrint('Chat: Socket error event: $err');
      });

      _socket.connect();
    } catch (e) {
      debugPrint('Chat: _setupSocket exception: $e');
    }
  }

  void _retryConnection() {
    debugPrint('Chat: Manual retry requested');
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
          content: Text('Not connected to chat server / सर्वर से कनेक्ट नहीं है'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    debugPrint('Chat: Sending message content: "$text"');

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.communityName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _connectionStatus == 'connected' 
                        ? Colors.greenAccent 
                        : _connectionStatus == 'connecting' 
                            ? Colors.orangeAccent 
                            : Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _connectionStatus == 'connected' 
                      ? (isHindi ? 'ऑनलाइन' : 'Online')
                      : _connectionStatus == 'connecting'
                          ? (isHindi ? 'कनेक्ट हो रहा है...' : 'Connecting...')
                          : (isHindi ? 'डिस्कनेक्टेड' : 'Disconnected'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_connectionStatus != 'connected')
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _retryConnection,
              tooltip: isHindi ? 'पुनः प्रयास करें' : 'Retry',
            ),
          const SizedBox(width: 8),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(RouteNames.home);
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Latest messages at bottom
                        padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, Map<String, dynamic> sender, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                sender['name']?.toString() ?? 'User',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              msg['content']?.toString() ?? '',
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isHindi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: isHindi ? 'संदेश लिखें...' : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
