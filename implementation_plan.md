# Implementation Plan - DriveMate Enhancements & Bug Fixes

This document outlines the step-by-step plan to address admin car management issues, dashboard UI consistency (Navbars & 2026 Footers), and customer KYC PDF upload functionality in the DriveMate Flutter application.

---

## 1. Requirements & Problem Breakdown

### 1. Admin Fleet & Journey Operations
- **Car List Visibility**: Ensure Admin sees all cars in fleet after sign-in, with real-time Firestore synchronization.
- **Car Details & Inventory**: Display complete car details for every car (Name, Category, Fuel Type, Seating, Transmission, Price/Hr, Total Units, Available in Garage, On Journey). Show complete breakdown for count >= 0.
- **Interactive Editing & Deletion**: Make car items clickable so clicking on a car opens its detailed view with options to **Update** (`EditCarScreen`) or **Delete** (`_confirmDelete`).
- **Running Operations Page**: A dedicated page (`JourneyOperationsScreen`) listing:
  - **Currently Running Journeys**: Complete car details, complete customer details (Name, Email, Mobile, KYC status), time duration, pickup & drop locations, pricing.
  - **Pending Journeys**: Upcoming bookings with full customer & vehicle info.

### 2. Dashboards Layout (Navbars & Footers)
- **Consistency**: Attach appropriate `AppNavbar` and `AppFooter` to all dashboards (`GuestDashboard`, `UserDashboard`, `AdminDashboard`).
- **Copyright 2026**: Update `AppFooter` and all inline footers to explicitly state: `© 2026 DriveMate. All Rights Reserved.`.

### 3. Customer KYC PDF Upload Bug Fix
- **PDF Upload Support**: Fix bug where `ImagePicker` prevented users from selecting `.pdf` files.
- **Separate Uploads**: Ensure Aadhaar Card and Driving Licence can be uploaded separately with `.pdf`, `.jpg`, `.jpeg`, or `.png` extensions using `file_picker`.
- **Status & Feedback**: Automatically mark KYC as `Verified` in Firestore when both documents are uploaded, with download/view indicators for customers.

---

## 2. Proposed Implementation Steps

### Step 1: Footer & Navigation Bar Standardization
- Edit `lib/core/widgets/app_footer.dart` to display `© 2026 DriveMate. All Rights Reserved.`
- Update `lib/features/home/screens/guest_dashboard.dart` to use `AppFooter`.
- Update `lib/features/booking/screens/user_dashboard.dart` to include `AppFooter`.
- Ensure `AdminDashboard` has a standardized top bar and `AppFooter`.

### Step 2: Customer KYC PDF Upload Fix
- Update `lib/features/profile/screens/profile_screen.dart` to use `file_picker` package instead of `image_picker`.
- Support selecting both `.pdf` and image files for Aadhaar and Driving Licence independently.
- Upload to Firebase Storage with proper file extensions and update Firestore user document.

### Step 3: Admin Car Management & Click-to-Edit/Delete
- Enhance `lib/features/admin/screens/admin_dashboard.dart`:
  - Fetch and compute live metric stats for Total Units, Units on Journey, and Garage Units.
  - Display all cars (`count >= 0`) with complete vehicle specifications and unit status.
  - Add click handler (`onTap`) on each car item to show car modal/details with **Edit Car** and **Delete Car** actions.

### Step 4: Admin Running Operations & Pending Journeys Page
- Upgrade `lib/features/admin/screens/journey_operations_screen.dart`:
  - Render full details for Active Journeys and Pending Journeys.
  - Details: Complete Car Info, Complete Customer Info (Name, Email, Mobile, KYC), Pickup/Drop Locations, Duration, Total Price.

---

## 3. Verification Plan

### Manual & Automated Verification
- Run `flutter analyze` to ensure clean code with no errors.
- Run/Test the app flow to verify admin car display, click-to-edit/delete, operations view, 2026 footer across dashboards, and KYC PDF uploads.
