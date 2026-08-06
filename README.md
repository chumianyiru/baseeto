# BAseeto

仿《蔚蓝档案》(Blue Archive)风格的本地聊天模拟器+剧情编辑器，完全本地运行。

## 功能特性

### 💬 聊天功能
- 高仿微信/蔚蓝档案风格消息气泡
- 支持文本、图片、文件、转账、红包、表情等多种消息类型
- 消息逐条弹出动画效果
- 可指定下一条消息发送者
- 每条消息支持自定义提示音

### 👥 联系人管理
- 创建私聊和群聊
- 自定义头像、昵称、颜色
- 每个联系人可配置独立AI提示词
- 支持启用/禁用AI自动回复

### 🤖 AI陪聊
- 集成GLM-4-Flash大模型
- 每个联系人独立System Prompt
- API Key可配置
- AI以对方身份自动回复

### 💰 虚拟钱包
- 自定义余额
- 模拟转账（仅本地显示）
- 红包可领取，金额加入余额
- 数据本地永久保存

### 📖 剧情编辑器（核心特色）
- 高仿蔚蓝档案剧情播放界面
- 创建人物、编辑对话
- 支持选项分支，多结局
- 文字逐字打出效果
- 点击屏幕推进剧情
- 内置10个蔚蓝档案角色预设

### 🔔 其他
- 本地通知提醒
- 图片全屏查看、缩放、保存
- Material 3 (Material You) 设计
- Android + iOS 跨平台
- 所有数据本地持久化

## 技术栈
- Flutter + Material Design 3
- Provider 状态管理
- SharedPreferences 本地存储
- flutter_local_notifications
- audioplayers
- photo_view

## 构建
```bash
flutter pub get
flutter build apk --release --target-platform android-arm64-v8a
```
