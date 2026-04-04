import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import 'call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _apiService = ApiService();
  final _socketService = SocketService();
  List<MessageModel> _messages = [];
  bool _loading = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSocket();
  }

  void _loadMessages() async {
    final messages = await _apiService.getMessages(widget.receiverId);
    setState(() {
      _messages = messages.map((m) => MessageModel.fromJson(m)).toList();
      _loading = false;
    });
    _scrollToBottom();
  }

  void _setupSocket() {
    _socketService.onReceiveMessage((data) {
      final message = MessageModel.fromJson(data);
      if ((message.sender == widget.receiverId && message.receiver == widget.currentUserId) ||
          (message.sender == widget.currentUserId && message.receiver == widget.receiverId)) {
        setState(() => _messages.add(message));
        _scrollToBottom();
      }
    });

    _socketService.onTypingStart((data) {
      if (data['senderId'] == widget.receiverId) {
        setState(() => _isTyping = true);
      }
    });

    _socketService.onTypingStop((data) {
      if (data['senderId'] == widget.receiverId) {
        setState(() => _isTyping = false);
      }
    });

    // Incoming call handler
    _socketService.socket?.on('call_offer', (data) {
      if (!mounted) return;
      _showIncomingCallDialog(data);
    });
  }

  void _showIncomingCallDialog(dynamic data) {
    final callType = data['callType'] ?? 'video';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(
          'Incoming ${callType == 'video' ? 'Video' : 'Audio'} Call',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          widget.receiverName,
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _socketService.socket?.emit('call_reject', {
                'callerId': data['callerId'],
                'callId': data['callId'],
              });
            },
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CallScreen(
                    targetId: data['callerId'],
                    targetName: widget.receiverName,
                    currentUserId: widget.currentUserId,
                    isCaller: false,
                    offer: data['offer'],
                    callType: callType,
                    callId: data['callId']?.toString(),
                  ),
                ),
              );
            },
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _startCall(String callType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          targetId: widget.receiverId,
          targetName: widget.receiverName,
          currentUserId: widget.currentUserId,
          isCaller: true,
          callType: callType,
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _socketService.sendMessage({
      'receiverId': widget.receiverId,
      'text': text,
    });

    _messageController.clear();
    _socketService.emitTypingStop(widget.receiverId);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socketService.removeListener('receive_message');
    _socketService.removeListener('typing_start');
    _socketService.removeListener('typing_stop');
    _socketService.removeListener('call_offer');
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName, style: const TextStyle(color: Colors.white, fontSize: 16)),
            if (_isTyping)
              const Text('typing...', style: TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () => _startCall('audio'),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () => _startCall('video'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.sender == widget.currentUserId;
                return _buildMessageBubble(message, isMe);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6C63FF) : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text ?? '', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(message.createdAt.toLocal()),
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF16213E),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (val) {
                if (val.isNotEmpty) {
                  _socketService.emitTypingStart(widget.receiverId);
                } else {
                  _socketService.emitTypingStop(widget.receiverId);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF6C63FF),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}