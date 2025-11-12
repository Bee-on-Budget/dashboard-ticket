# TODO: Update Flutter Dashboard Design to Modern Template

## Information Gathered
- Current theme uses Color(0xFF3D4B3F) as primary color with green variations
- Theme defined in `lib/src/config/themes/theme_config.dart`
- Main screens: MergedScreen (navigation), HomeScreen (dashboard), LoginScreen, CreateUserScreen, TicketsScreen, ProfileScreen, CompaniesScreen, etc.
- Functionality includes Firebase auth, Firestore data, charts, file uploads, user management
- Current design is basic Material Design 2, needs modernization to Material 3 with better layouts

## Plan
### 1. Update Theme Configuration
- [x] Update `lib/src/config/themes/theme_config.dart` to Material 3 with modern styling, better shadows, improved component themes, animations

### 2. Update Main Navigation (MergedScreen)
- [ ] Update `lib/src/modules/screens/merged_screen.dart` with modern drawer, app bar, better navigation patterns

### 3. Update Dashboard (HomeScreen)
- [ ] Update `lib/src/modules/screens/home_screen.dart` with modern card layouts, better chart presentation, responsive grid

### 4. Update Authentication Screens
- [x] Update `lib/src/modules/screens/login_screen.dart` with modern form design, better spacing, animations
- [x] Update `lib/src/modules/screens/create_user_screen.dart` with modern form styling

### 5. Update Tickets Management
- [ ] Update `lib/src/modules/screens/tickets_screen.dart` with modern list/detail views, better filtering UI

### 6. Update Other Screens
- [x] Update `lib/src/modules/screens/profile_screen.dart`
- [x] Update `lib/src/modules/screens/companies_screen.dart`
- [ ] Update `lib/src/modules/screens/CreateCompanyScreen.dart`
- [ ] Update `lib/src/modules/screens/UserDetailsScreen.dart`
- [ ] Update `lib/src/modules/screens/comment_screen.dart`

### 7. Update Main App Configuration
- [ ] Update `lib/main.dart` if needed for Material 3

## Dependent Files to be edited
- `lib/src/config/themes/theme_config.dart`
- `lib/src/modules/screens/merged_screen.dart`
- `lib/src/modules/screens/home_screen.dart`
- `lib/src/modules/screens/login_screen.dart`
- `lib/src/modules/screens/create_user_screen.dart`
- `lib/src/modules/screens/tickets_screen.dart`
- `lib/src/modules/screens/profile_screen.dart`
- `lib/src/modules/screens/companies_screen.dart`
- `lib/src/modules/screens/CreateCompanyScreen.dart`
- `lib/src/modules/screens/UserDetailsScreen.dart`
- `lib/src/modules/screens/comment_screen.dart`
- `lib/main.dart` (if needed)

## Followup Steps
- [ ] Test all screens for functionality preservation
- [ ] Run flutter analyze for any linting issues
- [ ] Test on different screen sizes for responsiveness
- [ ] Verify Firebase integration still works
