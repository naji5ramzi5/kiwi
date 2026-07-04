# Fresh Enterprise

Fresh Enterprise is a multi-app system for fresh-product ordering, branch POS operations, delivery, inventory, marketing, and finance.

## Apps

- `src/`: React + TypeScript admin dashboard built with Vite.
- `customer_app/`: Flutter customer app for browsing products, cart, orders, location, and notifications.
- `driver_app/`: Flutter driver app for driver login, approval, vehicle selection, and delivery map.
- `branch_pos/`: Flutter branch POS for delivery orders, inventory, purchases, stock entry, finance settlement, and hardware settings.
- `supabase/`: Supabase migrations and Edge Functions.

## Admin Dashboard

```bash
npm install
npm.cmd run dev
npm.cmd run build
```

PowerShell may block `npm` scripts on some Windows machines. Use `npm.cmd` if that happens.

Required web environment variables are loaded from `.env`:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`
- `VITE_FIREBASE_API_KEY`
- `VITE_FIREBASE_AUTH_DOMAIN`
- `VITE_FIREBASE_PROJECT_ID`
- `VITE_FIREBASE_STORAGE_BUCKET`
- `VITE_FIREBASE_MESSAGING_SENDER_ID`
- `VITE_FIREBASE_APP_ID`
- `VITE_FIREBASE_MEASUREMENT_ID`
- `VITE_FIREBASE_VAPID_KEY`

## Flutter Apps

Run each Flutter app from its folder:

```bash
cd customer_app
flutter pub get
flutter run
```

```bash
cd driver_app
flutter pub get
flutter run
```

```bash
cd branch_pos
flutter pub get
flutter run -d windows
```

## Supabase Edge Function Secrets

FCM private credentials must be stored as Supabase secrets, not inside source files:

```bash
supabase secrets set FCM_PROJECT_ID=your_project_id
supabase secrets set FCM_CLIENT_EMAIL=your_service_account_email
supabase secrets set FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
supabase secrets set SUPABASE_URL=your_supabase_url
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

Deploy functions:

```bash
supabase functions deploy send-notification
supabase functions deploy send-fcm-notification
```

## Current Verification

- Admin dashboard production build passes with `npm.cmd run build`.
- Delivery zones are routed at `/delivery-zones` and available from the admin sidebar.
- Branch POS stock entry no longer depends on missing local `ApiService` or model files.

## Important Security Note

If private Firebase service-account keys were ever committed or shared, rotate them in Firebase/GCP and update Supabase secrets with the new key.
