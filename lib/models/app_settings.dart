class AppSettings {
  String myName;
  String myAvatarPath;
  double balance;
  String apiKey;
  String apiBaseUrl;
  String modelName;
  bool notificationsEnabled;
  double messageVolume;
  int themeColor;

  AppSettings({
    this.myName = '我',
    this.myAvatarPath = '',
    this.balance = 0.0,
    this.apiKey = 'd0a99ebaa97e4bac9e99e236211b15f5.m8eJh0XSXMVu2I8P',
    this.apiBaseUrl = 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    this.modelName = 'glm-4-flash',
    this.notificationsEnabled = true,
    this.messageVolume = 0.7,
    this.themeColor = 0xFF3B82F6,
  });

  Map<String, dynamic> toJson() => {
    'myName': myName,
    'myAvatarPath': myAvatarPath,
    'balance': balance,
    'apiKey': apiKey,
    'apiBaseUrl': apiBaseUrl,
    'modelName': modelName,
    'notificationsEnabled': notificationsEnabled,
    'messageVolume': messageVolume,
    'themeColor': themeColor,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    myName: json['myName'] as String? ?? '我',
    myAvatarPath: json['myAvatarPath'] as String? ?? '',
    balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    apiKey: json['apiKey'] as String? ?? 'd0a99ebaa97e4bac9e99e236211b15f5.m8eJh0XSXMVu2I8P',
    apiBaseUrl: json['apiBaseUrl'] as String? ?? 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
    modelName: json['modelName'] as String? ?? 'glm-4-flash',
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    messageVolume: (json['messageVolume'] as num?)?.toDouble() ?? 0.7,
    themeColor: json['themeColor'] as int? ?? 0xFF3B82F6,
  );
}
