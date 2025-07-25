class Media {
  final String id;
  final String filename;
  final String mimeType;
  final int filesize;
  final int width;
  final int height;
  final int focalX;
  final int focalY;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String url;
  final String? thumbnailURL;

  Media({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.filesize,
    required this.width,
    required this.height,
    required this.focalX,
    required this.focalY,
    required this.createdAt,
    required this.updatedAt,
    required this.url,
    this.thumbnailURL,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as String,
      filename: json['filename'] as String,
      mimeType: json['mimeType'] as String,
      filesize: (json['filesize'] is double) ? (json['filesize'] as double).toInt() : json['filesize'] as int,
      width: (json['width'] is double) ? (json['width'] as double).toInt() : json['width'] as int,
      height: (json['height'] is double) ? (json['height'] as double).toInt() : json['height'] as int,
      focalX: (json['focalX'] is double) ? (json['focalX'] as double).toInt() : json['focalX'] as int? ?? 50,
      focalY: (json['focalY'] is double) ? (json['focalY'] as double).toInt() : json['focalY'] as int? ?? 50,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      url: json['url'] as String,
      thumbnailURL: json['thumbnailURL'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'mimeType': mimeType,
      'filesize': filesize,
      'width': width,
      'height': height,
      'focalX': focalX,
      'focalY': focalY,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'url': url,
      'thumbnailURL': thumbnailURL,
    };
  }

  String get fullUrl => 'https://payload.sojo.uk$url';

  @override
  String toString() {
    return 'Media(id: $id, filename: $filename, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Media && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 