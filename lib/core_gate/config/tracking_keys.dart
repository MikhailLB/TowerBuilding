import '../../cipher/key_mask.dart';

/// ════════════════════════════════════════════════════════════
/// ⚠️  TEMPLATE — encode your AppsFlyer & Firebase credentials
/// ════════════════════════════════════════════════════════════
///
/// trackingDevKey()      → AppsFlyer Dev Key
///                         Dashboard → App Settings → Dev Key
///
/// messagingProjectId()  → Firebase Project Number (numeric)
///                         google-services.json → "project_number"

// TODO: replace with your encoded AppsFlyer dev key bytes
String trackingDevKey() {
  const v = <int>[];
  if (v.isEmpty) return '';
  return reveal(v);
}

// TODO: replace with your encoded Firebase project number bytes
String messagingProjectId() {
  const v = <int>[];
  if (v.isEmpty) return '';
  return reveal(v);
}
