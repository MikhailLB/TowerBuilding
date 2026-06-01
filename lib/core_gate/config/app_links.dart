import '../../cipher/key_mask.dart';

const List<int> _privacyMask = [10, 48, 10, 141, 2, 98, 191, 126, 62, 92, 60, 117, 9, 108, 89, 149, 27, 229, 241, 171, 50, 120, 59, 229, 98, 105, 1, 65, 185, 209, 30, 252, 198, 40, 105, 61, 253, 124, 67, 34, 233, 128, 241, 223, 123, 13, 161, 247, 237, 133, 180, 95, 127, 30, 219, 28, 42];
const List<int> _supportMask = [10, 48, 10, 141, 2, 98, 191, 126, 62, 92, 60, 117, 9, 108, 89, 149, 27, 229, 241, 171, 50, 120, 59, 229, 98, 105, 1, 65, 185, 209, 30, 252, 198, 40, 105, 61, 253, 124, 69, 37, 175, 131, 114, 253, 253, 140, 162, 236, 109, 37];

String get appPrivacyPageUrl =>
    _privacyMask.isEmpty ? '' : unveil(_privacyMask);

String get appSupportPageUrl =>
    _supportMask.isEmpty ? '' : unveil(_supportMask);
