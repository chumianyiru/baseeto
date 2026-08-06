import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/contact.dart';
import 'contact_edit_screen.dart';
import 'chat_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('联系人'), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add), label: const Text('新建'),
      ),
      body: app.contacts.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.contacts_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('还没有联系人', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            const SizedBox(height: 8),
            Text('点击右下角添加', style: TextStyle(color: Colors.grey[400])),
          ]))
        : ListView.separated(
            itemCount: app.contacts.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
            itemBuilder: (_, i) {
              final c = app.contacts[i];
              return ListTile(
                leading: CircleAvatar(radius: 20, backgroundColor: Color(c.colorValue),
                  child: c.avatarPath.isEmpty ? Text(c.name.isNotEmpty ? c.name[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
                  backgroundImage: c.avatarPath.isNotEmpty ? NetworkImage(c.avatarPath) : null),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(c.isGroup ? '群聊 · ${c.memberIds.length}人' : (c.aiEnabled ? 'AI已开启' : 'AI已关闭'), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (!c.isGroup) IconButton(icon: Icon(c.aiEnabled ? Icons.smart_toy : Icons.smart_toy_outlined, color: c.aiEnabled ? Theme.of(context).colorScheme.primary : Colors.grey),
                    onPressed: () { c.aiEnabled = !c.aiEnabled; app.updateContact(c); }),
                  IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContactEditScreen(contact: c)))),
                ]),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(contact: c))),
              );
            },
          ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(16), child: Text('新建', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      ListTile(leading: const Icon(Icons.person_add), title: const Text('添加联系人'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactEditScreen())); }),
      ListTile(leading: const Icon(Icons.group_add), title: const Text('创建群聊'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactEditScreen(isGroup: true))); }),
    ])));
  }
}
