import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wc_coin_app/core/constants/ad_helper/ad_helper.dart';
import 'package:wc_coin_app/core/constants/ad_helper/app_open_ad_helper.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/main.dart';
import 'package:wc_coin_app/models/user_model.dart';
import 'package:wc_coin_app/screens/login/login.dart';
import 'package:wc_coin_app/screens/withdrawl_history/withdrawl_history.dart';
import 'package:wc_coin_app/services/user_profile_service.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/custom_button.dart';
import 'package:wc_coin_app/shared/snackbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class MyProfileView extends StatefulWidget {
  const MyProfileView({super.key});

  @override
  _MyProfileViewState createState() => _MyProfileViewState();
}

class _MyProfileViewState extends State<MyProfileView> {
  final UserService _userService = UserService();
  GoogleAdmobProvider adVM = GoogleAdmobProvider();

  UserModel? _user;
  String? _name;
  String? _email;
  String? _avatar;
  bool _isLoading = true;
  String? _error;
  bool _isDeletingAccount = false;

  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    adVM.loadInterAd();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _userService.fetchProfile();

      if (user == null) {
        setState(() {
          _error = "No profile data found";
          _isLoading = false;
        });
        return;
      }

      _name = user.name;
      _email = user.email;
      _avatar = user.avatar;
      _user = user;
      _nameController.text = _name ?? '';

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeletingAccount = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null) {
        if (!mounted) return;
        showCustomSnackBar("No API token found", context, isError: true);
        setState(() => _isDeletingAccount = false);
        return;
      }

      final response = await http.delete(
        Uri.parse("https://wc-admin.genwizz.com/api/delete-account"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Clear all stored data
        await prefs.clear();

        // Show success message
        showCustomSnackBar("Account deleted successfully", context,
            isError: false);

        // Navigate to login screen and clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (Route<dynamic> route) => false,
        );
      } else {
        final data = jsonDecode(response.body);
        String errorMessage = data["message"] ?? "Failed to delete account";
        showCustomSnackBar(errorMessage, context, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar("Error: $e", context, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.bgColor,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              CustomText(title: 'Delete Account')
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                title: 'Are you sure you want to delete your account?',
                size: 16,
              ),
              SizedBox(height: 10),
              CustomText(
                title:
                    'This action cannot be undone. All your data including coins and progress will be permanently lost.',
                size: 14,
              )
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const CustomText(title: 'Cancel')),
            ElevatedButton(
                onPressed: _isDeletingAccount
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        _deleteAccount();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isDeletingAccount
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : CustomText(
                        title: 'Delete',
                        color: AppColors.white,
                      )),
          ],
        );
      },
    );
  }

  Widget _iconCard({
    required String title,
    required String image,
    bool haveAmount = true,
    required String subtitle,
  }) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 120.h,
        height: 150.v,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
                backgroundColor: AppColors.secondary,
                child: Image.asset(image, scale: 5.v)),
            SizedBox(height: 12.v),
            CustomText(
                title: title,
                size: 13.fSize,
                color: AppColors.fontColor,
                fontWeight: FontWeight.w500,
                alignment: TextAlign.center),
            SizedBox(height: 12.v),
            if (haveAmount)
              CustomText(
                title: subtitle,
                size: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.fontColor,
              )
          ],
        ),
      ),
    );
  }

  Widget _menuItem(String title) {
    bool isDeleteAccount = title.contains('Delete Account');
    bool isRateUs = title.contains('Rate Us');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 13.v),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: CustomText(
              title: title,
              color: isDeleteAccount ? Colors.red : Colors.black,
              size: 23,
              fontWeight: FontWeight.w600,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: isDeleteAccount ? Colors.red : const Color(0xff7680A6),
              size: 16,
            ),
            onTap: () {
              if (isDeleteAccount) {
                _showDeleteAccountDialog();
              } else if (isRateUs) {
                // Handle other menu items
                _openPlayStore();
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openPlayStore() async {
    const String appId = 'com.get_unlimited_uc.earnuc_winuc_getuc';
    final Uri uri =
        Uri.parse("https://play.google.com/store/apps/details?id=$appId");

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "My Profile"),
      backgroundColor: AppColors.bgColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _loadProfile,
                          child: const Text("Retry"),
                        )
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 25.h,
                          ),
                          child: Material(
                            elevation: 5,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 25.v),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundImage: _avatar != null
                                        ? NetworkImage(_avatar!)
                                        : const AssetImage(
                                                "assets/images/profile.png")
                                            as ImageProvider,
                                  ),
                                  Gap.v(15),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CustomText(
                                        title: _name ?? '',
                                        size: 25,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.fontColor,
                                      ),
                                    ],
                                  ),
                                  CustomText(
                                    title: _email ?? '',
                                    size: 14,
                                    color: const Color(0xffA0A6BD),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 25.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _iconCard(
                                  title: "Total Earn",
                                  image: "assets/icons/coin.png",
                                  subtitle: "${_user?.coins ?? 0}"),
                              _iconCard(
                                  title: "Total Redeem",
                                  image: "assets/icons/coin.png",
                                  subtitle: "${_user?.totalRedeem ?? 0}"),
                              GestureDetector(
                                onTap: () {
                                  apads['int']
                                      ? InterstitialAdLoading.show(context,
                                          onComplete: () {
                                          Navigator.push(context,
                                              MaterialPageRoute(
                                            builder: (context) {
                                              return WithDrawlHistoryView();
                                            },
                                          ));
                                        }, onFailed: () {
                                          Navigator.push(context,
                                              MaterialPageRoute(
                                            builder: (context) {
                                              return WithDrawlHistoryView();
                                            },
                                          ));
                                        })
                                      : () {
                                          Navigator.push(context,
                                              MaterialPageRoute(
                                            builder: (context) {
                                              return WithDrawlHistoryView();
                                            },
                                          ));
                                        };
                                },
                                child: Material(
                                  elevation: 5,
                                  borderRadius: BorderRadius.circular(15),
                                  child: Container(
                                    width: 120.h,
                                    height: 150.v,
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: AppColors.secondary,
                                          child: Image.asset(
                                            "assets/icons/withdraw.png",
                                            scale: 5,
                                          ),
                                        ),
                                        SizedBox(height: 12.v),
                                        CustomText(
                                            title: 'Withdrawal',
                                            size: 13.fSize,
                                            color: AppColors.fontColor,
                                            fontWeight: FontWeight.w500,
                                            alignment: TextAlign.center),
                                        SizedBox(height: 12.v),
                                        CustomText(
                                            title: "History",
                                            size: 20.fSize,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.fontColor,
                                            alignment: TextAlign.center),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        Gap.v(30),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: CustomText(
                              title: 'General',
                              size: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.fontColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _menuItem('🖐 Help'),
                        _menuItem('📲 Contact Us'),
                        _menuItem('✨ Rate Us'),
                        _menuItem('🗑️ Delete Account'),
                        SizedBox(height: 10.v),
                      ],
                    ),
                  ),
      ),
    );
  }
}
