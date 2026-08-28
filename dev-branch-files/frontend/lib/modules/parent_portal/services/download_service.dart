import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

class DownloadService {
  /// Downloads a file from a URL
  /// [url] - The URL of the file to download
  /// [fileName] - The name to save the file as
  /// Returns true if successful, false otherwise
  static Future<bool> downloadFromUrl(String url, String fileName) async {
    try {
      // Remove any query parameters from the URL for cleaner processing
      final cleanUrl = url.split('?').first;

      // Create an anchor element and trigger download
      final anchor = html.AnchorElement()
        ..href = url
        ..download = fileName
        ..style.display = 'none';

      // Append to body, click, and remove
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();

      return true;
    } catch (e) {
      print('Download error: $e');
      return false;
    }
  }

  /// Downloads a file using fetch API (useful for CORS-protected resources)
  /// [url] - The URL of the file to download
  /// [fileName] - The name to save the file as
  /// Returns true if successful, false otherwise
  static Future<bool> downloadFileWithFetch(String url, String fileName) async {
    try {
      final response = await html.HttpRequest.request(
        url,
        method: 'GET',
        responseType: 'arraybuffer',
      );

      if (response.status == 200) {
        final bytes = Uint8List.view((response.response as ByteBuffer).asByteData().buffer);
        return _triggerBlobDownload(bytes, fileName);
      }
      return false;
    } catch (e) {
      print('Download with fetch error: $e');
      return false;
    }
  }

  /// Triggers a download from Uint8List bytes
  /// [bytes] - The file data as bytes
  /// [fileName] - The name to save the file as
  /// Returns true if successful, false otherwise
  static bool _triggerBlobDownload(Uint8List bytes, String fileName) {
    try {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement()
        ..href = url
        ..download = fileName
        ..style.display = 'none';

      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();

      // Clean up the object URL after a short delay
      Future.delayed(const Duration(milliseconds: 200), () {
        html.Url.revokeObjectUrl(url);
      });

      return true;
    } catch (e) {
      print('Blob download error: $e');
      return false;
    }
  }

  /// Sanitizes a filename by removing/replacing invalid characters
  static String sanitizeFilename(String filename) {
    // Replace invalid filename characters
    return filename
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '-')
        .replaceAll(RegExp(r'\s+'), '_')
        .trim();
  }

  /// Generates a filename from document title if not provided
  static String generateFilename(String title, String fileType) {
    final sanitized = sanitizeFilename(title);
    final extension = fileType.toLowerCase().startsWith('pdf') ? 'pdf' : fileType.toLowerCase();
    return '$sanitized.$extension';
  }

  /// Opens a file in a new tab for preview
  static void previewFile(String url) {
    try {
      html.window.open(url, '_blank');
    } catch (e) {
      print('Preview error: $e');
    }
  }

  /// Shows a download success message using browser's native notification
  /// This is a simple approach that can be enhanced with custom toasts
  static void showDownloadSuccess(String fileName) {
    print('Download started: $fileName');
    // Custom toast/snackbar feedback is handled by the caller
  }

  /// Shows a download error message
  static void showDownloadError(String errorMessage) {
    print('Download error: $errorMessage');
    // Custom error feedback is handled by the caller
  }
}
