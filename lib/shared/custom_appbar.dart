import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? trailing;
  final bool hasLeading;

  const CustomAppBar(
      {super.key, required this.title, this.trailing, this.hasLeading = true});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 80.v,
      leading: hasLeading
          ? Padding(
              padding: const EdgeInsets.all(10.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: CircleAvatar(
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.white,
                    size: 23.v,
                  ),
                  radius: 5.v,
                  backgroundColor: AppColors.white.withOpacity(.2),
                ),
              ),
            )
          : SizedBox(),
      title: CustomText(
        title: title,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
        size: 24.fSize,
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      iconTheme: const IconThemeData(color: AppColors.white),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(80.v);
}
