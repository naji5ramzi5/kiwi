import os
p = r'C:\Users\IRAQ SOFT\.gemini\antigravity-ide\brain\5989a30a-b02f-4e8a-a845-0f32260efc9d\task.md'
content = """# مهام تطبيق المشتري (Fresh App - Customer App)

## 1. Authentication Improvements
- [x] Remove the "Continue as Guest" button completely.
- [x] Fix registration using phone number only. Automatically generate a hidden unique email (`phone_078xxxxxxx@freshapp.local`).
- [x] Allow login using phone number (map to hidden email).

## 2. Home Screen
- [x] Update logo to `fresh-r.png` and adjust sizes.
- [x] Sticky Top Area (Search bar and notifications stay pinned while scrolling).
- [x] Extend the header gradient background smoothly under the status bar.
- [x] Delivery Location fix modal flow. Change "الفروع" and "الموقع الحالي" to "توصيل إلى عنوان العميل".

## 3. Product Features & Interactions
- [x] Replace the truck banner placeholder with a beautiful, high-quality delivery truck image.
- [x] Fix image cropping in product details to show the full image nicely. Remove the text "رجوع" and keep only the back arrow.
- [x] Add To Cart global feedback popup ('تمت الإضافة إلى السلة بنجاح') with options.
- [x] Fix "Out of Stock" logic (disable Add To Cart button if stock == 0, show "نفدت الكمية").

## 4. Categories & Offers
- [x] Categories Page Redesign (modern grocery app style).
- [x] Exclusive Offers Section (fix button functionality and out of stock logic).
- [x] Fresh Products Section (remove duplicated title, keep single bold title).

## 5. Cart & Order Flow
- [x] Fix 6-second countdown timer bug (Lock UI with transparent barrier using `PopScope` and `Stack`).
- [x] Order Tracking Screen (add empty state, add Call/WhatsApp buttons to driver details).
- [x] Update notifications screen to allow deleting/clearing notifications (empty state added).
- [x] Support Screen (new professional screen with Call/WhatsApp/Email options).
- [x] Legal Pages (add 'About App' and 'Privacy Policy' placeholder pages).
- [x] Favorites Functionality (added `FavoritesController` using Supabase).
"""
open(p, 'w', encoding='utf-8').write(content)
