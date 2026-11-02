# Kaizen Home Spa — Backend API Contract (homespa_client → Kaizen platform API)

**Goal:** homespa_client keeps its UI/UX exactly as designed, but reads/writes the
production Kaizen platform (the same database behind the admin panel, WhatsApp
bot, dispatch, and the staff app) instead of Supabase. One database of record:
bookings made in the app appear instantly in the admin panel, get a therapist +
driver dispatched, and the WhatsApp bot knows the same customer.

- **Base URL:** `https://kaizenspa-admin.vercel.app/api/mobile`
- **Auth:** JWT bearer token from login/register, sent as `Authorization: Bearer <token>`.
  Store in `flutter_secure_storage`. No Supabase SDK anywhere after migration.
- **IDs:** all UUIDs. **Money:** integer IDR (no decimals). **Time:** ISO-8601 UTC;
  display in `Asia/Jakarta`.

## Why auth must be phone-based (the one product change)

The production platform is keyed by **phone number**:
- 14,538 existing customers (migrated order history) claim their account by
  registering with the same phone — history, loyalty points, addresses attach automatically.
- The WhatsApp bot identifies customers by phone: same person on WA and in the app.
- Vouchers ("first order"), referral rewards, and loyalty points all join on the
  same customer row.

Email-based signup creates orphan accounts with none of that. The auth screens
should collect **name + phone + password** (email optional, stored on profile).

## Endpoint map (per current Supabase call site)

### 1. Auth (`auth_remote_datasource.dart`, auth providers)

| App call today | Replacement |
|---|---|
| `auth.signUp` (email) | `POST /auth/register` `{name, phone, email, password, referralCode?}` (email REQUIRED since 1.0.2) → `{token, userId, customerId, name, phone}`. Claims legacy accounts by phone. |
| `auth.signInWithPassword` | `POST /auth/login` `{phone, password}` → same shape. |
| `auth.currentUser` (29 sites) | Read cached profile + token from secure storage; refresh via `GET /customers/{customerId}/profile` *(live)*. |
| `auth.updateUser` | `PATCH /customers/{customerId}/profile` `{name?, email?, gender?}` *(live)*. |
| `auth.signOut` | Delete local token. |
| `auth.onAuthStateChange` | App-local (token presence). |

### 2. Catalog (`treatments_remote_datasource.dart`, home providers)

`GET /catalog` returns everything in one payload:
```json
{
  "categories": [{ "id", "name", "slug", "sortOrder" }],
  "services":   [{ "id", "categoryId", "name", "slug", "description", "active" }],
  "packages":   [{ "id", "serviceId", "name", "durationMin", "priceIdr", "photoUrl" }],
  "addons":     [{ "id", "name", "kind": "immediate|advance_only", "durationMin", "priceIdr" }]
}
```
Mapping: `categories`→categories, `treatments`→services, `treatment_durations`→packages
(a service has 1–4 duration/price variants), `addons`→addons *(live — payload includes `photoUrl` per package)*.
`getTreatmentDetail(id)` = client-side lookup in this payload (it's small, cache it).

### 3. Availability & booking (`booking_remote_datasource.dart`, booking providers)

| App call today | Replacement |
|---|---|
| read `therapist_profiles` for picker | `GET /availability?packageId&branchId&date=YYYY-MM-DD` → `{slots: [{startISO, therapistId, therapistName, label}]}` *(live — exhaustive: every free hour × therapist on the day, hours 08–22 WIB; optional `therapistId`/`addonMin` params; double-booking is impossible: the DB has an exclusion constraint)*. |
| `bookings` + `booking_items` insert | `POST /bookings` `{customerId, addressId, branchId, packageId, startISO, therapistId, paymentMethod: "cash"\|"qris"\|"va_mandiri", notes?, addonIds?, promoCode?, referralRewardId?}` → `{booking, freeAddon?}`. Add-ons ride the same call (paid `addonIds[]`, live). `redemptionId` consumes a points reward (free package must match `packageId`; discounts cut flat IDR). 409 = slot just taken. |
| booking history | `GET /customers/{id}/bookings` → list w/ status, schedule, package, address. |
| booking detail / live status | `GET /bookings/{id}` (status timeline: pending→assigned→en_route→at_customer→in_progress→completed). Poll 15s. |
| `validateVoucher(code)` | `POST /promos/validate` `{code, customerId}` → `{valid, reason?, grants?}`. KAIZENBARU = free 30-min Body Massage add-on, first app order only. |

### 4. Promo / rewards / points (`promo_*`, `rewards_provider.dart`)

| App call today | Replacement |
|---|---|
| `client_points` | `loyaltyPoints` on the profile payload. |
| `client_vouchers` (referral) | `GET /customers/{id}/referral` → `{referralCode, rewards: [{id, status, addonName, ...}]}`. Redeem by passing `referralRewardId` on `POST /bookings`. |
| `rewards`, `reward_redemptions` | `GET /rewards` + `POST /customers/{id}/reward-redemptions` *(live — reward = points-priced free package/discount; pass the redemption as `redemptionId` on `POST /bookings`)*. |
| `banners` | `GET /banners` *(live, admin-managed)*. |
| `vouchers`, `voucher_usages` | covered by `/promos/validate` + booking commit (usage counted server-side). |

### 5. Profile & addresses (`address_repository.dart`, profile pages)

| App call today | Replacement |
|---|---|
| `saved_addresses` select/insert/delete | `GET/POST /customers/{id}/addresses`, `DELETE /customers/{id}/addresses/{addressId}` *(live, incl. `PATCH .../{addressId}` for edit/set-default)*. Fields: label, line, city, patokan (landmark), entranceNotes, lat/lng. |
| `profiles` select/update | `GET/PATCH /customers/{id}/profile` *(live)*. |
| avatar upload (Supabase storage) | `POST /customers/{id}/avatar` (raw image bytes `image/jpeg|png|webp`, ≤3 MB, bearer auth → Vercel Blob public URL) *(live)*. |

### 6. Intake (`client_intake_page.dart`)

`GET/PUT /customers/{id}/intake` *(live — same fields, camelCase keys; stored on the platform so therapists/admin can see it)*.

### 7. Notifications (`notification_service.dart`)

`POST /push-token` `{token, platform}` (bearer auth identifies the user) — live; backend + admin push infra already in place.

## Gap list — all closed (2026-09-29)

Every gap below is implemented, deployed to production, and smoke-tested.
Extras added along the way: `POST /bookings/{id}/review` (therapist rating,
rolls the average), `GET /promos` (active codes for the voucher list), and
therapist id/name + `packageId` + `createdAt` on the bookings list.

| Gap | Status |
|---|---|
| `GET /customers/{id}/profile` + `PATCH` | live |
| `GET /availability` (exhaustive hourly slot scan) | live |
| paid `addonIds[]` + `redemptionId` on `POST /bookings` | live |
| addons + package `photoUrl` in `GET /catalog` | live |
| rewards catalog + redemption | live |
| banners | live |
| intake GET/PUT | live |
| `DELETE` + `PATCH` address, `isDefault` | live |
| avatar upload (Vercel Blob) | live |

## Migration status — COMPLETE (branch `api-integration`, 2026-09-29)

All seven steps are implemented in homespa_client; `supabase_flutter` is
removed from pubspec. `flutter analyze` is clean and the debug APK builds.

1. **Auth** — commit 89ca312
2. Catalog — commit 449e069
3. Availability + booking (+ history/detail/reviews) — commit a711874
4. Addresses — commit a711874
5. Vouchers / referral / points — commit 7f950b3
6. Rewards, banners, intake — commit 7f950b3
7. Avatar upload — commit 3e924b1

Platform model notes: one booking = one treatment package (checkout asks to
book a second treatment separately); paid add-on quantities collapse to one
each; promo codes grant a free add-on server-side (cart totals unchanged).

## Test accounts (production)

- Customer: `08000000002` / `KaizenDemo2026` ("Ibu Sari (Demo)", has history)
- Register any new number → fresh account; register a *migrated* customer's
  number → account claiming with history attached.
