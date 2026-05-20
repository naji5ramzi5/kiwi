import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum VehicleType { bike, van }

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  VehicleType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text('أهلاً بك في فريق Fresh', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
              const SizedBox(height: 8),
              const Text('اختر نوع مركبة التوصيل الخاصة بك للبدء', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 40),
              
              _buildVehicleCard(
                type: VehicleType.bike,
                title: 'توصيل سكوتر (دراجة)',
                subtitle: 'مثالي للطلبات الصغيرة والسريعة',
                icon: Icons.directions_bike,
              ),
              
              const SizedBox(height: 20),
              
              _buildVehicleCard(
                type: VehicleType.van,
                title: 'توصيل فان (سيارة كبيرة)',
                subtitle: 'للطلبات الضخمة وطلبات المطاعم',
                icon: Icons.local_shipping,
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedType == null ? null : () {
                    // Navigate to main screen
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    disabledBackgroundColor: Colors.grey.shade200,
                  ),
                  child: const Text('متابعة التسجيل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard({required VehicleType type, required String title, required String subtitle, required IconData icon}) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10b981).withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF10b981) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF10b981).withOpacity(0.1), blurRadius: 10)] : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF10b981) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 40),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF10b981) : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 28),
          ],
        ),
      ),
    );
  }
}
