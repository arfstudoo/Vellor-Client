class TrafficStats {
  final int uploadBytesPerSec;
  final int downloadBytesPerSec;
  final int totalUploadBytes;
  final int totalDownloadBytes;

  const TrafficStats({
    this.uploadBytesPerSec = 0,
    this.downloadBytesPerSec = 0,
    this.totalUploadBytes = 0,
    this.totalDownloadBytes = 0,
  });

  TrafficStats copyWith({
    int? uploadBytesPerSec,
    int? downloadBytesPerSec,
    int? totalUploadBytes,
    int? totalDownloadBytes,
  }) {
    return TrafficStats(
      uploadBytesPerSec: uploadBytesPerSec ?? this.uploadBytesPerSec,
      downloadBytesPerSec: downloadBytesPerSec ?? this.downloadBytesPerSec,
      totalUploadBytes: totalUploadBytes ?? this.totalUploadBytes,
      totalDownloadBytes: totalDownloadBytes ?? this.totalDownloadBytes,
    );
  }

  static String formatSpeed(int bytesPerSec) {
    if (bytesPerSec < 1024) {
      return '$bytesPerSec Б/с';
    } else if (bytesPerSec < 1024 * 1024) {
      final kb = (bytesPerSec / 1024).toStringAsFixed(1);
      return '$kb КБ/с';
    } else {
      final mb = (bytesPerSec / (1024 * 1024)).toStringAsFixed(2);
      return '$mb МБ/с';
    }
  }

  static String formatTotal(int bytes) {
    if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb КБ';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb МБ';
    } else {
      final gb = (bytes / (1024 * 1024 * 1024)).toStringAsFixed(2);
      return '$gb ГБ';
    }
  }
}
