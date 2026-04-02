import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'create_group_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();
  final _authService = AuthService();
  List<UserModel> _users = [];
  List<dynamic> _groups = [];
  bool _loading = true;
  String? _currentUserId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() async {
    _currentUserId = await _authService.getUserId();
    final users = await _apiService.getUsers();
    final groups = await _apiService.getGroups();
    setState(() {
      _users = users.map((u) => UserModel.fromJson(u)).toList();
      _groups = groups;
      _loading = false;
    });
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Chat App', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C63FF),
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
          );
          if (result == true) _loadData();
        },
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : TabBarView(
        controller: _tabController,
        children: [
          // Chats Tab
          _users.isEmpty
              ? const Center(child: Text('No users found', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6C63FF),
                  child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                title: Text(user.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  user.status,
                  style: TextStyle(color: user.status == 'online' ? Colors.green : Colors.grey),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      receiverId: user.id,
                      receiverName: user.name,
                      currentUserId: _currentUserId ?? '',
                    ),
                  ),
                ),
              );
            },
          ),
          // Groups Tab
          _groups.isEmpty
              ? const Center(child: Text('No groups yet', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
            itemCount: _groups.length,
            itemBuilder: (context, index) {
              final group = _groups[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6C63FF),
                  child: Text(group['name'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                title: Text(group['name'], style: const TextStyle(color: Colors.white)),
                subtitle: Text('${group['members'].length} members', style: const TextStyle(color: Colors.grey)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupChatScreen(
                      groupId: group['_id'],
                      groupName: group['name'],
                      currentUserId: _currentUserId ?? '',
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}