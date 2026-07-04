import 'package:get/get.dart';

class MainScreenController extends GetxController {
  var currentIndex = 0.obs;
  var selectedCategory = ''.obs;

  void switchTab(int index, {String? category}) {
    currentIndex.value = index;
    if (category != null) {
      selectedCategory.value = category;
    }
  }
}
