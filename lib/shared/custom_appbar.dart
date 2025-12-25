import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing; // Optional trailing widget

  const CustomAppBar({
    super.key,
    required this.title,
    this.trailing, // Accept it in constructor
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: CustomText(
        title: title,
        size: 24,
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      actions: trailing != null ? [trailing!] : null, // Show only if provided
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
