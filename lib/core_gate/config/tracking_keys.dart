import '../../cipher/key_mask.dart';

String trackingDevKey() {
  const v = [160, 206, 143, 227, 233, 235, 142, 153, 185, 227, 133, 243, 135, 186, 172, 231, 196, 157, 194, 235, 167, 147];
  return reveal(v);
}

String messagingProjectId() {
  const v = [235, 151, 178, 236, 231, 224, 187, 237, 205, 177, 133, 182];
  return reveal(v);
}
