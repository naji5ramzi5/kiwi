import 'package:get/get.dart';

class MainScreenController extends GetxController {
  var currentIndex = 0.obs;
  var selectedCategory = ''.obs;
  var localeVersion = 0.obs;

  void refreshLocale() {
    localeVersion.value++;
  }

  void switchTab(int index, {String? category}) {
    currentIndex.value = index;
    if (category != null) {
      selectedCategory.value = category;
    }
  }
}
