enum LaunchMode {
  web,
  arcade,
  pristine;

  String storageId() {
    switch (this) {
      case LaunchMode.web:
        return 'web';
      case LaunchMode.arcade:
        return 'arcade';
      case LaunchMode.pristine:
        return 'pristine';
    }
  }

  static LaunchMode decode(String? raw) {
    switch (raw) {
      case 'web':
      case 'browser':
        return LaunchMode.web;
      case 'arcade':
      case 'game':
        return LaunchMode.arcade;
      default:
        return LaunchMode.pristine;
    }
  }
}
