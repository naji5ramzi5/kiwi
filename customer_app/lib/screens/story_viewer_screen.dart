import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

/// Full-screen Instagram-style story viewer.
///
/// Fetches `story_items` for each group in [groups] and plays them with
/// progress bars, auto-advance, tap navigation and swipe-down to close.
class StoryViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> groups;
  final int initialGroupIndex;

  const StoryViewerScreen({
    super.key,
    required this.groups,
    this.initialGroupIndex = 0,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;

  late int _groupIndex;
  int _itemIndex = 0;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  late AnimationController _progress;
  Timer? _loadTimeout;

  @override
  void initState() {
    super.initState();
    _groupIndex = widget.initialGroupIndex.clamp(0, widget.groups.length - 1);
    _progress = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    _loadGroup();
  }

  @override
  void dispose() {
    _progress.dispose();
    _loadTimeout?.cancel();
    super.dispose();
  }

  Map<String, dynamic> get _group => widget.groups[_groupIndex];

  Future<void> _loadGroup() async {
    setState(() {
      _loading = true;
      _items = [];
      _itemIndex = 0;
    });
    _progress.stop();

    try {
      final rows = await _supabase
          .from('story_items')
          .select()
          .eq('group_id', _group['id'])
          .order('created_at', ascending: true);
      _items = List<Map<String, dynamic>>.from(rows);
      // Respect sort_order when available
      _items.sort((a, b) => ((a['sort_order'] ?? 0) as num).compareTo((b['sort_order'] ?? 0) as num));
    } catch (e) {
      debugPrint('Error loading story items: $e');
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (_items.isEmpty) {
      // Nothing to show in this group → skip forward
      _nextGroup();
    } else {
      _playCurrent();
    }
  }

  void _playCurrent() {
    if (_items.isEmpty) return;
    final duration = ((_items[_itemIndex]['duration'] ?? 5) as num).toInt().clamp(2, 60);
    _progress
      ..reset()
      ..duration = Duration(seconds: duration)
      ..forward();
    setState(() {});
  }

  void _next() {
    if (_itemIndex < _items.length - 1) {
      _itemIndex++;
      _playCurrent();
    } else {
      _nextGroup();
    }
  }

  void _previous() {
    if (_itemIndex > 0) {
      _itemIndex--;
      _playCurrent();
    } else if (_groupIndex > 0) {
      _groupIndex--;
      _loadGroup();
    } else {
      _playCurrent();
    }
  }

  void _nextGroup() {
    if (_groupIndex < widget.groups.length - 1) {
      _groupIndex++;
      _loadGroup();
    } else {
      Get.back();
    }
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppTheme.primary;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          // RTL friendly: right side = previous, left side = next
          if (details.globalPosition.dx > width * 0.35) {
            _previous();
          } else {
            _next();
          }
        },
        onLongPressStart: (_) => _progress.stop(),
        onLongPressEnd: (_) => _progress.forward(),
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 300) Get.back();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Content ──
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            else if (_items.isEmpty)
              const Center(
                child: Text('لا يوجد محتوى', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
              )
            else
              _buildItem(_items[_itemIndex]),

            // ── Top gradient ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),

            // ── Progress bars ──
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: Row(
                textDirection: TextDirection.rtl,
                children: List.generate(_items.isEmpty ? 1 : _items.length, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: i < _itemIndex
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : i == _itemIndex
                              ? AnimatedBuilder(
                                  animation: _progress,
                                  builder: (context, _) => FractionallySizedBox(
                                    alignment: AlignmentDirectional.centerStart,
                                    widthFactor: _progress.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                    ),
                  );
                }),
              ),
            ),

            // ── Header: group info + close ──
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 12,
              right: 12,
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: ClipOval(
                      child: (_group['thumbnail_url'] ?? '').toString().isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _group['thumbnail_url'].toString(),
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) => Container(
                                color: AppTheme.primary,
                                child: const Icon(Icons.local_offer, color: Colors.white, size: 18),
                              ),
                            )
                          : Container(
                              color: AppTheme.primary,
                              child: const Icon(Icons.local_offer, color: Colors.white, size: 18),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (_group['name'] ?? _group['title'] ?? 'قصة').toString(),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Cairo',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final mediaType = (item['media_type'] ?? 'image').toString();
    final mediaUrl = (item['media_url'] ?? '').toString();
    final textContent = (item['text_content'] ?? '').toString();

    if (mediaType == 'text' || (mediaUrl.isEmpty && textContent.isNotEmpty)) {
      return Container(
        color: _parseColor(item['bg_color']?.toString()),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Text(
          textContent,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
            height: 1.6,
          ),
        ),
      );
    }

    // image (default)
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: mediaUrl,
          fit: BoxFit.contain,
          placeholder: (c, u) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          errorWidget: (c, u, e) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white38, size: 60),
          ),
        ),
        if (textContent.isNotEmpty)
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                textContent,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
