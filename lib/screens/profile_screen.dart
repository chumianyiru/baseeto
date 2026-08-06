import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/app_settings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final settings = appState.settings;
        return Scaffold(
          appBar: AppBar(title: const Text('我的')),
          body: ListView(
            children: [
              _buildHeader(context, settings, appState),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
                title: const Text('我的钱包'),
                subtitle: Text('余额: ¥${settings.balance.toStringAsFixed(2)}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showWalletDialog(context, appState),
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text('个人信息'),
                subtitle: Text(settings.myName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showProfileEditDialog(context, appState),
              ),
              ListTile(
                leading: const Icon(Icons.psychology, color: Colors.purple),
                title: const Text('AI设置'),
                subtitle: Text('模型: ${settings.modelName}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAISettingsDialog(context, appState),
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.red),
                title: const Text('通知设置'),
                trailing: Switch(
                  value: settings.notificationsEnabled,
                  onChanged: (v) {
                    settings.notificationsEnabled = v;
                    appState.updateSettings(settings);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.volume_up, color: Colors.green),
                title: const Text('消息音量'),
                subtitle: Slider(
                  value: settings.messageVolume,
                  onChanged: (v) {
                    settings.messageVolume = v;
                    appState.updateSettings(settings);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.grey),
                title: const Text('关于 BAseeto'),
                subtitle: const Text('Blue Archive风格聊天模拟器 v1.0.0'),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'BAseeto',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2024 BAseeto',
                    children: [
                      const Text('仿蔚蓝档案风格的本地聊天模拟器与剧情编辑器'),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AppSettings settings, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: settings.myAvatarPath.isNotEmpty
                ? NetworkImage(settings.myAvatarPath)
                : null,
            child: settings.myAvatarPath.isEmpty
                ? Text(
                    settings.myName[0],
                    style: const TextStyle(fontSize: 32, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.myName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'BAseeto ID: ${settings.myName.hashCode.abs().toString().substring(0, 8)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWalletDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController(text: appState.settings.balance.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置余额'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '¥ ',
            labelText: '余额金额',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              appState.setBalance(amount);
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showProfileEditDialog(BuildContext context, AppState appState) {
    final nameController = TextEditingController(text: appState.settings.myName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑个人信息'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '我的昵称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              appState.settings.myName = nameController.text.trim();
              appState.updateSettings(appState.settings);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showAISettingsDialog(BuildContext context, AppState appState) {
    final keyController = TextEditingController(text: appState.settings.apiKey);
    final modelController = TextEditingController(text: appState.settings.modelName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI设置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(labelText: 'API Key'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(labelText: '模型名称'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              appState.settings.apiKey = keyController.text.trim();
              appState.settings.modelName = modelController.text.trim();
              appState.updateSettings(appState.settings);
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
