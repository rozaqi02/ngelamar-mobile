import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Unified Neo-Modern Search Box Component.
/// Digunakan di seluruh menu (Beranda, Daftar Lamaran, Eksplor Loker) dengan visual yang seragam:
/// - Radius pill konsisten (AppTheme.radiusPill: 28px/32px)
/// - Adaptif Dark/Light mode dengan border tipis dan bayangan halus
/// - Teks & ikon terpusat vertikal secara presisi (pixel-perfect)
/// - Ikon search elegan & tombol hapus cepat (X)
class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  const AppSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Cari posisi, perusahaan, atau kata kunci...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF242428) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF383840)
        : const Color(0xFFE5E0D5);
    final txtColor = isDark ? Colors.white : const Color(0xFF121214);
    final hintColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF9E9EA4);
    final iconColor = isDark
        ? const Color(0xFFA0A0A8)
        : const Color(0xFF707074);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final fieldHeight = (48 + (textScale - 1) * 14).clamp(48, 64).toDouble();

    return Container(
      height: fieldHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: borderColor, width: AppTheme.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: txtColor,
          height: 1.2,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: hintColor,
            height: 1.2,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Icon(CupertinoIcons.search, size: 18, color: iconColor),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 48,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, val, _) {
              if (val.text.isEmpty) return const SizedBox.shrink();
              return Semantics(
                button: true,
                label: 'Hapus pencarian',
                child: IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    controller.clear();
                    if (onClear != null) onClear!();
                    if (onChanged != null) onChanged!('');
                  },
                  padding: const EdgeInsets.only(right: 10),
                  icon: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 48,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 0,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
