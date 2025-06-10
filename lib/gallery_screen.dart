import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'hasil_scan_qr.dart';
import 'storage_services.dart';
import 'package:url_launcher/url_launcher.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  GalleryScreenState createState() => GalleryScreenState();
}

class GalleryScreenState extends State<GalleryScreen> {
  List<ScanResult> scanResults = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadScanResults();
  }

  Future<void> _loadScanResults() async {
    try {
      final results = await StorageService.getScanResults();
      if (!mounted) return;

      setState(() {
        scanResults = results;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat hasil scan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Scan'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
        actions: [
          if (scanResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _showClearDialog,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pink))
          : scanResults.isEmpty
              ? _buildEmptyState()
              : _buildResultsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_2, size: 80, color: Colors.pink[100]),
          const SizedBox(height: 20),
          Text(
            'Belum ada hasil scan',
            style: TextStyle(fontSize: 18, color: Colors.pink[300]),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan QR Code untuk melihat hasilnya di sini',
            style: TextStyle(fontSize: 14, color: Colors.pink[200]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scanResults.length,
      itemBuilder: (context, index) {
        final result = scanResults[index];
        return _buildResultCard(result, index);
      },
    );
  }

  Widget _buildResultCard(ScanResult result, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getTypeIcon(result.displayType),
                const SizedBox(width: 8),
                Text(
                  result.displayType,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(result.displayType),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(result.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.pink[100]!),
              ),
              child: Text(
                result.data,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.pink),
                  label: const Text('Copy', style: TextStyle(color: Colors.pink)),
                  onPressed: () => _copyToClipboard(result.data),
                ),
                if (result.displayType == 'URL') ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_browser, size: 16, color: Colors.pink),
                    label: const Text('Buka', style: TextStyle(color: Colors.pink)),
                    onPressed: () => _openUrl(result.data),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Icon _getTypeIcon(String type) {
    switch (type) {
      case 'URL':
        return const Icon(Icons.link, color: Colors.pink);
      case 'Email':
        return const Icon(Icons.email, color: Colors.pinkAccent);
      case 'Number':
        return const Icon(Icons.numbers, color: Colors.pink);
      default:
        return const Icon(Icons.text_fields, color: Colors.pink);
    }
  }

  Color _getTypeColor(String type) {
    return Colors.pink;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disalin ke clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Gagal membuka $url';
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka URL: $url')),
      );
    }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Semua Riwayat'),
          content: const Text('Yakin ingin menghapus semua hasil scan?'),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              child: const Text('Hapus Semua'),
              onPressed: () async {
                await StorageService.clearScanResults();
                if (!mounted) return;
                setState(() {
                  scanResults.clear();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua hasil scan telah dihapus')),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
