import os
p = r'C:\Users\IRAQ SOFT\Desktop\fresh-app\customer_app\lib\screens\home\widgets\products_section.dart'
content = open(p, encoding='utf-8').read()

import_fav = "import '../../../controllers/favorites_controller.dart';\n"
if "import '../../../controllers/favorites_controller.dart';" not in content:
    content = content.replace("import '../../../controllers/cart_controller.dart';", "import '../../../controllers/cart_controller.dart';\n" + import_fav)

src_controller = "  final CartController cartController = Get.isRegistered<CartController>()\n      ? Get.find<CartController>()\n      : Get.put(CartController());"
dst_controller = "  final CartController cartController = Get.isRegistered<CartController>()\n      ? Get.find<CartController>()\n      : Get.put(CartController());\n  final FavoritesController favController = Get.isRegistered<FavoritesController>() ? Get.find<FavoritesController>() : Get.put(FavoritesController());"

if "final FavoritesController favController" not in content:
    content = content.replace(src_controller, dst_controller)

src_heart = """                    // Favorite button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.5)
                              : Colors.white.withOpacity(0.92),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.heart,
                          size: 14,
                          color: isDark ? Colors.white60 : Colors.grey.shade400,
                        ),
                      ),
                    ),"""

dst_heart = """                    // Favorite button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => favController.toggleFavorite(p['id'].toString()),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withOpacity(0.5)
                                : Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Obx(() {
                            final isFav = favController.isFavorite(p['id'].toString());
                            return Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color: isFav ? Colors.red : (isDark ? Colors.white60 : Colors.grey.shade400),
                            );
                          }),
                        ),
                      ),
                    ),"""

content = content.replace(src_heart, dst_heart)
open(p, 'w', encoding='utf-8').write(content)
