/// How the app should route on each launch.
///
/// [web]   → open WebView (returning user with a saved URL).
/// [game]  → open the white-part game (organic / unattributed).
/// [fresh] → no decision yet; full attribution pipeline will run.
enum LaunchMode {
  web,
  game,
  fresh;

  String toKey() {
    switch (this) {
      case LaunchMode.web:   return 'web';
      case LaunchMode.game:  return 'game';
      case LaunchMode.fresh: return 'fresh';
    }
  }

  static LaunchMode fromKey(String? raw) {
    switch (raw) {
      case 'web':
      case 'browser':
        return LaunchMode.web;
      case 'game':
      case 'arcade':
        return LaunchMode.game;
      default:
        return LaunchMode.fresh;
    }
  }
}
