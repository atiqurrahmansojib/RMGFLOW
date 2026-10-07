import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

export 'app_colors.dart';
export 'app_tokens.dart';

/// Document 35: one design-system entry point — colours/typography defined
/// once here, not per screen. "Indigo & Thread" system: indigo primary, teal
/// secondary, coral tertiary, marigold accent (see app_colors.dart).
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(_lightScheme);
  static ThemeData get dark => _build(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.indigo,
    onPrimary: Colors.white,
    primaryContainer: AppColors.indigoSoft,
    onPrimaryContainer: Color(0xFF14166B),
    primaryFixed: AppColors.indigoSoft,
    primaryFixedDim: Color(0xFFC3C5F6),
    onPrimaryFixed: Color(0xFF14166B),
    onPrimaryFixedVariant: AppColors.indigoDeep,
    secondary: AppColors.teal,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.tealSoft,
    onSecondaryContainer: Color(0xFF00382F),
    tertiary: AppColors.coral,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.coralSoft,
    onTertiaryContainer: Color(0xFF5C0E15),
    error: AppColors.danger,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF5F1111),
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.inkMuted,
    surfaceDim: Color(0xFFDCDEEA),
    surfaceBright: AppColors.surface,
    surfaceContainerLowest: AppColors.surface,
    surfaceContainerLow: AppColors.canvas,
    surfaceContainer: AppColors.surfaceLow,
    surfaceContainerHigh: Color(0xFFE8EAF4),
    surfaceContainerHighest: Color(0xFFE1E3EF),
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineSoft,
    shadow: Color(0xFF1A1C4A),
    scrim: Colors.black,
    inverseSurface: Color(0xFF2B2D42),
    onInverseSurface: Color(0xFFF1F1FA),
    inversePrimary: AppColors.indigoNight,
    surfaceTint: AppColors.indigo,
  );

  static const ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.indigoNight,
    onPrimary: Color(0xFF14166B),
    primaryContainer: Color(0xFF30349A),
    onPrimaryContainer: Color(0xFFE3E4FB),
    primaryFixed: AppColors.indigoSoft,
    primaryFixedDim: Color(0xFFC3C5F6),
    onPrimaryFixed: Color(0xFF14166B),
    onPrimaryFixedVariant: AppColors.indigoDeep,
    secondary: AppColors.tealNight,
    onSecondary: Color(0xFF00382F),
    secondaryContainer: Color(0xFF005148),
    onSecondaryContainer: AppColors.tealSoft,
    tertiary: AppColors.coralNight,
    onTertiary: Color(0xFF5C0E15),
    tertiaryContainer: Color(0xFF8C2730),
    onTertiaryContainer: AppColors.coralSoft,
    error: Color(0xFFFF8A80),
    onError: Color(0xFF5F1111),
    errorContainer: Color(0xFF8C1D1D),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: AppColors.surfaceNight,
    onSurface: AppColors.inkNight,
    onSurfaceVariant: AppColors.inkNightMuted,
    surfaceDim: AppColors.canvasNight,
    surfaceBright: Color(0xFF34375A),
    surfaceContainerLowest: Color(0xFF0B0C18),
    surfaceContainerLow: AppColors.canvasNight,
    surfaceContainer: Color(0xFF1D1F35),
    surfaceContainerHigh: AppColors.surfaceNightHigh,
    surfaceContainerHighest: Color(0xFF2C2F4C),
    outline: Color(0xFF5A5E80),
    outlineVariant: AppColors.outlineNight,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.inkNight,
    onInverseSurface: Color(0xFF1F2135),
    inversePrimary: AppColors.indigo,
    surfaceTint: AppColors.indigoNight,
  );

  /// Roboto (bundled on Android) with a tuned scale: tight, heavy display &
  /// headline weights for numbers and titles; relaxed body leading for long
  /// remarks/notes; medium-weight labels for buttons/chips.
  static TextTheme _textTheme(ColorScheme s) {
    final base = Typography.material2021(platform: TargetPlatform.android).black;
    TextStyle t(TextStyle? b, double size, FontWeight w, double height, double ls) =>
        b!.copyWith(fontSize: size, fontWeight: w, height: height, letterSpacing: ls);
    return TextTheme(
      displayLarge: t(base.displayLarge, 52, FontWeight.w800, 1.08, -1.2),
      displayMedium: t(base.displayMedium, 42, FontWeight.w800, 1.1, -1.0),
      displaySmall: t(base.displaySmall, 34, FontWeight.w700, 1.12, -0.6),
      headlineLarge: t(base.headlineLarge, 30, FontWeight.w700, 1.15, -0.5),
      headlineMedium: t(base.headlineMedium, 26, FontWeight.w700, 1.2, -0.4),
      headlineSmall: t(base.headlineSmall, 22, FontWeight.w700, 1.25, -0.2),
      titleLarge: t(base.titleLarge, 20, FontWeight.w700, 1.3, -0.1),
      titleMedium: t(base.titleMedium, 16, FontWeight.w600, 1.35, 0),
      titleSmall: t(base.titleSmall, 14, FontWeight.w600, 1.35, 0.05),
      bodyLarge: t(base.bodyLarge, 16, FontWeight.w400, 1.5, 0.1),
      bodyMedium: t(base.bodyMedium, 14, FontWeight.w400, 1.45, 0.1),
      bodySmall: t(base.bodySmall, 12, FontWeight.w400, 1.4, 0.2),
      labelLarge: t(base.labelLarge, 14, FontWeight.w600, 1.2, 0.2),
      labelMedium: t(base.labelMedium, 12, FontWeight.w600, 1.2, 0.3),
      labelSmall: t(base.labelSmall, 11, FontWeight.w600, 1.2, 0.4),
    ).apply(bodyColor: s.onSurface, displayColor: s.onSurface);
  }

  static ThemeData _build(ColorScheme s) {
    final isDark = s.brightness == Brightness.dark;
    final text = _textTheme(s);
    final scaffold = isDark ? AppColors.canvasNight : AppColors.canvas;
    const pill = StadiumBorder();
    const buttonPadding = EdgeInsets.symmetric(horizontal: 22, vertical: 14);
    const buttonSize = Size(64, 48);

    OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: AppRadius.input, borderSide: BorderSide(color: c, width: w));

    return ThemeData(
      useMaterial3: true,
      colorScheme: s,
      brightness: s.brightness,
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,
      textTheme: text,
      primaryTextTheme: text,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: s.outlineVariant, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: s.onSurfaceVariant, size: 22),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      }),

      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: s.onSurface,
        surfaceTintColor: s.primary,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: s.shadow.withValues(alpha: 0.15),
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: s.onSurface),
        actionsIconTheme: IconThemeData(color: s.onSurfaceVariant),
      ),

      cardTheme: CardThemeData(
        color: s.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: s.shadow.withValues(alpha: isDark ? 0.5 : 0.12),
        elevation: isDark ? 0 : 1.5,
        margin: const EdgeInsets.symmetric(vertical: 6),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: isDark ? s.outlineVariant : s.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? s.surfaceContainerHigh : AppColors.surfaceLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: inputBorder(Colors.transparent),
        enabledBorder: inputBorder(Colors.transparent),
        focusedBorder: inputBorder(s.primary, 1.8),
        errorBorder: inputBorder(s.error.withValues(alpha: 0.7)),
        focusedErrorBorder: inputBorder(s.error, 1.8),
        disabledBorder: inputBorder(Colors.transparent),
        labelStyle: text.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) => text.bodyMedium!.copyWith(
              color: states.contains(WidgetState.error)
                  ? s.error
                  : states.contains(WidgetState.focused)
                      ? s.primary
                      : s.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            )),
        hintStyle: text.bodyMedium?.copyWith(color: s.onSurfaceVariant.withValues(alpha: 0.7)),
        helperStyle: text.bodySmall?.copyWith(color: s.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(color: s.error, fontWeight: FontWeight.w500),
        prefixIconColor: s.onSurfaceVariant,
        suffixIconColor: s.onSurfaceVariant,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: pill,
          padding: buttonPadding,
          minimumSize: buttonSize,
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: pill,
          padding: buttonPadding,
          minimumSize: buttonSize,
          textStyle: text.labelLarge,
          backgroundColor: s.primary,
          foregroundColor: s.onPrimary,
          elevation: 2,
          shadowColor: s.primary.withValues(alpha: 0.35),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: pill,
          padding: buttonPadding,
          minimumSize: buttonSize,
          textStyle: text.labelLarge,
          foregroundColor: s.primary,
          side: BorderSide(color: s.outline),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: pill,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: text.labelLarge,
          foregroundColor: s.primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: s.onSurfaceVariant)),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: pill,
          selectedBackgroundColor: s.primaryContainer,
          selectedForegroundColor: s.onPrimaryContainer,
          textStyle: text.labelMedium,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: s.primary,
        foregroundColor: s.onPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
        extendedTextStyle: text.labelLarge,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
      ),

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: s.outlineVariant),
        backgroundColor: isDark ? s.surfaceContainerHigh : s.surface,
        selectedColor: s.primaryContainer,
        secondarySelectedColor: s.primaryContainer,
        disabledColor: s.surfaceContainerHighest,
        checkmarkColor: s.onPrimaryContainer,
        labelStyle: text.labelMedium?.copyWith(color: s.onSurface),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: s.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        iconTheme: IconThemeData(color: s.onSurfaceVariant, size: 16),
        showCheckmark: true,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: isDark ? s.surface : Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: s.shadow,
        indicatorColor: s.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected) ? s.onPrimaryContainer : s.onSurfaceVariant,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => text.labelSmall?.copyWith(
              color: states.contains(WidgetState.selected) ? s.primary : s.onSurfaceVariant,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            )),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scaffold,
        indicatorColor: s.primaryContainer,
        selectedIconTheme: IconThemeData(color: s.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: s.onSurfaceVariant),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.xl)),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: s.primary,
        unselectedLabelColor: s.onSurfaceVariant,
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        indicatorColor: s.primary,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: s.primary, width: 3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
        dividerColor: s.outlineVariant,
        tabAlignment: TabAlignment.start,
        overlayColor: WidgetStatePropertyAll(s.primary.withValues(alpha: 0.06)),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 10,
        horizontalTitleGap: 14,
        iconColor: s.onSurfaceVariant,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        leadingAndTrailingTextStyle: text.labelMedium?.copyWith(color: s.onSurfaceVariant),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.input),
        selectedColor: s.primary,
        selectedTileColor: s.primaryContainer.withValues(alpha: 0.5),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        collapsedShape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
        iconColor: s.primary,
        collapsedIconColor: s.onSurfaceVariant,
        textColor: s.onSurface,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: s.shadow.withValues(alpha: 0.3),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl))),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: s.onSurfaceVariant),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surface,
        modalBackgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 8,
        showDragHandle: true,
        dragHandleColor: s.outline,
        dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: s.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: s.onInverseSurface),
        actionTextColor: isDark ? AppColors.indigo : AppColors.indigoNight,
        elevation: 4,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.input),
        showCloseIcon: false,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: s.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: s.shadow.withValues(alpha: 0.2),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.input),
        textStyle: text.bodyMedium,
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(s.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: AppRadius.input)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: text.bodyLarge,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(s.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: AppRadius.input)),
        ),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(isDark ? s.surfaceContainerHigh : s.primaryContainer.withValues(alpha: 0.45)),
        headingTextStyle: text.labelLarge?.copyWith(color: isDark ? s.onSurface : s.onPrimaryContainer),
        dataTextStyle: text.bodyMedium,
        dividerThickness: 0.6,
        headingRowHeight: 46,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 56,
        columnSpacing: 24,
        horizontalMargin: 16,
        decoration: BoxDecoration(borderRadius: AppRadius.input, border: Border.all(color: s.outlineVariant)),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: s.primary,
        linearTrackColor: s.primaryContainer,
        circularTrackColor: s.primaryContainer.withValues(alpha: 0.5),
        linearMinHeight: 6,
        borderRadius: const BorderRadius.all(Radius.circular(3)),
        refreshBackgroundColor: s.surface,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: s.primary,
        inactiveTrackColor: s.primaryContainer,
        thumbColor: s.primary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? s.onPrimary : s.outline),
        trackColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? s.primary : s.surfaceContainerHighest),
        trackOutlineColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? Colors.transparent : s.outline),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
        side: BorderSide(color: s.outline, width: 1.6),
      ),
      badgeTheme: BadgeThemeData(backgroundColor: s.tertiary, textColor: s.onTertiary),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: s.inverseSurface, borderRadius: AppRadius.input),
        textStyle: text.bodySmall?.copyWith(color: s.onInverseSurface),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl))),
        headerBackgroundColor: s.primary,
        headerForegroundColor: s.onPrimary,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: s.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl))),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(isDark ? s.surfaceContainerHigh : Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        side: WidgetStatePropertyAll(BorderSide(color: s.outlineVariant)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
        textStyle: WidgetStatePropertyAll(text.bodyLarge),
        hintStyle: WidgetStatePropertyAll(text.bodyLarge?.copyWith(color: s.onSurfaceVariant)),
      ),
    );
  }
}
