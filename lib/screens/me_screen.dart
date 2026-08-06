import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('我的'), centerTitle: false),
      body: ListView(children: [
        // Profile header
        Container(padding: const EdgeInsets.all(20), child: Row(children: [
          CircleAvatar(radius: 32, backgroundColor: Theme.of(context).colorScheme.primary,
            child: app.settings.myAvatarPath.isNotEmpty ? null : const Icon(Icons.person, color: Colors.white, size: 36),
            backgroundImage: app.settings.myAvatarPath.isNotEmpty ? NetworkImage(app.settings.myAvatarPath) : null),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(app.settings.myName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('BAseeto v1.0.0', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ])),
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editProfile(context)),
        ])),
        const Divider(height: 1),
        // Wallet
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.account_balance_wallet, color: Colors.orange)),
          title: const Text('钱包'),
          subtitle: Text('余额 ¥${app.settings.balance.toStringAsFixed(2)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openWallet(context),
        ),
        // Settings
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.settings, color: Colors.blue)),
          title: const Text('设置'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openSettings(context),
        ),
        // About
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple[100], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.info_outline, color: Colors.purple)),
          title: const Text('关于'),
          subtitle: const Text('BAseeto - 蔚蓝档案风格聊天模拟器'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showAboutDialog(context: context, applicationName: 'BAseeto', applicationVersion: '1.0.0', applicationLegalese: '© 2026 BAseeto. 本地聊天模拟器+剧情编辑器。'),
        ),
      ]),
    );
  }

  void _editProfile(BuildContext context) {
    final app = context.read<AppState>();
    final nameCtrl = TextEditingController(text: app.settings.myName);
    final avatarCtrl = TextEditingController(text: app.settings.myAvatarPath);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('编辑资料'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '昵称')),
        TextField(controller: avatarCtrl, decoration: const InputDecoration(labelText: '头像URL(可选)')),
      ]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), TextButton(onPressed: () {
        app.settings.myName = nameCtrl.text.trim().isEmpty ? '我' : nameCtrl.text.trim();
        app.settings.myAvatarPath = avatarCtrl.text.trim();
        app.updateSettings(app.settings);
        Navigator.pop(context);
      }, child: const Text('保存')),
    ]));
  }

  void _openWallet(BuildContext context) {
    final app = context.read<AppState>();
    final amountCtrl = TextEditingController();
    showModalBottomSheet(context: context, builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Text('钱包', style: Theme.of(context).textTheme.titleLarge)),
      const SizedBox(height: 16),
      Center(child: Text('¥${app.settings.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold))),
      const SizedBox(height: 24),
      TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '设置余额', prefixText: '¥ ', border: OutlineInputBorder())),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () {
          final v = double.tryParse(amountCtrl.text);
          if (v != null) { app.setBalance(v); Navigator.pop(ctx); }
        }, child: const Text('设置余额'))),
        const SizedBox(width: 12),
        Expanded(child: FilledButton(onPressed: () {
          final v = double.tryParse(amountCtrl.text);
          if (v != null) { app.addBalance(v); Navigator.pop(ctx); }
        }, child: const Text('增加'))),
      ]),
    ]))));
  }

  void _openSettings(BuildContext context) {
    final app = context.read<AppState>();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(children: [
        SwitchListTile(title: const Text('消息提示音'), value: app.settings.soundEnabled, onChanged: (v) { app.settings.soundEnabled = v; app.updateSettings(app.settings); }),
        SwitchListTile(title: const Text('消息通知'), value: app.settings.notificationEnabled, onChanged: (v) { app.settings.notificationEnabled = v; app.updateSettings(app.settings); }),
        ListTile(title: const Text('消息弹出速度'), trailing: DropdownButton<double>(
          value: app.settings.messageSpeed,
          items: const [DropdownMenuItem(value: 0.5, child: Text('慢')), DropdownMenuItem(value: 1.0, child: Text('正常')), DropdownMenuItem(value: 2.0, child: Text('快')), DropdownMenuItem(value: 5.0, child: Text('瞬间'))],
          onChanged: (v) { if (v != null) { app.settings.messageSpeed = v; app.updateSettings(app.settings); } },
        )),
        const Divider(),
        ListTile(title: const Text('AI API Key'), subtitle: Text(app.settings.apiKey.substring(0, 10) + '...', overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.edit), onTap: _editApiKey),
        ListTile(title: const Text('AI 模型'), subtitle: Text(app.settings.apiModel), trailing: const Icon(Icons.edit), onTap: _editApiModel),
      ]),
    );
  }

  void _editApiKey() {
    final app = context.read<AppState>();
    final ctrl = TextEditingController(text: app.settings.apiKey);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('API Key'), content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'GLM API Key')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), TextButton(onPressed: () { app.settings.apiKey = ctrl.text.trim(); app.updateSettings(app.settings); Navigator.pop(context); }, child: const Text('保存'))],
    ));
  }

  void _editApiModel() {
    final app = context.read<AppState>();
    final ctrl = TextEditingController(text: app.settings.apiModel);
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('模型名称'), content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Model')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), TextButton(onPressed: () { app.settings.apiModel = ctrl.text.trim(); app.updateSettings(app.settings); Navigator.pop(context); }, child: const Text('保存'))],
    ));
  }
}
