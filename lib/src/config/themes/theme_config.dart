import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final _poppinsFont = GoogleFonts.poppins();

final ThemeData themeConfig = ThemeData(
  useMaterial3: true, // Enable Material 3
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF3D4B3F), // Primary color
    brightness: Brightness.light,
  ),

  // App Bar Theme
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF3D4B3F),
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  ),

  // Card Theme
  cardTheme: CardTheme(
    elevation: 4,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),

  // Floating Action Button Theme
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: const Color(0xFF3D4B3F),
    foregroundColor: Colors.white,
    elevation: 6,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),

  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3D4B3F),
      foregroundColor: Colors.white,
      iconColor: Colors.white,
      elevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),

  // Outlined Button Theme
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF3D4B3F),
      side: const BorderSide(color: Color(0xFF3D4B3F), width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),

  // Text Button Theme
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF3D4B3F),
      textStyle: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),

  // Input Decoration Theme
  inputDecorationTheme: InputDecorationTheme(
    fillColor: Colors.white,
    filled: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: GoogleFonts.poppins(
      fontSize: 16,
      color: const Color(0xFF8D8D8D),
    ),
    labelStyle: GoogleFonts.poppins(
      fontSize: 16,
      color: const Color(0xFF4F4F4F),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFE0E0E0),
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFFE0E0E0),
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF3D4B3F),
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.red,
        width: 1,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.red,
        width: 2,
      ),
    ),
    prefixIconColor: const Color(0xFF4F4F4F),
    suffixIconColor: const Color(0xFF4F4F4F),
  ),

  // Dropdown Menu Theme
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(Colors.white),
      elevation: WidgetStateProperty.all(8),
      shadowColor: WidgetStateProperty.all(Colors.black26),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  ),

  // Dialog Theme
  dialogTheme: DialogTheme(
    backgroundColor: Colors.white,
    elevation: 8,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),

  // Bottom Sheet Theme
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    elevation: 8,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  ),

  // Navigation Bar Theme
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    elevation: 4,
    indicatorColor: const Color(0xFF3D4B3F).withValues(alpha: 0.1),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3D4B3F),
        );
      }
      return GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
      );
    }),
  ),

  // Drawer Theme
  drawerTheme: DrawerThemeData(
    backgroundColor: Colors.white,
    elevation: 8,
    shadowColor: Colors.black26,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
    ),
  ),

  // Font and Text Theme
  fontFamily: _poppinsFont.fontFamily,
  textTheme: TextTheme(
    displayLarge: _poppinsFont.copyWith(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF1C1B1F),
    ),
    displayMedium: _poppinsFont.copyWith(
      fontSize: 45,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF1C1B1F),
    ),
    displaySmall: _poppinsFont.copyWith(
      fontSize: 36,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF1C1B1F),
    ),
    headlineLarge: _poppinsFont.copyWith(
      fontSize: 32,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF1C1B1F),
    ),
    headlineMedium: _poppinsFont.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF1C1B1F),
    ),
    headlineSmall: _poppinsFont.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1C1B1F),
    ),
    titleLarge: _poppinsFont.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF1C1B1F),
    ),
    titleMedium: _poppinsFont.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF1C1B1F),
    ),
    titleSmall: _poppinsFont.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF1C1B1F),
    ),
    bodyLarge: _poppinsFont.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF1C1B1F),
    ),
    bodyMedium: _poppinsFont.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF1C1B1F),
    ),
    bodySmall: _poppinsFont.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF1C1B1F),
    ),
    labelLarge: _poppinsFont.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF1C1B1F),
    ),
    labelMedium: _poppinsFont.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF1C1B1F),
    ),
    labelSmall: _poppinsFont.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF1C1B1F),
    ),
  ),

  // SnackBar Theme
  snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF3D4B3F),
    contentTextStyle: GoogleFonts.poppins(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    actionTextColor: Colors.white,
    closeIconColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    behavior: SnackBarBehavior.floating,
    elevation: 6,
  ),

  // Chip Theme
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey[100],
    selectedColor: const Color(0xFF3D4B3F).withValues(alpha: 0.1),
    checkmarkColor: const Color(0xFF3D4B3F),
    deleteIconColor: Colors.grey[600],
    labelStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF1C1B1F),
    ),
    secondaryLabelStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF3D4B3F),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),

  // Progress Indicator Theme
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Color(0xFF3D4B3F),
    linearTrackColor: Colors.grey,
    circularTrackColor: Colors.grey,
  ),

  // Switch Theme
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF3D4B3F);
      }
      return Colors.white;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF3D4B3F).withValues(alpha: 0.5);
      }
      return Colors.grey;
    }),
  ),

  // Checkbox Theme
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF3D4B3F);
      }
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(Colors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  ),

  // Radio Theme
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF3D4B3F);
      }
      return Colors.grey;
    }),
  ),

  // Tab Bar Theme
  tabBarTheme: TabBarTheme(
    labelColor: const Color(0xFF3D4B3F),
    unselectedLabelColor: Colors.grey[600],
    indicatorColor: const Color(0xFF3D4B3F),
    indicatorSize: TabBarIndicatorSize.tab,
    labelStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    unselectedLabelStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
  ),

  // Divider Theme
  dividerTheme: const DividerThemeData(
    color: Color(0xFFE0E0E0),
    thickness: 1,
    space: 16,
  ),

  // List Tile Theme
  listTileTheme: ListTileThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    tileColor: Colors.white,
    selectedTileColor: const Color(0xFF3D4B3F).withValues(alpha: 0.1),
    textColor: const Color(0xFF1C1B1F),
    iconColor: const Color(0xFF4F4F4F),
  ),

  // Expansion Tile Theme
  expansionTileTheme: ExpansionTileThemeData(
    backgroundColor: Colors.white,
    collapsedBackgroundColor: Colors.white,
    textColor: const Color(0xFF1C1B1F),
    collapsedTextColor: const Color(0xFF1C1B1F),
    iconColor: const Color(0xFF4F4F4F),
    collapsedIconColor: const Color(0xFF4F4F4F),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    collapsedShape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),

  // Data Table Theme
  dataTableTheme: DataTableThemeData(
    headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
    dataRowColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF3D4B3F).withValues(alpha: 0.1);
      }
      return Colors.white;
    }),
    headingTextStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1C1B1F),
    ),
    dataTextStyle: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF1C1B1F),
    ),
    dividerThickness: 1,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE0E0E0)),
    ),
  ),

  // Tooltip Theme
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: const Color(0xFF3D4B3F),
      borderRadius: BorderRadius.circular(8),
    ),
    textStyle: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Colors.white,
    ),
  ),

  // Bottom Navigation Bar Theme
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: const Color(0xFF3D4B3F),
    unselectedItemColor: Colors.grey[600],
    selectedLabelStyle: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    unselectedLabelStyle: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    elevation: 8,
    type: BottomNavigationBarType.fixed,
  ),

  // Scaffold Background Color
  scaffoldBackgroundColor: const Color(0xFFFAFAFA),

  // Canvas Color
  canvasColor: Colors.white,
);

// final ThemeData themeConfig1 = ThemeData(
//   colorScheme: ColorScheme.fromSeed(
//     seedColor: const Color(0xFF3D4B3F),
//   ),
//   floatingActionButtonTheme: const FloatingActionButtonThemeData(
//     backgroundColor: Color(0xFF3D4B3F),
//   ),
//   elevatedButtonTheme: ElevatedButtonThemeData(
//     style: ElevatedButton.styleFrom(
//         backgroundColor: const Color(0xff00210d),
//         foregroundColor: const Color(0xFFFFFFFF),
//         iconColor: const Color(0xFFFFFFFF),
//         padding: const EdgeInsets.symmetric(horizontal: 30)),
//   ),
//   dropdownMenuTheme: DropdownMenuThemeData(
//     menuStyle: MenuStyle(),
//   ),
//   inputDecorationTheme: InputDecorationTheme(
//     fillColor: Colors.white,
//     filled: true,
//     contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
//     hintStyle: GoogleFonts.poppins(
//       fontSize: 15,
//       color: const Color(0xFF8D8D8D),
//     ),
//     disabledBorder: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(20),
//       borderSide: const BorderSide(
//         color: Colors.blueGrey,
//         width: 1,
//       ),
//     ),
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(20),
//       borderSide: BorderSide(
//         color: const Color(0xFF3D4B3F),
//       ),
//     ),
//     prefixIconColor: const Color(0xFF4F4F4F),
//   ),
//   fontFamily: GoogleFonts.poppins.toString(),
//   textTheme: TextTheme(
//     bodyLarge: GoogleFonts.poppins(
//       fontSize: 15,
//       color: const Color(0xFF4F4F4F),
//     ),
//     labelLarge: GoogleFonts.poppins(
//       fontSize: 18,
//       color: const Color(0xFF8D8D8D),
//     ),
//   ),
//   snackBarTheme: SnackBarThemeData(
//     closeIconColor: Color(0xff00210d),
//     backgroundColor: Color(0xffb2f1bf),
//     contentTextStyle: TextStyle(
//       color: Color(0xff00210d),
//     ),
//   ),
// );
