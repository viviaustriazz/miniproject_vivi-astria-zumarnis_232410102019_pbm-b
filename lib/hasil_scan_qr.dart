class ScanResult {
  final String data;
  final DateTime timestamp;
  final String type;

  ScanResult({
    required this.data,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
    };
  }

  static ScanResult fromJson(Map<String, dynamic> json) {
    return ScanResult(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
    );
  }

  String get displayType {
    if (data.startsWith('http://') || data.startsWith('https://')) {
      return 'URL';
    } else if (data.contains('@') && data.contains('.')) {
      return 'Email';
    } else if (RegExp(r'^\d+$').hasMatch(data)) {
      return 'Number';
    } else {
      return 'Text';
    }
  }
}