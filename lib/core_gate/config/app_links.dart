import '../../cipher/key_mask.dart';

const List<int> _privacyMask = [111, 241, 188, 34, 40, 226, 177, 71, 30, 242, 130, 91, 67, 124, 94, 151, 0, 12, 51, 251, 241, 52, 43, 206, 143, 44, 183, 214, 6, 210, 116, 185, 169, 182, 43, 107, 227, 237, 76, 147, 130, 202, 240, 191, 153, 249, 212, 77, 69, 125, 241, 230, 111, 32, 64, 146, 9];
const List<int> _supportMask = [111, 241, 188, 34, 40, 226, 177, 71, 30, 242, 130, 91, 67, 124, 94, 151, 0, 12, 51, 251, 241, 52, 43, 206, 143, 44, 183, 214, 6, 210, 116, 185, 169, 182, 43, 107, 227, 237, 79, 148, 155, 204, 254, 174, 148, 250, 204, 86, 68, 120];

String get appPrivacyPageUrl =>
    _privacyMask.isEmpty ? '' : reveal(_privacyMask);

String get appSupportPageUrl =>
    _supportMask.isEmpty ? '' : reveal(_supportMask);
