import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../models/key_action.dart';
import '../../native/remapper_channel.dart';
import '../theme/nothing_theme.dart';
import '../theme/nothing_type.dart';
import '../widgets/app_icon.dart';
import '../widgets/slab_group.dart';
import '../widgets/slab_tile.dart';
import 'app_picker_screen.dart';

class AppsColumnPickerScreen extends StatefulWidget {
  final AppsColumnActionSpec initialSpec;

  const AppsColumnPickerScreen({super.key, required this.initialSpec});

  @override
  State<AppsColumnPickerScreen> createState() => _AppsColumnPickerScreenState();
}

class _AppsColumnPickerScreenState extends State<AppsColumnPickerScreen> {
  final RemapperChannel _channel = RemapperChannel();
  final List<String> _packages = [];
  Map<String, String> _appNames = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _packages.addAll(widget.initialSpec.packageNames);
    _loadLabels();
  }

  /// Only the packages already in the column need names — the picker that adds
  /// new ones brings its own list.
  Future<void> _loadLabels() async {
    final names = await _channel.appLabels(_packages);
    if (!mounted) return;
    setState(() {
      _appNames = names;
      _loading = false;
    });
  }

  void _addApp() async {
    if (_packages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum of 6 apps allowed in the column',
            style: NothingType.archivo(color: Colors.white),
          ),
          backgroundColor: NothingTheme.accentRed,
        ),
      );
      return;
    }
    final result = await Navigator.push<AppActionSpec>(
      context,
      MaterialPageRoute(builder: (_) => const AppPickerScreen()),
    );
    if (!mounted) return;
    if (result != null && result.packageName.isNotEmpty) {
      if (_packages.contains(result.packageName)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'App already in the column',
              style: NothingType.archivo(color: Colors.white),
            ),
            backgroundColor: NothingTheme.accentRed,
          ),
        );
        return;
      }
      setState(() => _packages.add(result.packageName));
      await _loadLabels();
    }
  }

  void _removeApp(int index) {
    setState(() {
      _packages.removeAt(index);
    });
  }

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        final pkg = _packages.removeAt(index);
        _packages.insert(index - 1, pkg);
      });
    }
  }

  void _moveDown(int index) {
    if (index < _packages.length - 1) {
      setState(() {
        final pkg = _packages.removeAt(index);
        _packages.insert(index + 1, pkg);
      });
    }
  }

  void _save() {
    if (_packages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add at least one app',
            style: NothingType.archivo(color: Colors.white),
          ),
          backgroundColor: NothingTheme.accentRed,
        ),
      );
      return;
    }
    Navigator.pop(context, AppsColumnActionSpec(_packages));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NothingTheme.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      PhosphorIcons.arrowLeft,
                      color: NothingTheme.txtPrimary(context),
                      size: 22,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    onPressed: _save,
                    child: Text(
                      'SAVE',
                      style: NothingType.doto(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: NothingTheme.accentRed,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: NothingTheme.accentRed))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'APPS COLUMN',
                            style: NothingType.sectionHeader(color: NothingTheme.accentRed),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'CONFIGURE APPS',
                            style: NothingType.doto(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: NothingTheme.txtPrimary(context),
                              letterSpacing: 0.08,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Display up to 6 applications on the edge overlay card for quick launching.',
                            style: NothingType.archivo(
                              fontSize: 13,
                              color: NothingTheme.txtSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_packages.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              decoration: BoxDecoration(
                                color: NothingTheme.slab(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: NothingTheme.divider(context).withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    PhosphorIcons.squaresFour,
                                    size: 36,
                                    color: NothingTheme.txtMuted(context),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No apps added yet',
                                    style: NothingType.archivo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: NothingTheme.txtPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap below to choose applications.',
                                    style: NothingType.archivo(
                                      fontSize: 12,
                                      color: NothingTheme.txtMuted(context),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            SlabGroup(
                              children: List.generate(_packages.length, (idx) {
                                final pkg = _packages[idx];
                                final name = _appNames[pkg] ?? pkg;

                                return Container(
                                  color: NothingTheme.slab(context),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      AppIcon(packageName: pkg, size: 32),
                                      const SizedBox(width: 12),

                                      // App Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: NothingType.archivo(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: NothingTheme.txtPrimary(context),
                                              ),
                                            ),
                                            Text(
                                              pkg,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: NothingType.archivo(
                                                fontSize: 11,
                                                color: NothingTheme.txtMuted(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Reorder and Delete Actions
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(PhosphorIcons.arrowUp, size: 16),
                                            color: idx > 0
                                                ? NothingTheme.txtSecondary(context)
                                                : NothingTheme.txtMuted(context),
                                            onPressed: idx > 0 ? () => _moveUp(idx) : null,
                                          ),
                                          IconButton(
                                            icon: Icon(PhosphorIcons.arrowDown, size: 16),
                                            color: idx < _packages.length - 1
                                                ? NothingTheme.txtSecondary(context)
                                                : NothingTheme.txtMuted(context),
                                            onPressed: idx < _packages.length - 1
                                                ? () => _moveDown(idx)
                                                : null,
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              PhosphorIcons.trash,
                                              size: 16,
                                              color: NothingTheme.accentRed,
                                            ),
                                            onPressed: () => _removeApp(idx),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          const SizedBox(height: 20),

                          if (_packages.length < 4)
                            SlabGroup(
                              children: [
                                SlabTile(
                                  onTap: _addApp,
                                  leading: Icon(
                                    PhosphorIcons.plus,
                                    color: NothingTheme.accentRed,
                                    size: 18,
                                  ),
                                  title: 'Add Application',
                                  titleColor: NothingTheme.accentRed,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
