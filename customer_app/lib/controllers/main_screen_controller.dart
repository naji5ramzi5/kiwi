import 'package:get/get.dart';

class MainScreenController extends GetxController {
  var currentIndex = 0.obs;
  var localeVersion = 0.obs;

  void refreshLocale() {
    localeVersion.value++;
  }

  void switchTab(int index) {
    currentIndex.value = index;
  }
}
