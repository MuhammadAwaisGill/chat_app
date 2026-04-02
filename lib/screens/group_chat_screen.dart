import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../models/message_model.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String currentUserId;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.currentUserId,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _apiService = ApiService();
  final _socketService = SocketService();
  List<MessageModel> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _socketService.joinRoom(widget.groupId);
    _loadMessages();
    _setupSocket();
  }

  void _loadMessages() async {
    final messages = await _apiService.getGroupMessages(widget.groupId);
    setState(() {
      _messages = messages.map((m) => MessageModel.fromJson(m)).toList();
      _loading = false;
    });
    _scrollToBottom();
  }

  void _setupSocket() {
    _socketService.onReceiveMessage((data) {
      final message = MessageModel.fromJson(data);
      if (message.group == widget.groupId) {
        setState(() => _messages.add(message));
        _scrollToBottom();
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _socketService.sendMessage({
      'groupId': widget.groupId,
      'text': text,
    });
    _messageController.clear();
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
        title: Text(widget.groupName, style: const TextStyle(color: Colors.white)),
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