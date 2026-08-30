# Paperboy

A newspaper subscription app with three roles: customer, admin, delivery.

## Demo logins
All passwords are `password`.

| Username | Role      |
|----------|-----------|
| customer | Customer  |
| admin    | Admin     |
| delivery | Delivery  |

## What's included
- `lib/models/` — User, Newspaper, Subscription data classes
- `lib/data/mock_data.dart` — placeholder top-10 English newspapers
- `lib/state/app_state.dart` — in-memory app state (Provider/ChangeNotifier):
  login, subscriptions, delivery assignment
- `lib/screens/login_screen.dart` — shared login for all 3 roles
- `lib/screens/customer/` — pick newspaper → set frequency/copies/address →
  mock checkout → subscription created
- `lib/screens/admin/` — view all subscriptions, assign a delivery boy to each
- `lib/screens/delivery/` — shows ONLY newspaper name + address for
  subscriptions assigned to that delivery account

## Notes / what's mocked for now
- Auth is hardcoded (no backend, no persistence). Restarting the app resets
  everything, including subscriptions.
- Payment is a fake 1-second delay — no real card processing.
- Newspaper catalog is a placeholder list of 10 well-known English papers.
- Only one delivery account exists, but the admin assignment UI already
  supports multiple delivery boys once you add more to `kUsers`.

## Running it
See the step-by-step instructions provided alongside this project.
