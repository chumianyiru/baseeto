import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_state.dart';
import '../models/contact.dart';
import '../models/chat_message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import 'image_viewer_screen.dart';

class ChatScreen extends StatefulWidget {
  final Contact contact;

  const ChatScreen({super.key, required this.contact});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _showEmoji = false;
  String? _nextSenderId;
  String? _nextSenderName;
  bool _nextIsMe = false;
  String? _nextAvatarPath;
  final List<AnimationController> _messageAnimations = [];
  int _visibleMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _nextSenderId = 'me';
    _nextSenderName = '我';
    _nextIsMe = true;
    _animateMessages();
  }

  void _animateMessages() {
    final appState = context.read<AppState>();
    final messages = appState.getMessagesForChat(widget.contact.id);
    _visibleMessageCount = 0;
    for (var i = 0; i < messages.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          setState(() => _visibleMessageCount++);
        }
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    for (var controller in _messageAnimations) {
      controller.dispose();
    }
    super.dispose();
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

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final appState = context.read<AppState>();
    await appState.sendMessage(
      chatId: widget.contact.id,
      senderId: _nextSenderId ?? 'me',
      senderName: _nextSenderName ?? appState.settings.myName,
      content: text,
      isMe: _nextIsMe,
      avatarPath: _nextAvatarPath ?? widget.contact.avatarPath,
    );

    _textController.clear();
    _scrollToBottom();
    setState(() {
      _visibleMessageCount++;
    });
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final appState = context.read<AppState>();
    await appState.sendMessage(
      chatId: widget.contact.id,
      senderId: _nextSenderId ?? 'me',
      senderName: _nextSenderName ?? appState.settings.myName,
      content: '[图片]',
      type: MessageType.image,
      isMe: _nextIsMe,
      filePath: image.path,
      avatarPath: _nextAvatarPath ?? widget.contact.avatarPath,
    );
    _scrollToBottom();
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final appState = context.read<AppState>();
    await appState.sendMessage(
      chatId: widget.contact.id,
      senderId: _nextSenderId ?? 'me',
      senderName: _nextSenderName ?? appState.settings.myName,
      content: file.name,
      type: MessageType.file,
      isMe: _nextIsMe,
      filePath: file.path,
      avatarPath: _nextAvatarPath ?? widget.contact.avatarPath,
    );
    _scrollToBottom();
  }

  Future<void> _sendTransfer() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => _AmountDialog(title: '转账金额'),
    );
    if (amount == null || amount <= 0) return;

    final appState = context.read<AppState>();
    if (appState.settings.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('余额不足')),
      );
      return;
    }

    await appState.sendMessage(
      chatId: widget.contact.id,
      senderId: _nextSenderId ?? 'me',
      senderName: _nextSenderName ?? appState.settings.myName,
      content: '向你转账',
      type: MessageType.transfer,
      isMe: _nextIsMe,
      amount: amount,
      avatarPath: _nextAvatarPath ?? widget.contact.avatarPath,
    );
    await appState.setBalance(appState.settings.balance - amount);
    _scrollToBottom();
  }

  Future<void> _sendRedPacket() async {
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => _AmountDialog(title: '红包金额'),
    );
    if (amount == null || amount <= 0) return;

    final appState = context.read<AppState>();
    if (appState.settings.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('余额不足')),
      );
      return;
    }

    await appState.sendMessage(
      chatId: widget.contact.id,
      senderId: _nextSenderId ?? 'me',
      senderName: _nextSenderName ?? appState.settings.myName,
      content: '恭喜发财，大吉大利',
      type: MessageType.redPacket,
      isMe: _nextIsMe,
      amount: amount,
      avatarPath: _nextAvatarPath ?? widget.contact.avatarPath,
    );
    await appState.setBalance(appState.settings.balance - amount);
    _scrollToBottom();
  }

  void _showSenderSelector() {
    final appState = context.read<AppState>();
    final members = <Map<String, dynamic>>[
      {'id': 'me', 'name': appState.settings.myName, 'isMe': true, 'avatar': appState.settings.myAvatarPath},
      {'id': widget.contact.id, 'name': widget.contact.name, 'isMe': false, 'avatar': widget.contact.avatarPath},
      if (widget.contact.isGroup)
        ...widget.contact.memberIds.map((id) {
          final member = appState.getContactById(id);
          return {
            'id': id,
            'name': member?.name ?? '未知',
            'isMe': false,
            'avatar': member?.avatarPath ?? '',
          };
        }),
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: (member['avatar'] as String).isNotEmpty
                  ? NetworkImage(member['avatar'] as String)
                  : null,
              child: (member['avatar'] as String).isEmpty
                  ? Text((member['name'] as String)[0])
                  : null,
            ),
            title: Text(member['name'] as String),
            trailing: _nextSenderId == member['id']
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              setState(() {
                _nextSenderId = member['id'] as String;
                _nextSenderName = member['name'] as String;
                _nextIsMe = member['isMe'] as bool;
                _nextAvatarPath = member['avatar'] as String;
              });
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final messages = appState.getMessagesForChat(widget.contact.id);
        final visibleMessages = messages.take(_visibleMessageCount).toList();

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(widget.contact.colorValue),
                  backgroundImage: widget.contact.avatarPath.isNotEmpty
                      ? NetworkImage(widget.contact.avatarPath)
                      : null,
                  child: widget.contact.avatarPath.isEmpty
                      ? Text(
                          widget.contact.name[0],
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(widget.contact.name),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: _showSenderSelector,
                tooltip: '选择下一条消息发送者',
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: visibleMessages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == visibleMessages.length && _isTyping) {
                        return const TypingIndicator();
                      }
                      final message = visibleMessages[index];
                      return MessageBubble(
                        message: message,
                        onImageTap: message.type == MessageType.image && message.filePath != null
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ImageViewerScreen(
                                      imagePath: message.filePath!,
                                    ),
                                  ),
                                )
                            : null,
                        onRedPacketOpen: message.type == MessageType.redPacket && !message.isOpened
                            ? () => appState.openRedPacket(message.id)
                            : null,
                      );
                    },
                  ),
                ),
              ),
              _buildInputBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_nextSenderId != 'me')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '下一条由 $_nextSenderName 发送',
                      style: const TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showAttachmentSheet(),
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendTextMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.sentiment_satisfied_alt),
                  onPressed: () => _showEmojiPicker(),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _sendTextMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text('图片'),
              onTap: () {
                Navigator.pop(context);
                _sendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
              title: const Text('文件'),
              onTap: () {
                Navigator.pop(context);
                _sendFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.orange),
              title: const Text('转账'),
              onTap: () {
                Navigator.pop(context);
                _sendTransfer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.red),
              title: const Text('红包'),
              onTap: () {
                Navigator.pop(context);
                _sendRedPacket();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    final emojis = ['😀', '😂', '🥰', '😎', '🤔', '😴', '🥺', '😡', '👍', '❤️', '🎉', '🔥', '✨', '💯', '🤣', '😊'];
    showModalBottomSheet(
      context: context,
      builder: (context) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () {
              _textController.text += emojis[index];
              Navigator.pop(context);
            },
            child: Center(
              child: Text(emojis[index], style: const TextStyle(fontSize: 28)),
            ),
          );
        },
      ),
    );
  }
}

class _AmountDialog extends StatefulWidget {
  final String title;
  const _AmountDialog({required this.title});

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          prefixText: '¥ ',
          hintText: '0.00',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            final amount = double.tryParse(_controller.text);
            Navigator.pop(context, amount);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}
