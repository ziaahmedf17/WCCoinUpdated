import 'package:flutter/material.dart';
import 'package:wc_coin_app/core/constants/colors.dart';
import 'package:wc_coin_app/core/constants/size_utils.dart';
import 'package:wc_coin_app/models/transaction_model.dart';
import 'package:wc_coin_app/services/transaction_service.dart';
import 'package:wc_coin_app/shared/custom_appbar.dart';
import 'package:wc_coin_app/shared/text_view.dart';

class WithDrawlHistoryView extends StatefulWidget {
  const WithDrawlHistoryView({super.key});

  @override
  State<WithDrawlHistoryView> createState() => _WithDrawlHistoryViewState();
}

class _WithDrawlHistoryViewState extends State<WithDrawlHistoryView> {
  List<Transaction> transactions = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final fetchedTransactions = await TransactionService.getTransactions();

      setState(() {
        transactions = fetchedTransactions;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _showTransactionDialog(String transactionId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: FutureBuilder<Transaction>(
            future:
                TransactionService.getTransactionById(int.parse(transactionId)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: EdgeInsets.all(40.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                      Gap.v(20),
                      const CustomText(
                        title: 'Loading transaction details...',
                        size: 16,
                        color: AppColors.white,
                        alignment: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: EdgeInsets.all(20.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48.v,
                        color: Colors.red,
                      ),
                      Gap.v(16),
                      const CustomText(
                        title: 'Error loading transaction',
                        size: 18,
                        color: AppColors.white,
                        alignment: TextAlign.center,
                      ),
                      Gap.v(8),
                      CustomText(
                        title: snapshot.error
                            .toString()
                            .replaceAll('Exception: ', ''),
                        size: 14,
                        color: AppColors.white.withOpacity(0.8),
                        alignment: TextAlign.center,
                        maxLines: 3,
                        // overflow: TextOverflow.ellipsis,
                      ),
                      Gap.v(20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const CustomText(
                              title: 'Close',
                              size: 16,
                              color: AppColors.white,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showTransactionDialog(transactionId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.white,
                              foregroundColor: AppColors.primary,
                            ),
                            child: const CustomText(
                              title: 'Retry',
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return Container(
                  padding: EdgeInsets.all(20.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48.v,
                        color: AppColors.white.withOpacity(0.7),
                      ),
                      Gap.v(16),
                      const CustomText(
                        title: 'Transaction not found',
                        size: 18,
                        color: AppColors.white,
                        alignment: TextAlign.center,
                      ),
                      Gap.v(20),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const CustomText(
                          title: 'Close',
                          size: 16,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final transaction = snapshot.data!;
              return _buildTransactionDetailDialog(transaction);
            },
          ),
        );
      },
    );
  }

  Widget _buildTransactionDetailDialog(Transaction transaction) {
    return Container(
      padding: EdgeInsets.all(20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomText(
                title: 'Transaction Details',
                size: 20,
                color: AppColors.white,
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
          Gap.v(20),

          // Only show image if transaction is not pending
          if (transaction.status.toLowerCase() != 'pending') ...[
            _buildTransactionImage(transaction.transactionImageUrl ?? ''),
            Gap.v(12),
          ],

          _buildDetailRow('Transaction ID', transaction.transactionId),
          Gap.v(12),
          _buildDetailRow('Status', transaction.status.capitalize(),
              valueColor: _getStatusColor(transaction.status)),
          Gap.v(12),
          _buildDetailRow(
            'Withdraw Coins',
            '-${transaction.withdrawCoins.toStringAsFixed(0)} coins',
            valueColor: Colors.white,
          ),
          Gap.v(12),
          _buildDetailRow(
              'Total UC', '${transaction.totalUc.toStringAsFixed(0)} UC'),
          Gap.v(12),
          _buildDetailRow('Date', _formatDate(transaction.createdAt)),
          Gap.v(12),
          _buildDetailRow('Message', transaction.message, isMultiline: true),
          Gap.v(30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 12.v),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const CustomText(
                title: 'Close',
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const CustomText(
              title: 'Transaction Proof',
              size: 18,
              color: Colors.white,
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        Gap.v(16),
                        const CustomText(
                          title: 'Loading image...',
                          size: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 64.v,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        Gap.v(16),
                        const CustomText(
                          title: 'Failed to load image',
                          size: 14,
                          color: Colors.white,
                          alignment: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionImage(String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title: 'Transaction Proof Image',
          size: 14,
          color: AppColors.white.withOpacity(0.7),
        ),
        Gap.v(8),
        GestureDetector(
          onTap: () => _showFullScreenImage(imageUrl),
          child: Container(
            width: double.infinity,
            height: 200.v,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.white),
                          strokeWidth: 2,
                        ),
                        Gap.v(8),
                        CustomText(
                          title: 'Loading image...',
                          size: 12,
                          color: AppColors.white.withOpacity(0.7),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48.v,
                          color: AppColors.white.withOpacity(0.5),
                        ),
                        Gap.v(8),
                        CustomText(
                          title: 'Failed to load image',
                          size: 12,
                          color: AppColors.white.withOpacity(0.7),
                          alignment: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Gap.v(4),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? valueColor, bool isMultiline = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title: label,
          size: 14,
          color: AppColors.white.withOpacity(0.7),
        ),
        Gap.v(4),
        CustomText(
          title: value,
          size: 16,
          color: valueColor ?? AppColors.white,
          maxLines: isMultiline ? null : 1,
          // overflow: isMultiline ? null : TextOverflow.ellipsis,
        ),
      ],
    );
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
            title: 'Loading transactions...',
            size: 16,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.v,
              color: AppColors.white.withOpacity(0.7),
            ),
            Gap.v(20),
            const CustomText(
              title: 'Oops! Something went wrong',
              size: 18,
              color: AppColors.white,
            ),
            Gap.v(10),
            CustomText(
              title: errorMessage ?? 'Unknown error occurred',
              size: 14,
              color: AppColors.white.withOpacity(0.8),
              alignment: TextAlign.center,
            ),
            Gap.v(30),
            ElevatedButton(
              onPressed: _loadTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 30.h, vertical: 12.v),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const CustomText(
                title: 'Try Again',
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64.v,
            color: AppColors.white.withOpacity(0.7),
          ),
          Gap.v(20),
          const CustomText(
            title: 'No withdrawal history yet',
            size: 18,
            color: AppColors.white,
          ),
          Gap.v(10),
          CustomText(
            title: 'Your withdrawal transactions will appear here',
            size: 14,
            color: AppColors.white.withOpacity(0.8),
            alignment: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'approved':
        return const Color(0xff44FF00);
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget HistoryDetail({
    required Transaction transaction,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 10.v, right: 20.h, left: 20.h),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 5,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.v),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            onTap: () => _showTransactionDialog(transaction.id.toString()),
            leading: CircleAvatar(
              backgroundColor: AppColors.secondary,
              radius: 30.fSize,
              child: Center(
                child: Image.asset(
                  'assets/icons/WCC.png',
                  scale: 5.v,
                ),
              ),
            ),
            // title: CustomText(
            //   title: transaction.transactionId,
            //   size: 16.fSize,
            //   color: AppColors.white,
            // ),
            title: CustomText(
              title:
                  'Withdrawal of ${transaction.totalUc.toStringAsFixed(0)} UC',
              color: AppColors.fontColor,
              size: 17.fSize,
              fontWeight: FontWeight.w600,
            ),
            subtitle: CustomText(
              title: _formatDate(transaction.createdAt),
              color: Colors.black.withOpacity(0.5),
              size: 14.fSize,
            ),
            trailing: CustomText(
              size: 16.fSize,
              title: '-${transaction.withdrawCoins.toStringAsFixed(0)} coins',
              color: AppColors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      // appBar: AppBar(
      //   title: const CustomText(
      //     title: 'Withdrawal History',
      //     size: 24,
      //     color: AppColors.white,
      //   ),
      //   centerTitle: true,
      //   elevation: 0,
      //   backgroundColor: AppColors.primary,
      //   iconTheme: const IconThemeData(color: AppColors.white),
      // ),

      appBar: CustomAppBar(
        title: 'Withdrawal History',
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        color: AppColors.primary,
        backgroundColor: AppColors.white,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingWidget();
    }

    if (errorMessage != null) {
      return _buildErrorWidget();
    }

    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return HistoryDetail(
                transaction: transactions[index],
              );
            },
          ),
        ),
      ],
    );
  }
}

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
