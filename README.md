# PaperBoy Express

A Flutter app (Firebase Auth + Firestore) for newspaper subscriptions and 15-minute
greens & vegetable delivery, with three roles: customer, admin and delivery.

## Demo logins
All passwords are `password`. Customers can also sign up for a real account.

| Username | Role     | Notes                                                       |
|----------|----------|-------------------------------------------------------------|
| customer | Customer | Demo profile in zip `560102`, so greens & vegetables show up |
| admin    | Admin    |                                                             |
| delivery | Delivery |                                                             |

## What each role can do

**Customer**
- Subscribe to a newspaper with delivery days, copies, a start date and an end date.
  Both dates must be after today. Payment is taken up front by UPI.
- Pause a subscription for up to 30 days; it resumes automatically.
- Order greens & vegetables (zip `560102` only), paid by UPI and delivered in ~15 minutes.
- UPI payment shows a QR code that is valid for 15 minutes, then must be regenerated.
- **Receipts** tab with separate *Newspapers* and *Greens & Veg* sub tabs.
- Edit name, address, zip and phone, or delete the account (menu → My account).

**Admin**
- Subscriptions: see and edit everything, pause/resume, cancel, delete, assign delivery.
- Assign Delivery: newspaper subscriptions and today's greens orders.
- Catalog: add, edit, price and delete newspapers and greens/vegetables (and mark out of stock).
- Pricing: zip-specific prices, delivery charges, GST.
- Payments, Users (edit or delete a customer) and Issues (reported problems).

**Delivery person**
- Sees only today's deliveries (what, where, when). Nothing is editable.

**Everyone**: menu → *Report an issue* (support replies within 1 business day, urgent
contact shown) and *About us*.

## Placeholders to replace before launch
- `lib/utils/app_constants.dart`: UPI id, payee name and support contact are dummies.
- UPI payments aren't verified: the "I've completed the payment" button confirms them.
  Hook up a payment gateway callback in `UpiPaymentScreen`.

## Firestore
Collections used: `subscriptions`, `payments`, `veggieOrders`, `customers`, `emailIndex`,
`phoneIndex`, `newspapers`, `produce`, `pricing`, `deliveryCharges`, `settings`,
`notifications`, `issues`. Your security rules must allow the app to read and write them
(the admin and delivery logins are not Firebase accounts). The catalog is seeded with
defaults the first time the app runs.

## Running it
```
flutter pub get
flutter run -d chrome
flutter test
```
