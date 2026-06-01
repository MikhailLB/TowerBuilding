/// Central registry of bundled asset locations. Keeping the strings in one
/// place avoids scattering literal paths through the widget tree.
class Art {
  Art._();

  static const _scene = 'assets/gameplay_assets';
  static const _boot = 'assets/additional_assets/loading_screen';

  static const sky = '$_scene/bg_sky_asset.webp';
  static const street = '$_scene/start_bg_asset.webp';
  static const soil = '$_scene/ground_asset.webp';
  static const cloud = '$_scene/cloud_asset_01.webp';
  static const crane = '$_scene/hook_asset.webp';
  static const foundation = '$_scene/start_building_asset.webp';

  static const mark = 'assets/logo.webp';
  static const wordmark = 'assets/logo_name.webp';

  /// House facade art, indexed 1..6.
  static String house(int n) => '$_scene/block_asset_0$n.webp';

  static const houseCount = 6;
  static List<String> get allHouses =>
      List.generate(houseCount, (i) => house(i + 1));

  // Boot curtain (loading screen) — untouched assets.
  static const bootVideoPortrait = '$_boot/9x16_Loading_Screen.mp4';
  static const bootVideoLandscape = '$_boot/16x9_loading_screen.mp4';
  static String bootBar(int state) => '$_boot/loading_bar_0$state.webp';
}
