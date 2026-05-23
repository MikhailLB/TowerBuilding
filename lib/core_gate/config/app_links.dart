import '../../cipher/key_mask.dart';

/// ════════════════════════════════════════════════════════════
/// ⚠️  TEMPLATE — encode your privacy/support URLs
/// ════════════════════════════════════════════════════════════
///
/// Run tool/encode_creds.dart to generate byte arrays.

// TODO: encoded https://yourdomain.com/privacy-policy.html
const List<int> _privacyMask = <int>[];

// TODO: encoded https://yourdomain.com/support.html
const List<int> _supportMask = <int>[];

String get appPrivacyPageUrl =>
    _privacyMask.isEmpty ? '' : reveal(_privacyMask);

String get appSupportPageUrl =>
    _supportMask.isEmpty ? '' : reveal(_supportMask);
