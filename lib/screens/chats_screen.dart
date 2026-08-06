import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/contact.dart';
import '../models/chat_message.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final contactsWithMsgs = app.contacts.where((c) => (app.messages[c.id]?.isNotEmpty ?? false)).toList()
      ..sort((a, b) {
        final ma = app.messages[a.id]?.last.timestamp ?? DateTime(2000);
        final mb = app.messages[b.id]?.last.timestamp ?? DateTime(2000);
        return mb.compareTo(ma);
      });
    return Scaffold(
      appBar: AppBar(title: const Text('聊天'), centerTitle: false),
      body: contactsWithMsgs.isEmpty
        ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('还没有聊天记录', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            const SizedBox(height: 8),
            Text('去联系人页面开始聊天吧', style: TextStyle(color: Colors.grey[400])),
          ]))
        : ListView.separated(
            itemCount: contactsWithMsgs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
            itemBuilder: (_, i) {
              final c = contactsWithMsgs[i];
              final msgs = app.messages[c.id] ?? [];
              final last = msgs.isEmpty ? null : msgs.last;
              return ListTile(
                leading: _avatar(c, 40),
                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_lastMsgText(last), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: last != null ? Text(DateFormat('HH:mm').format(last.timestamp), style: TextStyle(color: Colors.grey[500], fontSize: 12)) : null,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(contact: c))),
              );
            },
          ),
    );
  }

  String _lastMsgText(ChatMessage? m) {
    if (m == null) return '';
    if (m.isMe) return '我: ${m.content}';
    return '${m.senderName}: ${m.content}';
  }

  Widget _avatar(Contact c, double size) {
    return CircleAvatar(radius: size / 2, backgroundColor: Color(c.colorValue),
      child: c.avatarPath.isEmpty ? Text(c.name.isNotEmpty ? c.name[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
      backgroundImage: c.avatarPath.isNotEmpty ? NetworkImage(c.avatarPath) : null,
    );
  }
}
