import 'web_file_utils_stub.dart'
    if (dart.library.html) 'web_file_utils_web.dart';

/// Triggers a browser download of an image (base64 Data URL or network URL)
void downloadWebFile({required String dataOrUrl, required String fileName}) {
  downloadFileImpl(dataOrUrl: dataOrUrl, fileName: fileName);
}

/// Opens native file chooser dialog on PC to select an image file
void pickImageFileFromPC({required Function(String base64Data, String fileName) onPicked}) {
  pickImageFileImpl(onPicked: onPicked);
}
