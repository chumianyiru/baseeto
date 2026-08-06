import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/app_state.dart';
import '../models/contact.dart';

class AddContactScreen extends StatefulWidget {
  final Contact? contact;

  const AddContactScreen({super.key, this.contact});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _promptController = TextEditingController();
  String _avatarPath = '';
  bool _enableAI = false;
  bool _isGroup = false;
  List<String> _selectedMembers = [];
  int _selectedColor = 0xFF2196F3;

  final _colors = [
    0xFF2196F3, 0xFF4CAF50, 0xFFFF9800, 0xFFE91E63,
    0xFF9C27B0, 0xFF00BCD4, 0xFF795548, 0xFF607D8B,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _promptController.text = widget.contact!.systemPrompt;
      _avatarPath = widget.contact!.avatarPath;
      _enableAI = widget.contact!.aiEnabled;
      _isGroup = widget.contact!.isGroup;
      _selectedMembers = List.from(widget.contact!.memberIds);
      _selectedColor = widget.contact!.colorValue;
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
    );
    if (image != null) {
      setState(() => _avatarPath = image.path);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = context.read<AppState>();
    if (widget.contact != null) {
      final updated = widget.contact!
        ..name = _nameController.text.trim()
        ..systemPrompt = _promptController.text.trim()
        ..avatarPath = _avatarPath
        ..aiEnabled = _enableAI
        ..isGroup = _isGroup
        ..memberIds = _selectedMembers
        ..colorValue = _selectedColor;
      await appState.updateContact(updated);
    } else {
      await appState.addContact(
        name: _nameController.text.trim(),
        systemPrompt: _promptController.text.trim(),
        avatarPath: _avatarPath,
        aiEnabled: _enableAI,
        isGroup: _isGroup,
        memberIds: _selectedMembers,
        colorValue: _selectedColor,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact != null ? '编辑联系人' : '添加联系人'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(_selectedColor),
                      backgroundImage: _avatarPath.isNotEmpty
                          ? (_avatarPath.startsWith('http')
                              ? NetworkImage(_avatarPath)
                              : FileImage(File(_avatarPath)) as ImageProvider)
                          : null,
                      child: _avatarPath.isEmpty
                          ? const Icon(Icons.person, size: 48, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名称',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v?.trim().isEmpty == true ? '请输入名称' : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('群聊'),
              subtitle: const Text('创建多人群聊'),
              value: _isGroup,
              onChanged: (v) => setState(() => _isGroup = v),
            ),
            if (_isGroup) ...[
              const SizedBox(height: 8),
              const Text('选择群成员', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Consumer<AppState>(
                builder: (context, appState, child) {
                  final members = appState.contacts.where((c) => !c.isGroup).toList();
                  if (members.isEmpty) {
                    return const Text('暂无其他联系人，请先添加普通联系人');
                  }
                  return Wrap(
                    spacing: 8,
                    children: members.map((member) {
                      final selected = _selectedMembers.contains(member.id);
                      return FilterChip(
                        label: Text(member.name),
                        selected: selected,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedMembers.add(member.id);
                            } else {
                              _selectedMembers.remove(member.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用AI自动回复'),
              subtitle: const Text('使用GLM AI进行自动回复'),
              value: _enableAI,
              onChanged: (v) => setState(() => _enableAI = v),
            ),
            if (_enableAI) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'AI角色设定 (System Prompt)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.psychology),
                  hintText: '例如：你是星野，来自蔚蓝档案，性格慵懒...',
                ),
                maxLines: 4,
              ),
            ],
            const SizedBox(height: 16),
            const Text('头像颜色', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _colors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
