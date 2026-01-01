import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class ProfileDetailView extends StatefulWidget {
  final int userId;
  const ProfileDetailView({super.key, required this.userId});

  @override
  State<ProfileDetailView> createState() => _ProfileDetailViewState();
}

class _ProfileDetailViewState extends State<ProfileDetailView> {
  Map<String, dynamic>? userData;
  List<dynamic>? transactions;
  bool _loading = true;
  String? _error;

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');
      if (token == null) {
        setState(() {
          _error = "No token found";
          _loading = false;
        });
        return;
      }

      final url = Uri.parse(
          "https://wc-admin.genwizz.com/api/leaderboard/${widget.userId}");
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userData = data['user'];
          transactions =
              data['transactions']; // Get transactions from API response
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Failed: ${response.statusCode}";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error: $e";
        _loading = false;
      });
    }
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
          ),
          Gap.v(20),
          const CustomText(
            title: 'Loading Details...',
            size: 16,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard,
            size: 64.v,
            color: AppColors.white.withOpacity(0.7),
          ),
          Gap.v(20),
          const CustomText(
            title: 'No Leaderboard yet',
            size: 18,
            color: AppColors.white,
          ),
          Gap.v(10),
          CustomText(
            title: 'All the users will displayed here.',
            size: 14,
            color: AppColors.white.withOpacity(0.8),
            alignment: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Profile Details"),
      backgroundColor: AppColors.primary,
      body: _loading
          ? Center(child: _buildLoadingWidget())
          : _error != null
              ? Center(
                  child: CustomText(
                    title: _error!,
                    size: 16,
                    color: Colors.red,
                  ),
                )
              : userData == null
                  ? Center(child: _buildEmptyState())
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            padding: EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.fontColor,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: userData!['avatar'] != null
                                  ? NetworkImage(userData!['avatar'])
                                  : const AssetImage("assets/images/demo.png")
                                      as ImageProvider,
                            ),
                          ),
                          Gap.v(15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomText(
                                title: userData!['name'] ?? "No Name",
                                size: 25,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                          CustomText(
                            title: userData!['email'] ?? "",
                            size: 14,
                            color: AppColors.white,
                          ),
                          SizedBox(height: 20.v),

                          // Cards
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _iconCard(
                                  title: "Total Earn",
                                  image: "assets/icons/coin.png",
                                  subtitle: "${userData!['total_earn'] ?? 0}",
                                ),
                                _iconCard(
                                  title: "Total Redeem",
                                  image: "assets/icons/coin.png",

                                  subtitle:
                                      "${userData!['total_radeem'] ?? 0}", // Fixed: using 'total_radeem' as in API response
                                ),
                              ],
                            ),
                          ),
                          Gap.v(45),

                          Container(
                            color: AppColors.bgColor,
                            child: Column(
                              children: [
                                Gap.v(30),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: CustomText(
                                      title: 'Withdrawal History',
                                      size: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Gap.v(30),
                                SizedBox(
                                  height: SizeUtils.height,
                                  child: (transactions != null &&
                                          transactions!.isNotEmpty)
                                      ? ListView.builder(
                                          itemCount: transactions!.length,
                                          itemBuilder: (context, index) {
                                            final transaction =
                                                transactions![index];
                                            return ActivityTile(
                                              image: "assets/icons/WCC.png",
                                              subtitle: transaction['status'] ??
                                                  "N/A",
                                              tile: transaction[
                                                      'transaction_id'] ??
                                                  "Withdrawal Record",
                                              traling:
                                                  "-${transaction['withdraw_coins'] ?? 0}",
                                            );
                                          },
                                        )
                                      : const Center(
                                          child: CustomText(
                                            title: "No withdrawal history",
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
    );
  }

  Widget ActivityTile({
    required String tile,
    required String image,
    required String subtitle,
    required String traling,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 18.v, left: 20, right: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10.v, horizontal: 12.h),
          child: ListTile(
            contentPadding: const EdgeInsets.all(0),
            leading: CircleAvatar(
              radius: 30.fSize,
              backgroundColor: AppColors.secondary,
              child: Center(
                child: Image.asset(
                  image,
                  scale: 6.5.v,
                ),
              ),
            ),
            title: CustomText(
              title: tile,
              height: 0,
              size: 22.fSize,
              fontWeight: FontWeight.bold,
            ),
            subtitle: Padding(
              padding: EdgeInsets.symmetric(vertical: 7.v),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 5.v, horizontal: 12.h),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: AppColors.secondary.withOpacity(.1),
                    border:
                        Border.all(color: AppColors.secondary.withOpacity(.4))),
                child: CustomText(
                  title: subtitle,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  alignment: TextAlign.center,
                ),
              ),
            ),
            trailing: CustomText(
              size: 25.fSize,
              title: traling,
              color: AppColors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconCard({
    required String title,
    required String image,
    required String subtitle,
  }) {
    return Container(
      width: 180.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.symmetric(horizontal: 25.h, vertical: 20.v),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, scale: 3.v),
          SizedBox(height: 12.v),
          CustomText(
            title: title,
            size: 17.fSize,
            fontWeight: FontWeight.w500,
            color: AppColors.fontColor.withOpacity(.7),
            alignment: TextAlign.center,
          ),
          SizedBox(height: 12.v),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomText(
                title: subtitle,
                fontWeight: FontWeight.bold,
                size: 21,
                height: 0,
              ),
              Gap.h(10),
              Image.asset(
                "assets/icons/coin.png",
                scale: 5.v,
              )
            ],
          ),
        ],
      ),
    );
  }
}
