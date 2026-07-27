import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../theme/app_theme.dart';
import '../../../models/invoice_settings.dart';

class ReceiptPreviewWidget extends StatefulWidget {
  final InvoiceSettings settings;

  const ReceiptPreviewWidget({super.key, required this.settings});

  @override
  State<ReceiptPreviewWidget> createState() => _ReceiptPreviewWidgetState();
}

class _ReceiptPreviewWidgetState extends State<ReceiptPreviewWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReceiptPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final isSmall = s.paperSize == '58mm';
    final receiptWidth = isSmall ? 220.0 : 280.0;
    final fs = s.fontSize;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        width: receiptWidth + 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.eye, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  const Text('معاينة الفاتورة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSmall ? AppTheme.warningLight : AppTheme.primaryLighter,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSmall ? '58mm' : '80mm',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSmall ? AppTheme.warning : AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Receipt paper
            Expanded(
              child: Center(
                child: Container(
                  width: receiptWidth,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(2, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(-1, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo
                        if (s.logoPath != null && s.logoPath!.isNotEmpty)
                          _buildLogo(s.logoPath!),
                        if (s.logoPath != null && s.logoPath!.isNotEmpty)
                          SizedBox(height: 10 * fs),

                        // Store name
                        _buildCenteredText(
                          s.storeName.isNotEmpty ? s.storeName : 'KIWI STORE',
                          fontSize: 18 * fs,
                          fontWeight: FontWeight.w900,
                        ),
                        SizedBox(height: 4 * fs),

                        // Phone
                        if (s.storePhone.isNotEmpty)
                          _buildCenteredText(
                            'هاتف: ${s.storePhone}',
                            fontSize: 9 * fs,
                            color: Colors.grey.shade600,
                          ),

                        // Address
                        if (s.storeAddress.isNotEmpty)
                          _buildCenteredText(
                            s.storeAddress,
                            fontSize: 9 * fs,
                            color: Colors.grey.shade600,
                          ),
                        SizedBox(height: 10 * fs),

                        // Dashed divider
                        _buildDivider(),

                        // Invoice info
                        SizedBox(height: 6 * fs),
                        _buildInfoRow('رقم الفاتورة', '#INV-2026-0001', fs),
                        SizedBox(height: 3 * fs),
                        _buildInfoRow('العميل', 'أحمد محمد', fs),
                        if (s.showDate) ...[
                          SizedBox(height: 3 * fs),
                          _buildInfoRow('التاريخ', _formatDate(), fs),
                          SizedBox(height: 3 * fs),
                          _buildInfoRow('الوقت', _formatTime(), fs),
                        ],
                        SizedBox(height: 8 * fs),

                        // Divider
                        _buildDivider(),
                        SizedBox(height: 6 * fs),

                        // Column headers
                        _buildItemHeader(fs),
                        SizedBox(height: 4 * fs),

                        // Items
                        _buildItemRow('تفاح', '2', '5,000', '10,000', fs),
                        SizedBox(height: 3 * fs),
                        _buildItemRow('موز', '1', '3,000', '3,000', fs),
                        SizedBox(height: 3 * fs),
                        _buildItemRow('عصير برتقال', '3', '4,000', '12,000', fs),

                        SizedBox(height: 6 * fs),
                        _buildDivider(),

                        // Totals
                        SizedBox(height: 6 * fs),
                        _buildInfoRow('المجموع الفرعي', '25,000 د.ع', fs, isBold: false),
                        SizedBox(height: 3 * fs),
                        _buildInfoRow('رسوم التوصيل', '0 د.ع', fs, isBold: false),
                        _buildDivider(),
                        SizedBox(height: 4 * fs),
                        _buildInfoRow('الإجمالي', '25,000 د.ع', fs, isTotal: true),

                        SizedBox(height: 8 * fs),
                        _buildInfoRow('طريقة الدفع', 'نقداً', fs, isBold: false),

                        // Barcode
                        if (s.showBarcode) ...[
                          SizedBox(height: 12 * fs),
                          _buildBarcode(fs),
                        ],

                        SizedBox(height: 10 * fs),
                        _buildDivider(),
                        SizedBox(height: 8 * fs),

                        // Footer
                        _buildCenteredText(
                          s.footerText.isNotEmpty ? s.footerText : 'شكراً لتسوقكم معنا',
                          fontSize: 10 * fs,
                          fontWeight: FontWeight.w700,
                        ),
                        SizedBox(height: 4 * fs),
                        _buildCenteredText(
                          'نتمنى لكم يوماً سعيداً',
                          fontSize: 8 * fs,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(String path) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.primaryLighter,
            child: const Icon(LucideIcons.image, color: AppTheme.primary, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredText(String text, {
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: 1.3,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, double fs, {bool isBold = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: (isTotal ? 13 : 10) * fs,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.normal,
            color: isTotal ? AppTheme.primaryDark : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: (isTotal ? 13 : 10) * fs,
            fontWeight: isBold ? FontWeight.bold : (isTotal ? FontWeight.w900 : FontWeight.normal),
            color: isTotal ? AppTheme.primaryDark : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildItemHeader(double fs) {
    return Row(
      children: [
        Expanded(flex: 3, child: Text('الصنف', style: TextStyle(fontSize: 9 * fs, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
        Expanded(flex: 1, child: Text('الكمية', textAlign: TextAlign.center, style: TextStyle(fontSize: 9 * fs, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
        Expanded(flex: 2, child: Text('السعر', textAlign: TextAlign.center, style: TextStyle(fontSize: 9 * fs, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
        Expanded(flex: 2, child: Text('المجموع', textAlign: TextAlign.end, style: TextStyle(fontSize: 9 * fs, fontWeight: FontWeight.bold, color: Colors.grey.shade600))),
      ],
    );
  }

  Widget _buildItemRow(String name, String qty, String price, String total, double fs) {
    return Row(
      children: [
        Expanded(flex: 3, child: Text(name, style: TextStyle(fontSize: 10 * fs))),
        Expanded(flex: 1, child: Text(qty, textAlign: TextAlign.center, style: TextStyle(fontSize: 10 * fs))),
        Expanded(flex: 2, child: Text(price, textAlign: TextAlign.center, style: TextStyle(fontSize: 10 * fs))),
        Expanded(flex: 2, child: Text('$total د.ع', textAlign: TextAlign.end, style: TextStyle(fontSize: 10 * fs, fontWeight: FontWeight.w600))),
      ],
    );
  }

  Widget _buildDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, 1),
          painter: _DashedLinePainter(color: Colors.grey.shade300),
        );
      },
    );
  }

  Widget _buildBarcode(double fs) {
    return Column(
      children: [
        // Simple barcode representation
        Container(
          height: 40 * fs,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Text(
              '||| || ||| | || |||',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10 * fs,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        SizedBox(height: 4 * fs),
        Text(
          'INV-2026-0001',
          style: TextStyle(
            fontSize: 9 * fs,
            fontFamily: 'monospace',
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  String _formatTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
