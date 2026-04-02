import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _apiService = ApiService();
  List<UserModel> _users = [];
  List<String> _selectedUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    final users = await _apiService.getUsers();
    setState(() {
      _users = users.map((u) => UserModel.fromJson(u)).toList();
      _loading = false;
    });
  }

  void _createGroup() async {
    if (_nameController.text.trim().isEmpty) return;
    final result = await _apiService.createGroup(
      _nameController.text.trim(),
      _selectedUsers,
    );
    if (result['_id'] != null && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Create Group', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: const Text('Create', style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Group Name',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Select Members', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final selected = _selectedUsers.contains(user.id);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedUsers.add(user.id);
                        } else {
                          _selectedUsers.remove(user.id);
                        }
                      });
                    },
                    title: Text(user.name, style: const TextStyle(color: Colors.white)),
                    activeColor: const Color(0xFF6C63FF),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}