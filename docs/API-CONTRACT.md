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
| `auth.signUp` (email) | `POST /auth/register` `{name, phone, password, referralCode?}` → `{token, userId, customerId, name, phone}`. Claims legacy accounts by phone. |
| `auth.signInWithPassword` | `POST /auth/login` `{phone, password}` → same shape. |
| `auth.currentUser` (29 sites) | Read cached profile + token from secure storage; refresh via `GET /customers/{customerId}/profile` *(NEW — being added)*. |
| `auth.updateUser` | `PATCH /customers/{customerId}/profile` `{name?, email?, gender?}` *(NEW)*. |
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
(a service has 1–4 duration/price variants), `addons`→addons *(being added to the payload)*.
`getTreatmentDetail(id)` = client-side lookup in this payload (it's small, cache it).

### 3. Availability & booking (`booking_remote_datasource.dart`, booking providers)

| App call today | Replacement |
|---|---|
| read `therapist_profiles` for picker | `GET /availability?packageId&branchId&date=YYYY-MM-DD` → `{slots: [{startISO, therapistId, therapistName, label}]}` *(NEW — wraps the same engine the WhatsApp bot uses; double-booking is impossible: the DB has an exclusion constraint)*. |
| `bookings` + `booking_items` insert | `POST /bookings` `{customerId, addressId, branchId, packageId, startISO, therapistId, paymentMethod: "cash"\|"qris"\|"va_mandiri", notes?, addonIds?, promoCode?, referralRewardId?}` → `{booking, freeAddon?}`. Add-ons ride the same call *(paid `addonIds[]` being added)*. 409 = slot just taken. |
| booking history | `GET /customers/{id}/bookings` → list w/ status, schedule, package, address. |
| booking detail / live status | `GET /bookings/{id}` (status timeline: pending→assigned→en_route→at_customer→in_progress→completed). Poll 15s. |
| `validateVoucher(code)` | `POST /promos/validate` `{code, customerId}` → `{valid, reason?, grants?}`. KAIZENBARU = free 30-min Body Massage add-on, first app order only. |

### 4. Promo / rewards / points (`promo_*`, `rewards_provider.dart`)

| App call today | Replacement |
|---|---|
| `client_points` | `loyaltyPoints` on the profile payload. |
| `client_vouchers` (referral) | `GET /customers/{id}/referral` → `{referralCode, rewards: [{id, status, addonName, ...}]}`. Redeem by passing `referralRewardId` on `POST /bookings`. |
| `rewards`, `reward_redemptions` | `GET /rewards` + `POST /customers/{id}/reward-redemptions` *(NEW — reward = points-priced free add-on/discount; redemption issues a voucher usable on the next booking)*. |
| `banners` | `GET /banners` *(NEW, admin-managed)*. |
| `vouchers`, `voucher_usages` | covered by `/promos/validate` + booking commit (usage counted server-side). |

### 5. Profile & addresses (`address_repository.dart`, profile pages)

| App call today | Replacement |
|---|---|
| `saved_addresses` select/insert/delete | `GET/POST /customers/{id}/addresses`, `DELETE /customers/{id}/addresses/{addressId}` *(DELETE being added)*. Fields: label, line, city, patokan (landmark), entranceNotes, lat/lng. |
| `profiles` select/update | `GET/PATCH /customers/{id}/profile` *(NEW)*. |
| avatar upload (Supabase storage) | `POST /customers/{id}/avatar` (multipart → Vercel Blob) *(NEW — phase 2; ship v1 with initials avatar)*. |

### 6. Intake (`client_intake_page.dart`)

`GET/PUT /customers/{id}/intake` *(NEW — same fields as the current `client_intake` table; stored on the platform so therapists/admin can see it)*.

### 7. Notifications (`notification_service.dart`)

`POST /fcm-token` `{userId, token, platform}` — backend + admin push infra already live.

## Gap list (backend work on our side — none block starting the swap)

| Gap | Size |
|---|---|
| `GET /customers/{id}/profile` + `PATCH` | S |
| `GET /availability` (expose existing slot engine) | S |
| paid `addonIds[]` on `POST /bookings` | S |
| addons in `GET /catalog` | XS |
| rewards catalog + redemption | M |
| banners | XS |
| intake GET/PUT | S |
| `DELETE` address | XS |
| avatar upload | M (phase 2) |

## Migration order (feature-by-feature, app stays shippable throughout)

1. **Auth** (phone-based; unlocks everything, enables legacy account claiming)
2. Catalog (+ per-service durations/addons)
3. Availability + create booking (+ history/detail)
4. Addresses
5. Vouchers / referral / points
6. Rewards, banners, intake
7. Avatar upload (phase 2)

## Test accounts (production)

- Customer: `08000000002` / `KaizenDemo2026` ("Ibu Sari (Demo)", has history)
- Register any new number → fresh account; register a *migrated* customer's
  number → account claiming with history attached.
