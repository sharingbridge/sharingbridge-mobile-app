class ReferencePhotoUpload {
  const ReferencePhotoUpload({
    required this.artifactId,
    required this.viewUrl,
    required this.thumbnailUrl,
  });

  final String artifactId;
  final String viewUrl;
  final String thumbnailUrl;

  factory ReferencePhotoUpload.fromJson(Map<String, dynamic> json) {
    final artifactId = json['artifact_id']?.toString() ?? '';
    final viewUrl = json['view_url']?.toString() ?? '';
    final thumbnailUrl = json['thumbnail_url']?.toString() ?? '';
    if (artifactId.isEmpty || viewUrl.isEmpty) {
      throw FormatException('artifact_id and view_url are required');
    }
    return ReferencePhotoUpload(
      artifactId: artifactId,
      viewUrl: viewUrl,
      thumbnailUrl: thumbnailUrl.isNotEmpty ? thumbnailUrl : viewUrl,
    );
  }
}
