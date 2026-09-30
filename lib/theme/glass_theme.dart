/// ═══════════════════════════════════════════════════════════════════
///  MediaRescue Admin — Liquid Glass design system
/// ═══════════════════════════════════════════════════════════════════
///
/// Everything visual in this app is built from the pieces below: one
/// palette, one set of [LiquidGlassStyle] recipes, and a small family of
/// iOS-flavoured glass widgets (cards, chips, fields, selects, toasts).
///
/// Two grades of glass are used on purpose:
///
///  • **Lens glass** ([GlassCard]) — a real [LiquidGlassLens]: it refracts
///    the backdrop through the shader. Used for the few, large, floating
///    surfaces (stat cards, chart cards, form cards, dialogs, sheets).
///  • **Lite glass** ([GlassLiteSurface], [GlassChip], [GlassField], …) —
///    the shader-free `LiquidGlassLite` material (frost + tint + lit rim).
///    Used for the many, repeated surfaces (list rows, inputs, toolbar
///    buttons) where one backdrop read each would be wasteful.
///
/// Both are the same package, the same vocabulary and the same look;
/// the second is simply the one that scales to a long list.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

// ─────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────

/// The app's colour set, tuned for a dark, saturated, iOS-like backdrop.
class GlassPalette {
  GlassPalette._();

  // Accents (kept from the original Material 3 design so charts and
  // status dots stay recognisable).
  static const Color indigo = Color(0xFF6366F1);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color pink = Color(0xFFEC4899);

  // iOS system accents used for the glass call-to-actions.
  static const Color iosBlue = Color(0xFF0A84FF);
  static const Color iosGreen = Color(0xFF34C759);
  static const Color iosRed = Color(0xFFFF453A);
  static const Color iosGray = Color(0xFF8E8E93);

  // Text on glass.
  static const Color textPrimary = Color(0xFFF7F8FC);
  static const Color textSecondary = Color(0xC7FFFFFF);
  static const Color textTertiary = Color(0x8AFFFFFF);

  // The page behind the glass.
  static const Color backdropTop = Color(0xFF07080F);
  static const Color backdropMid = Color(0xFF111427);
  static const Color backdropBottom = Color(0xFF080A13);

  static const Color orbIndigo = Color(0x736366F1);
  static const Color orbViolet = Color(0x598B5CF6);
  static const Color orbCyan = Color(0x4006B6D4);
  static const Color orbEmerald = Color(0x3310B981);

  static const Color divider = Color(0x1FFFFFFF);
}

/// Fill tints used across the glass surfaces.
class GlassTints {
  GlassTints._();

  /// Standard card fill over a dark page — a light veil, not a bright chip.
  static const Color card = Color(0x1AFFFFFF);

  /// A slightly stronger fill, for surfaces that must read above others.
  static const Color cardStrong = Color(0x24FFFFFF);

  /// Bars and rails.
  static const Color bar = Color(0x1CFFFFFF);

  /// Small elements: chips, icon buttons.
  static const Color chip = Color(0x1FFFFFFF);

  /// Inputs — a dark well rather than a light one.
  static const Color field = Color(0x26000000);

  /// Tints for the selected / accented states.
  static const Color selected = Color(0x3D6366F1);
  static const Color accentBlue = Color(0x660A84FF);
  static const Color accentRed = Color(0x66FF453A);
  static const Color accentGreen = Color(0x6634C759);
}


// ─────────────────────────────────────────────────────────────
// Styles
// ─────────────────────────────────────────────────────────────

/// The tuned [LiquidGlassStyle] recipes the whole app shares.
///
/// They are `static const` on purpose: a fresh `LiquidGlassStyle` every
/// build would make every lens repaint on each rebuild.
class GlassStyles {
  GlassStyles._();

  /// The iOS-style optical rim: an SDF-based edge light tinted by
  /// whatever sits behind the glass.
  static const OpticalBorder _rim = OpticalBorder(
    borderSaturation: 1.3,
    ambientIntensity: 1.0,
    borderSolidity: 0.35,
  );

  static const OpticalBorder _lightRim = OpticalBorder(
    borderSaturation: 1.15,
    ambientIntensity: 1.2,
    borderSolidity: 0.2,
  );

  /// Cards: an iOS squircle, a soft frost, and a contact shadow so the
  /// surface reads as *sitting in* the page instead of floating on it.
  static const LiquidGlassStyle card = LiquidGlassStyle(
    shape: LiquidGlassShape.squircle(
      cornerRadius: 26,
      clipQuality: LiquidGlassClipQuality.exact,
      borderWidth: 1.1,
      lightIntensity: 1.25,
      lightDirection: 80,
      borderType: _rim,
    ),
    appearance: LiquidGlassAppearance(
      color: GlassTints.card,
      // // blur: LiquidGlassBlur(sigmaX: 6, sigmaY: 6),
      // shadow: LiquidGlassShadow(blur: 5, opacity: 0.30, inset: 1),
    ),
    refraction: LiquidGlassRefraction(
      distortion: 0.10,
      distortionWidth: 30,
      chromaticAberration: 0.002,
    ),
  );

  /// Inset panels (a card inside a card): less frost, no shadow.
  static const LiquidGlassStyle panel = LiquidGlassStyle(
    shape: LiquidGlassShape.squircle(
      cornerRadius: 20,
      clipQuality: LiquidGlassClipQuality.exact,
      borderWidth: 1.0,
      lightIntensity: 1.1,
      lightDirection: 80,
      borderType: _lightRim,
    ),
    appearance: LiquidGlassAppearance(
      color: Color(0x14FFFFFF),
      // // blur: LiquidGlassBlur(sigmaX: 4, sigmaY: 4),
    ),
    refraction: LiquidGlassRefraction(
      distortion: 0.07,
      distortionWidth: 24,
      chromaticAberration: 0.002,
    ),
  );

  /// The app bar's own glass — lighter and gentler than a card.
  static const LiquidGlassStyle bar = LiquidGlassStyle(
    shape: LiquidGlassShape.continuousRoundedRectangle(
      cornerRadius: 28,
      borderWidth: 1.0,
      lightIntensity: 1.25,
      lightDirection: 80,
      borderType: _lightRim,
    ),
    appearance: LiquidGlassAppearance(
      color: GlassTints.bar,
      // // blur: LiquidGlassBlur(sigmaX: 8, sigmaY: 8),
      // shadow: LiquidGlassShadow( opacity: 0.28),
    ),
    refraction: LiquidGlassRefraction(
      distortion: 0.09,
      distortionWidth: 28,
      chromaticAberration: 0.002,
    ),
  );

  /// A rail entry on the wide-screen side navigation.
  static const LiquidGlassStyle railItem = LiquidGlassStyle(
    shape: LiquidGlassShape.squircle(
      cornerRadius: 20,
      clipQuality: LiquidGlassClipQuality.exact,
      borderWidth: 1.0,
      lightIntensity: 1.1,
      lightDirection: 80,
      borderType: _lightRim,
    ),
    appearance: LiquidGlassAppearance(
      color: Color(0x14FFFFFF),
      // // blur: LiquidGlassBlur(sigmaX: 4, sigmaY: 4),
    ),
    refraction: LiquidGlassRefraction(
      distortion: 0.07,
      distortionWidth: 22,
      chromaticAberration: 0.002,
    ),
  );

  /// The selected entry of the wide-screen rail.
  static const LiquidGlassStyle railItemSelected = LiquidGlassStyle(
    shape: LiquidGlassShape.squircle(
      cornerRadius: 20,
      clipQuality: LiquidGlassClipQuality.exact,
      borderWidth: 1.1,
      lightIntensity: 1.35,
      lightDirection: 80,
      borderType: _rim,
    ),
    appearance: LiquidGlassAppearance(
      color: GlassTints.selected,
      // blur: LiquidGlassBlur(sigmaX: 5, sigmaY: 5),
      // shadow: LiquidGlassShadow(blur: 4, opacity: 0.26, inset: 1),
    ),
    refraction: LiquidGlassRefraction(
      distortion: 0.10,
      distortionWidth: 24,
      chromaticAberration: 0.002,
    ),
  );

  /// The bottom navigation capsule.
  static const LiquidGlassStyle tabBar = LiquidGlassStyle(
    shape: LiquidGlassShape.continuousRoundedRectangle(
      cornerRadius: 32,
      borderWidth: 1.0,
      lightIntensity: 1.3,
      lightDirection: 80,
      borderType: _lightRim,
    ),
    appearance: LiquidGlassAppearance(
      color: Color(0x1CFFFFFF),
      // blur: LiquidGlassBlur(sigmaX: 6, sigmaY: 6),
      // shadow: LiquidGlassShadow(blur: 6, opacity: 0.30),
    ),
    refraction: LiquidGlassRefraction(
      distortion: 0.08,
      distortionWidth: 26,
      chromaticAberration: 0.002,
    ),
  );

  /// The tab bar's moving glass pill.
  static const LiquidGlassStyle pillGlass = LiquidGlassStyle(
    appearance: LiquidGlassAppearance(
      color: Color(0x1FFFFFFF),
      // blur: LiquidGlassBlur(sigmaX: 3, sigmaY: 3),
      // shadow: LiquidGlassShadow(blur: 3.5, opacity: 0.22, inset: 2),
    ),
    refraction: LiquidGlassRefraction(
      distortion: 0.14,
      distortionWidth: 22,
      chromaticAberration: 0.004,
    ),
  );

  /// The tab bar's settled (non-refracting) highlight.
  static const LiquidGlassStyle pillRest = LiquidGlassStyle(
    appearance: LiquidGlassAppearance(color: Color(0x2EFFFFFF)),
  );

  /// Shapes shared by the shader-free (lite) surfaces.
  static const LiquidGlassShape liteCardShape =
      LiquidGlassShape.continuousRoundedRectangle(
    cornerRadius: 22,
    borderWidth: 1.0,
    lightIntensity: 1.2,
    lightDirection: 80,
    borderType: _lightRim,
  );

  static const LiquidGlassShape liteRowShape =
      LiquidGlassShape.continuousRoundedRectangle(
    cornerRadius: 20,
    borderWidth: 0.9,
    lightIntensity: 1.1,
    lightDirection: 80,
    borderType: _lightRim,
  );

  static const LiquidGlassShape liteFieldShape =
      LiquidGlassShape.continuousRoundedRectangle(
    cornerRadius: 16,
    borderWidth: 0.9,
    lightIntensity: 1.05,
    lightDirection: 80,
    borderType: _lightRim,
  );

  static const LiquidGlassShape liteChipShape =
      LiquidGlassShape.continuousRoundedRectangle(
    cornerRadius: 14,
    borderWidth: 0.9,
    lightIntensity: 1.1,
    lightDirection: 80,
    borderType: _lightRim,
  );

  static const LiquidGlassShape liteCircleShape =
      LiquidGlassShape.continuousRoundedRectangle(
    cornerRadius: 999,
    borderWidth: 1.0,
    lightIntensity: 1.2,
    lightDirection: 80,
    borderType: _lightRim,
  );
}

/// The adaptivity verdict the shell hands down: the glass tint and the
/// content colour flip together with the background actually behind each
/// surface, animated.
const LiquidGlassAdaptivity kAdminAdaptivity = LiquidGlassAdaptivity(
  glassColorOnDark: Color(0x1F000000),
  contentColorOnDark: Color(0xFFF7F8FC),
  glassColorOnLight: Color(0x4DFFFFFF),
  contentColorOnLight: Color(0xFF101223),
  continuousGlassColor: true,
  duration: Duration(milliseconds: 260),
);

// ─────────────────────────────────────────────────────────────
// Backdrop
// ─────────────────────────────────────────────────────────────

/// The page every lens refracts: a deep gradient with soft colour orbs.
///
/// Deliberately **static** — an animating backdrop would force the glass
/// capture to re-read itself every frame, which is the one thing that
/// makes liquid glass expensive. Fills whatever box it is given, so use
/// it as a `StackFit.expand` child or wrap it in `SizedBox.expand`.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key, this.tint = GlassPalette.orbIndigo});

  /// Hue of the largest orb, so each screen can lean a different colour.
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            GlassPalette.backdropTop,
            GlassPalette.backdropMid,
            GlassPalette.backdropBottom,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          _orb(tint.withValues(alpha: 0.45), 430, top: -140, left: -110),
          _orb(GlassPalette.orbViolet, 340, top: 120, right: -130),
          _orb(GlassPalette.orbCyan, 380, bottom: -160, left: -40),
          _orb(GlassPalette.orbEmerald, 300, bottom: 40, right: -100),
        ],
      ),
    );
  }

  Widget _orb(
    Color color,
    double size, {
    double? top,
    double? left,
    double? right,
    double? bottom,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0)],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Surfaces
// ─────────────────────────────────────────────────────────────

/// A real liquid-glass card: one [LiquidGlassLens] wrapping [child].
///
/// This is the expensive, beautiful one — use it for the few large
/// surfaces on a screen (stat cards, chart cards, form sections). Give
/// it a `touch` and the card becomes a soft body under the finger.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.style,
    this.touch,
    this.visibility = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Overrides [GlassStyles.card].
  final LiquidGlassStyle? style;

  /// How the glass answers a finger — try
  /// `LiquidGlassTouch.flexing(LiquidGlassFlex.subtle())`.
  final LiquidGlassTouch? touch;

  final bool visibility;

  @override
  Widget build(BuildContext context) {
    Widget lens = LiquidGlassLens(
      style: style ?? GlassStyles.card,
      touch: touch,
      visibility: visibility,
      child: Padding(padding: padding, child: child),
    );
    if (margin != null) lens = Padding(padding: margin!, child: lens);
    return lens;
  }
}

/// The shader-free glass sheet — frost, tint and a lit rim, no
/// refraction and no capture. The one to repeat: list rows, inputs,
/// toolbar buttons, badges.
class GlassLiteSurface extends StatelessWidget {
  const GlassLiteSurface({
    super.key,
    required this.child,
    this.shape = GlassStyles.liteRowShape,
    this.color = GlassTints.card,
    this.blur = const LiquidGlassBlur(),
    this.pickup = LiquidGlassLitePickup.surface,
    this.padding,
    this.margin,
  });

  final Widget child;
  final LiquidGlassShape shape;
  final Color? color;
  final LiquidGlassBlur blur;
  final LiquidGlassLitePickup pickup;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    Widget surface = LiquidGlassLite(
      shape: shape,
      color: color,
      blur: blur,
      pickup: pickup,
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
    if (margin != null) {
      surface = Padding(padding: margin!, child: surface);
    }
    return surface;
  }
}


/// A small glass pill — status text, a filter token, a version badge.
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.iconColor,
    this.textColor = GlassPalette.textSecondary,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? iconColor;
  final Color textColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: iconColor ?? textColor),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );

    return GlassLiteSurface(
      shape: GlassStyles.liteChipShape,
      color: color ?? GlassTints.chip,
      padding: padding,
      child: onTap == null
          ? row
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap!.call();
              },
              child: row,
            ),
    );
  }
}

/// A round glass icon button, sized for toolbars and app-bar actions.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 40,
    this.iconSize = 20,
    this.color,
    this.background,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;

    Widget button = GlassLiteSurface(
      shape: GlassStyles.liteCircleShape,
      color: background ?? GlassTints.chip,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: (color ?? GlassPalette.textPrimary).withValues(
              alpha: enabled ? 1.0 : 0.35,
            ),
          ),
        ),
      ),
    );

    if (enabled) {
      button = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed!.call();
        },
        child: button,
      );
    }

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// A glass checkbox for the device list's multi-select mode.
class GlassCheckbox extends StatelessWidget {
  const GlassCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 26,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onChanged!.call(!value);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? GlassPalette.indigo.withValues(alpha: 0.85) : null,
          gradient: value
              ? null
              : const LinearGradient(
                  colors: [Color(0x26FFFFFF), Color(0x14FFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(size * 0.32),
          border: Border.all(
            color: value
                ? GlassPalette.indigo
                : Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: GlassPalette.indigo.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: -1,
                  ),
                ]
              : null,
        ),
        child: value
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// Inputs
// ─────────────────────────────────────────────────────────────

/// A text field sunk into a sheet of lite glass.
///
/// The label is drawn by us above the well (iOS caption style) rather
/// than as a Material floating label, which would fight the borderless
/// decoration the glass needs.
class GlassField extends StatelessWidget {
  const GlassField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final Widget field = TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofocus: autofocus,
      cursorColor: GlassPalette.indigo,
      style: const TextStyle(
        color: GlassPalette.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(
          color: GlassPalette.textTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  prefixIcon,
                  size: 18,
                  color: GlassPalette.textTertiary,
                ),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: EdgeInsets.symmetric(
          horizontal: prefixIcon == null ? 16 : 6,
          vertical: 14,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: GlassPalette.textTertiary,
              ),
            ),
          ),
        LiquidGlassLite(
          shape: GlassStyles.liteFieldShape,
          color: enabled
              ? GlassTints.field
              : GlassTints.field.withValues(alpha: 0.6),
          blur: const LiquidGlassBlur(),
          pickup: LiquidGlassLitePickup.surface,
          child: field,
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────
// Select — an iOS action sheet in glass
// ─────────────────────────────────────────────────────────────

/// One entry of a [GlassSelectField].
class GlassSelectOption<T> {
  const GlassSelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// A private payload so the sheet can tell "picked the *All* entry"
/// (value `null`) apart from "dismissed the sheet" (`null` result).
class GlassSelectResult<T> {
  const GlassSelectResult(this.value);

  final T? value;
}

/// A glass select: tapping it presents a frosted action sheet built from
/// `showLiquidGlassSheet`, the way iOS picks from a short list.
class GlassSelectField<T> extends StatelessWidget {
  const GlassSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.placeholder = 'All',
    this.icon,
  });

  final String label;
  final List<GlassSelectOption<T>> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String placeholder;
  final IconData? icon;

  String get _current {
    for (final GlassSelectOption<T> option in options) {
      if (option.value == value) return option.label;
    }
    return placeholder;
  }

  Future<void> _open(BuildContext context) async {
    HapticFeedback.selectionClick();

    final GlassSelectResult<T>? result =
        await showLiquidGlassSheet<GlassSelectResult<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: GlassPalette.textPrimary,
          ),
        ),
      ),
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.55,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GlassSelectTile(
                  label: placeholder,
                  selected: value == null,
                  onTap: () => Navigator.of(sheetContext)
                      .pop(GlassSelectResult<T>(null)),
                ),
                const Divider(
                  height: 1,
                  thickness: 0.6,
                  color: Color(0x1AFFFFFF),
                ),
                for (final GlassSelectOption<T> option in options)
                  _GlassSelectTile(
                    label: option.label,
                    selected: option.value == value,
                    onTap: () => Navigator.of(sheetContext)
                        .pop(GlassSelectResult<T>(option.value)),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) onChanged(result.value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: GlassPalette.textTertiary,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _open(context),
          child: GlassLiteSurface(
            shape: GlassStyles.liteFieldShape,
            color: GlassTints.field,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17, color: GlassPalette.textTertiary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      _current,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: value == null
                            ? GlassPalette.textTertiary
                            : GlassPalette.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: GlassPalette.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One row inside the select's presented sheet.
class _GlassSelectTile extends StatelessWidget {
  const _GlassSelectTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? GlassPalette.textPrimary
                      : GlassPalette.textSecondary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: GlassPalette.indigo,
              ),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
// Shell plumbing
// ─────────────────────────────────────────────────────────────

/// How much room the floating glass chrome (app bar, tab bar, side rail)
/// takes, so a page's own scrollable can start clear of it while its
/// content still slides underneath.
class GlassShellInsets extends InheritedWidget {
  const GlassShellInsets({
    super.key,
    required this.top,
    required this.bottom,
    required this.left,
    required super.child,
  });

  /// Room taken at the top by the floating app bar (already including the
  /// device's safe-area inset).
  final double top;

  /// Room taken at the bottom by the floating tab bar.
  final double bottom;

  /// Room taken at the left by the wide-screen side rail.
  final double left;

  static GlassShellInsets? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassShellInsets>();

  @override
  bool updateShouldNotify(GlassShellInsets oldWidget) =>
      oldWidget.top != top ||
      oldWidget.bottom != bottom ||
      oldWidget.left != left;
}

/// The padding a page inside the shell should give its scrollable.
EdgeInsets glassPagePadding(
  BuildContext context, {
  double horizontal = 20,
  double extraTop = 0,
  double extraBottom = 8,
}) {
  final GlassShellInsets? insets = GlassShellInsets.maybeOf(context);
  return EdgeInsets.only(
    left: horizontal + (insets?.left ?? 0),
    right: horizontal,
    top: (insets?.top ?? 0) + extraTop,
    bottom: (insets?.bottom ?? 0) + extraBottom,
  );
}

// ─────────────────────────────────────────────────────────────
// Feedback
// ─────────────────────────────────────────────────────────────

/// Kinds of glass toast.
enum GlassToastType { info, success, error, warning }

/// A floating glass toast — the app's replacement for flat Material
/// snack bars. Same [ScaffoldMessenger] plumbing underneath, so it
/// queues and dismisses exactly like a snack bar does.
void showGlassToast(
  BuildContext context,
  String message, {
  GlassToastType type = GlassToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final (Color, IconData) accentIcon = switch (type) {
    GlassToastType.success => (GlassPalette.iosGreen, Icons.check_circle_rounded),
    GlassToastType.error => (GlassPalette.iosRed, Icons.error_rounded),
    GlassToastType.warning => (GlassPalette.amber, Icons.warning_amber_rounded),
    GlassToastType.info => (GlassPalette.iosBlue, Icons.info_rounded),
  };

  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: GlassLiteSurface(
        shape: GlassStyles.liteCardShape,
        color: const Color(0xE6141727),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(accentIcon.$2, size: 18, color: accentIcon.$1),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: GlassPalette.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Boot / loading
// ─────────────────────────────────────────────────────────────

/// The full-screen glass loader used while the app boots and while the
/// admin allowlist is verified.
class GlassLoadingScreen extends StatelessWidget {
  const GlassLoadingScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const GlassBackdrop(),
        Center(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: GlassPalette.indigo,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GlassPalette.textSecondary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A page title in the iOS "large title" register, on glass.
class GlassPageTitle extends StatelessWidget {
  const GlassPageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: GlassPalette.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: GlassPalette.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

