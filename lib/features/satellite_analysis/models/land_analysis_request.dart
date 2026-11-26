class LandAnalysisRequest {
  const LandAnalysisRequest({
    required this.boundary,
    required this.startDate,
    required this.endDate,
  });

  /// Coordinates are [longitude, latitude] pairs in GeoJSON order.
  final List<List<double>> boundary;
  final DateTime startDate;
  final DateTime endDate;

  Map<String, dynamic> toJson() {
    final ring = boundary.map((point) => point).toList(growable: true);
    if (ring.isNotEmpty &&
        (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
      ring.add(ring.first);
    }
    return {
      'geometry': {
        'type': 'Polygon',
        'coordinates': [ring],
      },
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
    };
  }

  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
