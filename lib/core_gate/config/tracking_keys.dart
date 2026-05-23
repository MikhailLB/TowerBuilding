import '../../cipher/key_mask.dart';

String trackingDevKey() {
  const v = [100, 189, 173, 53, 98, 154, 210, 57, 36, 229, 180, 83, 89, 88, 69, 201, 60, 94, 48, 254, 228, 21];
  return reveal(v);
}

String messagingProjectId() {
  const v = [52, 182, 255, 98, 104, 238, 172, 88, 92, 168, 198, 11];
  return reveal(v);
}
