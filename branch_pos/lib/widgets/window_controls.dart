import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/app_theme.dart';

class WindowControls extends StatefulWidget {
  final Color backgroundColor;
  final Color iconColor;
  final Color hoverColor;
  final bool showTitle;
  final String? title;

  const WindowControls({
    super.key,
    this.backgroundColor = AppTheme.sidebar,
    this.iconColor = Colors.white70,
    this.hoverColor = Colors.white24,
    this.showTitle = true,
    this.title,
  });

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _checkMaximized();
  }

  Future<void> _checkMaximized() async {
    try {
      final isMax = await windowManager.isMaximized();
      if (mounted) setState(() => _isMaximized = isMax);
    } catch (_) {}
  }

  Future<void> _toggleMaximize() async {
    try {
      final isMax = await windowManager.isMaximized();
      if (isMax) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
      if (mounted) setState(() => _isMaximized = !isMax);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _toggleMaximize,
      child: Container(
        height: 36,
        color: widget.backgroundColor,
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(LucideIcons.store, color: AppTheme.primary, size: 16),
            const SizedBox(width: 8),
            if (widget.showTitle)
              Expanded(
                child: Text(
                  widget.title ?? 'Kiwi Fresh - نظام إدارة الفرع',
                  style: TextStyle(
                    color: widget.iconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              const Spacer(),
            _buildButton(
              icon: LucideIcons.minus,
              onTap: () async => await windowManager.minimize(),
            ),
            _buildButton(
              icon: _isMaximized ? LucideIcons.copy : LucideIcons.square,
              onTap: _toggleMaximize,
            ),
            _buildButton(
              icon: LucideIcons.x,
              hoverColor: Colors.red.withOpacity(0.8),
              onTap: () async => await windowManager.close(),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    Color? hoverColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      hoverColor: hoverColor ?? widget.hoverColor,
      child: Container(
        width: 46,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, color: widget.iconColor, size: 14),
      ),
    );
  }
}
