import 'dart:io';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onImageTap;
  final VoidCallback? onRedPacketOpen;

  const MessageBubble({
    super.key,
    required this.message,
    this.onImageTap,
    this.onRedPacketOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            CircleAvatar(
              radius: 18,
              child: Text(message.senderName.isNotEmpty ? message.senderName[0] : '?'),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!message.isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(
                      message.senderName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                GestureDetector(
                  onTap: message.type == MessageType.redPacket ? onRedPacketOpen : onImageTap,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: _getPadding(),
                    decoration: BoxDecoration(
                      color: _getBubbleColor(context),
                      borderRadius: _getBorderRadius(),
                    ),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              child: Text(message.senderName.isNotEmpty ? message.senderName[0] : '?'),
            ),
          ],
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (message.type) {
      case MessageType.image:
        return EdgeInsets.zero;
      case MessageType.redPacket:
      case MessageType.transfer:
        return const EdgeInsets.all(12);
      default:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
    }
  }

  Color _getBubbleColor(BuildContext context) {
    if (message.type == MessageType.redPacket) {
      return message.isOpened ? Colors.grey[400]! : const Color(0xFFF56565);
    }
    if (message.type == MessageType.transfer) {
      return const Color(0xFFED8936);
    }
    return message.isMe
        ? Theme.of(context).colorScheme.primary
        : Colors.grey[200]!;
  }

  BorderRadius _getBorderRadius() {
    return BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(message.isMe ? 16 : 4),
      bottomRight: Radius.circular(message.isMe ? 4 : 16),
    );
  }

  Widget _buildContent() {
    switch (message.type) {
      case MessageType.text:
      case MessageType.sticker:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: message.isMe ? Colors.white : Colors.black87,
          ),
        );
      case MessageType.image:
        final imagePath = message.extraData ?? '';
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: imagePath.isNotEmpty
              ? (imagePath.startsWith('http')
                  ? Image.network(
                      imagePath,
                      width: 200,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(imagePath),
                      width: 200,
                      fit: BoxFit.cover,
                    ))
              : Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: message.isMe ? Colors.white : Colors.black87),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(color: message.isMe ? Colors.white : Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case MessageType.transfer:
        final amount = double.tryParse(message.extraData ?? '0') ?? 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '转账',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  '¥${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        );
      case MessageType.redPacket:
        final amount = double.tryParse(message.extraData ?? '0') ?? 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.isOpened ? '红包已领取' : '微信红包',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  message.content,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (!message.isOpened)
                  Text(
                    '¥${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        );
      default:
        return Text(message.content);
    }
  }
}
