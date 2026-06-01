import '../../cipher/key_mask.dart';

String trackingDevKey() {
  const v = [38, 185, 27, 72, 80, 26, 137, 225, 239, 215, 39, 125, 143, 46, 111, 103, 235, 204, 247, 131, 99, 106];
  return unveil(v);
}

String messagingProjectId() {
  const v = [103, 216, 62, 157, 0, 110, 110, 185, 44, 113, 30, 37];
  return unveil(v);
}
