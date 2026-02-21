# Errand Runner Application Blueprint

## Overview
A platform connecting customers with errand runners to perform various tasks.

## Application Architecture
- **Presentation Layer:** Flutter Widgets (Screens, Widgets)
- **Domain Layer:** Models, Business Logic
- **Data Layer:** Firebase Services (Auth, Firestore, Storage)
- **State Management:** Provider

## Implemented Features
- **Authentication:** Login, Signup (Customer/Runner/Admin roles)
- **Dashboards:** Customer, Runner, Admin
- **Errand Management:** Post, Track, and Manage Errands
- **Wallet & Transactions:** Manage user balances and history
- **Admin Management:** User management, Fee/Rate configuration, FAQ management, Financial approvals, Promo management, Statistics

## Current Plan: Auth Refinement and Admin Fixes
1. **Forgot Password:** Implement password reset logic and UI.
2. **Error Handling:** Improve login/signup error messages (e.g., "Invalid email or password").
3. **Admin Dashboard Fixes:** Resolve `RangeError` and ensure all Firestore collections are accessible/manageable.
4. **Fee Calculation:** Fix the issue where fees appear as "Ksh 0".
5. **Collection Integration:** Ensure all 14 specified collections are correctly utilized and displayed in the Admin section.

## Firestore Collections
- `audit_logs`
- `errands`
- `faq`
- `location_rates`
- `notifications`
- `pricing_addons`
- `reviews`
- `runner_status`
- `service rates`
- `statistics`
- `system_configs`
- `transactions`
- `users`
- `wallets`
