import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../core/ui.dart';
import '../../models/models.dart';
import '../../widgets/member_card.dart';

class MemberCardScreen extends StatefulWidget {
  final Profile profile;
  const MemberCardScreen({super.key, required this.profile});

  @override
  State<MemberCardScreen> createState() => _MemberCardScreenState();
}

class _MemberCardScreenState extends State<MemberCardScreen> {
  final _frontKey = GlobalKey();
  final _backKey = GlobalKey();
  bool _busy = false;

  Future<void> _save(GlobalKey key, String fileName) async {
    setState(() => _busy = true);
    try {
      final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName.png');
      await file.writeAsBytes(data!.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: 'Kartu member MICHELIN MyXpert'),
      );
    } catch (_) {
      if (mounted) toast(context, 'Kartu gagal disimpan. Coba lagi.');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final no = p.memberNo.toLowerCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Kartu member')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Sisi depan',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 8),
          RepaintBoundary(
            key: _frontKey,
            child: MemberCardFront(profile: p),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _save(_frontKey, 'kartu-$no-depan'),
            icon: const Icon(Icons.download),
            label: const Text('Unduh sisi depan'),
          ),
          const SizedBox(height: 28),
          const Text('Sisi belakang',
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 8),
          RepaintBoundary(
            key: _backKey,
            child: MemberCardBack(profile: p),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
            _busy ? null : () => _save(_backKey, 'kartu-$no-belakang'),
            icon: const Icon(Icons.download),
            label: const Text('Unduh sisi belakang'),
          ),
        ],
      ),
    );
  }
}