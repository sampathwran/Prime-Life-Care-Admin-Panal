// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFileImpl({required String dataOrUrl, required String fileName}) {
  final anchor = html.AnchorElement(href: dataOrUrl)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
}

void pickImageFileImpl({required Function(String base64Data, String fileName) onPicked}) {
  final input = html.FileUploadInputElement()..accept = 'image/png,image/jpeg,image/webp,image/jpg';
  input.click();
  input.onChange.listen((event) {
    final file = input.files?.first;
    if (file != null) {
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((event) {
        final result = reader.result as String?;
        if (result != null) {
          onPicked(result, file.name);
        }
      });
    }
  });
}
