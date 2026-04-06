enum UploadStatus {
  queued,
  uploading,
  processing,
  success,
  failed;

  bool get isTerminal => this == success || this == failed;
  bool get isActive => this == uploading || this == processing;

  int get priority {
    switch (this) {
      case uploading:   return 5;
      case processing:  return 4;
      case queued:      return 3;
      case success:     return 2;
      case failed:      return 1;
    }
  }
}