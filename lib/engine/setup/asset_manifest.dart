abstract final class MediaConfig {
  static String? splashVideoPortrait;
  static String? splashVideoLandscape;
  static String? splashBackground;

  static String? notifyOfferVideoPortrait;
  static String? notifyOfferVideoLandscape;
  static String? notifyOfferBackground;
  static String? notifyOfferBackgroundPortrait;
  static String? notifyOfferBackgroundLandscape;

  static String? networkPauseBackgroundPortrait;
  static String? networkPauseBackgroundLandscape;

  static String? networkPauseImagePortrait;
  static String? networkPauseImageLandscape;

  static String? networkPauseRetryButton;

  static void configure({
    String? splashVideoPortrait,
    String? splashVideoLandscape,
    String? splashBackground,
    String? notifyOfferVideoPortrait,
    String? notifyOfferVideoLandscape,
    String? notifyOfferBackground,
    String? notifyOfferBackgroundPortrait,
    String? notifyOfferBackgroundLandscape,
    String? networkPauseBackgroundPortrait,
    String? networkPauseBackgroundLandscape,
    String? networkPauseImagePortrait,
    String? networkPauseImageLandscape,
    String? networkPauseRetryButton,
  }) {
    MediaConfig.splashVideoPortrait = splashVideoPortrait;
    MediaConfig.splashVideoLandscape = splashVideoLandscape;
    MediaConfig.splashBackground = splashBackground;
    MediaConfig.notifyOfferVideoPortrait = notifyOfferVideoPortrait;
    MediaConfig.notifyOfferVideoLandscape = notifyOfferVideoLandscape;
    MediaConfig.notifyOfferBackground = notifyOfferBackground;
    MediaConfig.notifyOfferBackgroundPortrait = notifyOfferBackgroundPortrait;
    MediaConfig.notifyOfferBackgroundLandscape = notifyOfferBackgroundLandscape;
    MediaConfig.networkPauseBackgroundPortrait = networkPauseBackgroundPortrait;
    MediaConfig.networkPauseBackgroundLandscape = networkPauseBackgroundLandscape;
    MediaConfig.networkPauseImagePortrait = networkPauseImagePortrait;
    MediaConfig.networkPauseImageLandscape = networkPauseImageLandscape;
    MediaConfig.networkPauseRetryButton = networkPauseRetryButton;
  }
}
