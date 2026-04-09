enum NotificationMediaType { image, gif, video }

class NotificationMedia {
  const NotificationMedia({
    required this.url,
    required this.type,
    this.thumbnailUrl,
    this.altText,
  });

  final String url;
  final NotificationMediaType type;
  final String? thumbnailUrl;
  final String? altText;

  factory NotificationMedia.fromJson(Map<String, dynamic> json) =>
      NotificationMedia(
        url: json['url'] as String,
        type: NotificationMediaType.values.byName(json['type'] as String),
        thumbnailUrl: json['thumbnailUrl'] as String?,
        altText: json['altText'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type.name,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (altText != null) 'altText': altText,
      };
}