import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final _poppinsFont = GoogleFonts.poppins();

final ThemeData themeConfig = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF3D4B3F), // Primary color
  ),

  // Floating Action Button Theme
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF3D4B3F), // Dark green
    foregroundColor: Colors.white, // White icon
  ),

  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3D4B3F),
      // Dark green
      foregroundColor: Colors.white,
      // White text
      iconColor: Colors.white,
      // White icon
      padding: const EdgeInsets.all(25),
      textStyle: GoogleFonts.poppins(
        fontSize: 15,
        color: const Color(0xFF8D8D8D), // Light gray hint text
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Rounded corners
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    fillColor: Colors.white,
    filled: true,
    contentPadding: const EdgeInsets.all(20),
    hintStyle: GoogleFonts.poppins(
      fontSize: 15,
      color: const Color(0xFF8D8D8D), // Light gray hint text
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(
        color: const Color(0xFF3D4B3F),
        width: 1,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(
        color: Colors.blueGrey,
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(
        color: Color(0xFF3D4B3F), // Dark green border
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(
        color: Color(0xFF6B8E4E), // Lighter green border
        width: 2,
      ),
    ),
    prefixIconColor: const Color(0xFF4F4F4F), // Dark gray icon
  ),

  // Dropdown Menu Theme
  dropdownMenuTheme: DropdownMenuThemeData(
    menuStyle: MenuStyle(
      backgroundColor: WidgetStateProperty.all(Colors.white),
      // White background
      elevation: WidgetStateProperty.all(4),
      // Add shadow
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  ),

  // Font and Text Theme
  fontFamily: _poppinsFont.fontFamily,
  textTheme: TextTheme(
    bodyLarge: _poppinsFont.copyWith(
      fontSize: 15,
      color: const Color(0xFF4F4F4F), // Dark gray text
    ),
    labelLarge: _poppinsFont.copyWith(
      fontSize: 18,
      color: const Color(0xFF8D8D8D), // Light gray text
    ),
    titleLarge: _poppinsFont.copyWith(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF3D4B3F), // Dark green text
    ),
  ),

  // SnackBar Theme
  snackBarTheme: SnackBarThemeData(
    closeIconColor: const Color(0xFF3D4B3F), // Dark green close icon
    backgroundColor: const Color(0xFFE0F7E9), // Light green background
    contentTextStyle: GoogleFonts.poppins(
      color: const Color(0xFF3D4B3F), // Dark green text
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Rounded corners
    ),
  ),
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
