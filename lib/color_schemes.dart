import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

var lightColorSchemeTiber = FlexThemeData.light(
  colors: const FlexSchemeColor(
    primary: Color.fromARGB(255, 178, 28, 28),
    secondary: Color.fromARGB(255, 178, 28, 28),
  ),
  appBarStyle: FlexAppBarStyle.primary,
  appBarElevation: 4.0,
  bottomAppBarElevation: 8.0,
  tabBarStyle: FlexTabBarStyle.forAppBar,
  subThemesData: const FlexSubThemesData(
    interactionEffects: false,
    tintedDisabledControls: false,
    blendOnColors: false,
    blendTextTheme: true,
    useTextTheme: true,
    adaptiveRemoveElevationTint: FlexAdaptive.all(),
    adaptiveElevationShadowsBack: FlexAdaptive.all(),
    adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
    defaultRadius: 15.0,
    elevatedButtonSchemeColor: SchemeColor.onPrimary,
    elevatedButtonSecondarySchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    inputDecoratorUnfocusedHasBorder: false,
    chipSchemeColor: SchemeColor.background,
    chipRadius: 20.0,
    popupMenuRadius: 10.0,
    popupMenuElevation: 8.0,
    alignedDropdown: true,
    tooltipRadius: 4,
    dialogElevation: 24.0,
    useInputDecoratorThemeInDialogs: true,
    datePickerHeaderBackgroundSchemeColor: SchemeColor.primary,
    snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
    appBarScrolledUnderElevation: 4.0,
    tabBarIndicatorSize: TabBarIndicatorSize.tab,
    tabBarIndicatorWeight: 2,
    tabBarIndicatorTopRadius: 0,
    tabBarDividerColor: Color(0x00000000),
    drawerElevation: 16.0,
    drawerWidth: 304.0,
    bottomSheetElevation: 10.0,
    bottomSheetModalElevation: 20.0,
    bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
    bottomNavigationBarSelectedIconSchemeColor: SchemeColor.primary,
    bottomNavigationBarElevation: 8.0,
    menuElevation: 8.0,
    menuBarRadius: 0.0,
    menuBarElevation: 1.0,
    navigationBarSelectedLabelSchemeColor: SchemeColor.onSurface,
    navigationBarUnselectedLabelSchemeColor: SchemeColor.onSurface,
    navigationBarMutedUnselectedLabel: false,
    navigationBarSelectedIconSchemeColor: SchemeColor.onSurface,
    navigationBarUnselectedIconSchemeColor: SchemeColor.onSurface,
    navigationBarMutedUnselectedIcon: false,
    navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
    navigationBarIndicatorOpacity: 1.00,
    navigationRailSelectedLabelSchemeColor: SchemeColor.onSurface,
    navigationRailUnselectedLabelSchemeColor: SchemeColor.onSurface,
    navigationRailSelectedIconSchemeColor: SchemeColor.onSurface,
    navigationRailUnselectedIconSchemeColor: SchemeColor.onSurface,
    navigationRailIndicatorSchemeColor: SchemeColor.secondary,
  ),
  useMaterial3ErrorColors: true,
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
);

var darkColorSchemeTiber = FlexThemeData.dark(
  scheme: FlexScheme.redM3,
  appBarStyle: FlexAppBarStyle.material,
  appBarElevation: 4.0,
  bottomAppBarElevation: 8.0,
  tabBarStyle: FlexTabBarStyle.forAppBar,
  subThemesData: const FlexSubThemesData(
    interactionEffects: false,
    tintedDisabledControls: false,
    blendOnColors: false,
    useTextTheme: true,
    adaptiveElevationShadowsBack: FlexAdaptive.all(),
    adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
    defaultRadius: 15.0,
    elevatedButtonSchemeColor: SchemeColor.onPrimary,
    elevatedButtonSecondarySchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    inputDecoratorUnfocusedHasBorder: false,
    chipSchemeColor: SchemeColor.background,
    chipRadius: 20.0,
    popupMenuRadius: 10.0,
    popupMenuElevation: 8.0,
    alignedDropdown: true,
    tooltipRadius: 4,
    dialogElevation: 24.0,
    useInputDecoratorThemeInDialogs: true,
    datePickerHeaderBackgroundSchemeColor: SchemeColor.primary,
    snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
    appBarScrolledUnderElevation: 4.0,
    tabBarIndicatorSize: TabBarIndicatorSize.tab,
    tabBarIndicatorWeight: 2,
    tabBarIndicatorTopRadius: 0,
    tabBarDividerColor: Color(0x00000000),
    drawerElevation: 16.0,
    drawerWidth: 304.0,
    bottomSheetElevation: 10.0,
    bottomSheetModalElevation: 20.0,
    bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
    bottomNavigationBarSelectedIconSchemeColor: SchemeColor.primary,
    bottomNavigationBarElevation: 8.0,
    menuElevation: 8.0,
    menuBarRadius: 0.0,
    menuBarElevation: 1.0,
    navigationBarSelectedLabelSchemeColor: SchemeColor.onSurface,
    navigationBarUnselectedLabelSchemeColor: SchemeColor.onSurface,
    navigationBarMutedUnselectedLabel: false,
    navigationBarSelectedIconSchemeColor: SchemeColor.onSurface,
    navigationBarUnselectedIconSchemeColor: SchemeColor.onSurface,
    navigationBarMutedUnselectedIcon: false,
    navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
    navigationBarIndicatorOpacity: 1.00,
    navigationRailSelectedLabelSchemeColor: SchemeColor.onSurface,
    navigationRailUnselectedLabelSchemeColor: SchemeColor.onSurface,
    navigationRailSelectedIconSchemeColor: SchemeColor.onSurface,
    navigationRailUnselectedIconSchemeColor: SchemeColor.onSurface,
    navigationRailIndicatorSchemeColor: SchemeColor.secondary,
  ),
  useMaterial3ErrorColors: true,
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
);

var lightColorSchemeDelta = FlexThemeData.light(
  colors: const FlexSchemeColor(
    primary: Color(0xFF00296B), 
    secondary: Color(0xFF00296B),
  ),
  appBarStyle: FlexAppBarStyle.primary,
  appBarElevation: 4.0,
  bottomAppBarElevation: 8.0,
  tabBarStyle: FlexTabBarStyle.forAppBar,
  subThemesData: const FlexSubThemesData(
    interactionEffects: false,
    tintedDisabledControls: false,
    blendOnColors: false,
    blendTextTheme: true,
    useTextTheme: true,
    adaptiveRemoveElevationTint: FlexAdaptive.all(),
    adaptiveElevationShadowsBack: FlexAdaptive.all(),
    adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
    defaultRadius: 15.0,
    elevatedButtonSchemeColor: SchemeColor.onPrimary,
    elevatedButtonSecondarySchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    inputDecoratorUnfocusedHasBorder: false,
    chipSchemeColor: SchemeColor.background,
    chipRadius: 20.0,
    popupMenuRadius: 10.0,
    popupMenuElevation: 8.0,
    alignedDropdown: true,
    tooltipRadius: 4,
    dialogElevation: 24.0,
    useInputDecoratorThemeInDialogs: true,
    datePickerHeaderBackgroundSchemeColor: SchemeColor.primary,
    snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
    appBarScrolledUnderElevation: 4.0,
    tabBarIndicatorSize: TabBarIndicatorSize.tab,
    tabBarIndicatorWeight: 2,
    tabBarIndicatorTopRadius: 0,
    tabBarDividerColor: Color(0x00000000),
    drawerElevation: 16.0,
    drawerWidth: 304.0,
    bottomSheetElevation: 10.0,
    bottomSheetModalElevation: 20.0,
    bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
    bottomNavigationBarSelectedIconSchemeColor: SchemeColor.primary,
    bottomNavigationBarElevation: 8.0,
    menuElevation: 8.0,
    menuBarRadius: 0.0,
    menuBarElevation: 1.0,
    navigationBarSelectedLabelSchemeColor: SchemeColor.onSurface,
    navigationBarUnselectedLabelSchemeColor: SchemeColor.onSurface,
    navigationBarMutedUnselectedLabel: false,
    navigationBarSelectedIconSchemeColor: SchemeColor.onSurface,
    navigationBarUnselectedIconSchemeColor: SchemeColor.onSurface,
    navigationBarMutedUnselectedIcon: false,
    navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
    navigationBarIndicatorOpacity: 1.00,
    navigationRailSelectedLabelSchemeColor: SchemeColor.onSurface,
    navigationRailUnselectedLabelSchemeColor: SchemeColor.onSurface,
    navigationRailSelectedIconSchemeColor: SchemeColor.onSurface,
    navigationRailUnselectedIconSchemeColor: SchemeColor.onSurface,
    navigationRailIndicatorSchemeColor: SchemeColor.secondary,
  ),
  useMaterial3ErrorColors: true,
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
);

var darkColorSchemeDelta = FlexThemeData.dark(
  colors: const FlexSchemeColor(
    primary: Color(0xFF00296B),
    secondary: Color(0xFF00296B),
  ),
  appBarStyle: FlexAppBarStyle.material,
  appBarElevation: 4.0,
  bottomAppBarElevation: 8.0,
  tabBarStyle: FlexTabBarStyle.forAppBar,
  subThemesData: const FlexSubThemesData(
    interactionEffects: false,
    tintedDisabledControls: false,
    blendOnColors: false,
    useTextTheme: true,
    adaptiveElevationShadowsBack: FlexAdaptive.all(),
    adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
    defaultRadius: 15.0,
    elevatedButtonSchemeColor: SchemeColor.onPrimary,
    elevatedButtonSecondarySchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    inputDecoratorUnfocusedHasBorder: false,
    chipSchemeColor: SchemeColor.background,
    chipRadius: 20.0,
    popupMenuRadius: 10.0,
    popupMenuElevation: 8.0,
    alignedDropdown: true,
    tooltipRadius: 4,
    dialogElevation: 24.0,
    useInputDecoratorThemeInDialogs: true,
    datePickerHeaderBackgroundSchemeColor: SchemeColor.primary,
    snackBarBackgroundSchemeColor: SchemeColor.inverseSurface,
    appBarScrolledUnderElevation: 4.0,
    tabBarIndicatorSize: TabBarIndicatorSize.tab,
    tabBarIndicatorWeight: 2,
    tabBarIndicatorTopRadius: 0,
    tabBarDividerColor: Color(0x00000000),
    drawerElevation: 16.0,
    drawerWidth: 304.0,
    bottomSheetElevation: 10.0,
    bottomSheetModalElevation: 20.0,
    bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
    bottomNavigationBarSelectedIconSchemeColor: SchemeColor.primary,
    bottomNavigationBarElevation: 8.0,
    menuElevation: 8.0,
    menuBarRadius: 0.0,
    menuBarElevation: 1.0,
    navigationBarSelectedLabelSchemeColor: SchemeColor.onSurface,
    navigationBarUnselectedLabelSchemeColor: SchemeColor.onSurface,
    navigationBarMutedUnselectedLabel: false,
    navigationBarSelectedIconSchemeColor: SchemeColor.onSurface,
    navigationBarUnselectedIconSchemeColor: SchemeColor.onSurface,
    navigationBarMutedUnselectedIcon: false,
    navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
    navigationBarIndicatorOpacity: 1.00,
    navigationRailSelectedLabelSchemeColor: SchemeColor.onSurface,
    navigationRailUnselectedLabelSchemeColor: SchemeColor.onSurface,
    navigationRailSelectedIconSchemeColor: SchemeColor.onSurface,
    navigationRailUnselectedIconSchemeColor: SchemeColor.onSurface,
    navigationRailIndicatorSchemeColor: SchemeColor.secondary,
  ),
  useMaterial3ErrorColors: true,
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
);
