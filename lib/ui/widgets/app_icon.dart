import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../native/remapper_channel.dart';
import '../theme/nothing_theme.dart';

/// One app's launcher icon, loaded when the row is built rather than up front.
///
/// The platform caches what it has already rendered, so scrolling back over a row
/// resolves without another call and without a flash of the placeholder.
class AppIcon extends StatefulWidget {
  const AppIcon({super.key, required this.packageName, this.size = 40});

  final String packageName;
  final double size;

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  static final RemapperChannel _channel = RemapperChannel();

  Uint8List? _bytes;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(AppIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName) {
      _resolved = false;
      _bytes = null;
      _load();
    }
  }

  Future<void> _load() async {
    final packageName = widget.packageName;
    final bytes = await _channel.appIcon(packageName);
    // The row may have been recycled onto a different app while this was in flight.
    if (!mounted || packageName != widget.packageName) return;
    setState(() {
      _bytes = bytes;
      _resolved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes != null) {
      return Image.memory(bytes, width: widget.size, height: widget.size, gaplessPlayback: true);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: _resolved
          ? Icon(
              PhosphorIcons.appWindow,
              size: widget.size * 0.6,
              color: NothingTheme.txtMuted(context),
            )
          : null,
    );
  }
}
