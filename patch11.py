import os
p = r'C:\Users\IRAQ SOFT\Desktop\fresh-app\customer_app\lib\screens\cart\cart_screen.dart'
content = open(p, encoding='utf-8').read()

# 1. Disable Back button and Trash
src_appbar = """      appBar: AppBar(
        title: Text('cart'.tr, style: TextStyle(color: themeTextColor)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: themeTextColor),
        actions: [
          IconButton(
            onPressed: () => cartController.clearCart(),
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
          ),
        ],
      ),"""

dst_appbar = """      appBar: AppBar(
        title: Text('cart'.tr, style: TextStyle(color: themeTextColor)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: themeTextColor),
        automaticallyImplyLeading: false,
        leading: Obx(() => IconButton(
          icon: Icon(Icons.arrow_back, color: cartController.isCountingDown.value ? Colors.grey : themeTextColor),
          onPressed: cartController.isCountingDown.value ? null : () => Get.back(),
        )),
        actions: [
          Obx(() => IconButton(
            onPressed: cartController.isCountingDown.value ? null : () => cartController.clearCart(),
            icon: Icon(LucideIcons.trash2, color: cartController.isCountingDown.value ? Colors.grey : Colors.red),
          )),
        ],
      ),"""
content = content.replace(src_appbar, dst_appbar)

# 2. Add Barrier to Stack
src_stack = """        return Stack(
          children: [
            ListView.builder("""

dst_stack = """        return Stack(
          children: [
            ListView.builder("""

# Wait, instead of just replacing Stack, I can inject the barrier before Checkout Bottom Sheet
src_checkout = """            // Checkout Bottom Sheet
            Positioned("""
dst_checkout = """            // Barrier
            if (cartController.isCountingDown.value)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
              
            // Checkout Bottom Sheet
            Positioned("""
content = content.replace(src_checkout, dst_checkout)

# 3. Update _OrderConfirmButtonState
src_countdown_start = """  void _startCountdown() {
    setState(() {
      _isCountingDown = true;
      _secondsRemaining = 6;
    });
    _progressController.reverse(from: 1.0);"""
dst_countdown_start = """  void _startCountdown() {
    Get.find<CartController>().isCountingDown.value = true;
    setState(() {
      _isCountingDown = true;
      _secondsRemaining = 6;
    });
    _progressController.reverse(from: 1.0);"""
content = content.replace(src_countdown_start, dst_countdown_start)

src_countdown_end = """        setState(() => _isCountingDown = false);
        widget.onConfirm();"""
dst_countdown_end = """        setState(() => _isCountingDown = false);
        Get.find<CartController>().isCountingDown.value = false;
        widget.onConfirm();"""
content = content.replace(src_countdown_end, dst_countdown_end)

src_countdown_cancel = """  void _cancelCountdown() {
    _timer.cancel();
    _progressController.stop();
    setState(() {
      _isCountingDown = false;
    });
  }"""
dst_countdown_cancel = """  void _cancelCountdown() {
    _timer.cancel();
    _progressController.stop();
    setState(() {
      _isCountingDown = false;
    });
    Get.find<CartController>().isCountingDown.value = false;
  }"""
content = content.replace(src_countdown_cancel, dst_countdown_cancel)

open(p, 'w', encoding='utf-8').write(content)
