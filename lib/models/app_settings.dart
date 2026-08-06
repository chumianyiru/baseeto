class AppSettings {
  double balance;
  String myName;
  String myAvatarPath;
  bool soundEnabled;
  bool notificationEnabled;
  double messageSpeed;
  String apiKey;
  String apiModel;

  AppSettings({
    this.balance = 0.0, this.myName = '我', this.myAvatarPath = '',
    this.soundEnabled = true, this.notificationEnabled = true,
    this.messageSpeed = 1.0,
    this.apiKey = 'd0a99ebaa97e4bac9e99e236211b15f5.m8eJh0XSXMVu2I8P',
    this.apiModel = 'glm-4-flash',
  });

  Map<String, dynamic> toJson() => {
    'balance': balance, 'myName': myName, 'myAvatarPath': myAvatarPath,
    'soundEnabled': soundEnabled, 'notificationEnabled': notificationEnabled,
    'messageSpeed': messageSpeed, 'apiKey': apiKey, 'apiModel': apiModel,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    balance: (j['balance'] ?? 0.0).toDouble(), myName: j['myName'] ?? '我',
    myAvatarPath: j['myAvatarPath'] ?? '', soundEnabled: j['soundEnabled'] ?? true,
    notificationEnabled: j['notificationEnabled'] ?? true,
    messageSpeed: (j['messageSpeed'] ?? 1.0).toDouble(),
    apiKey: j['apiKey'] ?? 'd0a99ebaa97e4bac9e99e236211b15f5.m8eJh0XSXMVu2I8P',
    apiModel: j['apiModel'] ?? 'glm-4-flash',
  );
}
