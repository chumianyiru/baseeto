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
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final contacts = appState.contacts;
        final chats = contacts.map((contact) {
          final messages = appState.getMessagesForChat(contact.id);
          final lastMessage = messages.isNotEmpty ? messages.last : null;
          return MapEntry(contact, lastMessage);
        }).toList()
          ..sort((a, b) {
            if (a.value == null && b.value == null) return 0;
            if (a.value == null) return 1;
            if (b.value == null) return -1;
            return b.value!.timestamp.compareTo(a.value!.timestamp);
          });

        return Scaffold(
          appBar: AppBar(
            title: const Text('BAseeto'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
            ],
          ),
          body: chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '还没有聊天',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '去联系人页面添加好友开始聊天吧',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final contact = chats[index].key;
                    final lastMessage = chats[index].value;
                    return _ChatListItem(
                      contact: contact,
                      lastMessage: lastMessage,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(contact: contact),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final Contact contact;
  final ChatMessage? lastMessage;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.contact,
    required this.lastMessage,
    required this.onTap,
  });

  String _getPreviewText() {
    if (lastMessage == null) return '';
    switch (lastMessage!.type) {
      case MessageType.text:
        return lastMessage!.content;
      case MessageType.image:
        return '[图片]';
      case MessageType.file:
        return '[文件]';
      case MessageType.transfer:
        return '[转账] ¥${lastMessage!.amount?.toStringAsFixed(2)}';
      case MessageType.redPacket:
        return '[红包]';
      case MessageType.emoji:
        return '[表情]';
      case MessageType.system:
        return lastMessage!.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Color(contact.colorValue),
        backgroundImage: contact.avatarPath.isNotEmpty
            ? NetworkImage(contact.avatarPath)
            : null,
        child: contact.avatarPath.isEmpty
            ? Text(
                contact.name.isNotEmpty ? contact.name[0] : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              contact.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          if (lastMessage != null)
            Text(
              DateFormat('HH:mm').format(lastMessage!.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
      subtitle: Text(
        _getPreviewText(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
