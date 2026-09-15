import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/customer_order.dart';
import '../services/api_client.dart';
import '../services/customer_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/status_badge.dart';
import 'home_screen.dart' show formatKes;

/// Rewritten against GET /customer-portal/orders -- the real CRM's order
/// history, not the old Firestore `orders` collection the app used to write
/// to (which was invisible to the actual backend and never drew down
/// inventory).
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<CustomerOrder> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  static final _dateFormat = DateFormat('d MMM y, h:mm a');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchOrders());
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await context.read<CustomerApi>().orders();
      if (!mounted) return;
      setState(() => _orders = orders);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load orders. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: 4,
              itemBuilder: (context, index) => const SkeletonListRow(),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton(onPressed: _fetchOrders, child: const Text('TRY AGAIN')),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? const EmptyState(
                      glyph: EmptyStateGlyph.box,
                      title: 'No orders yet',
                      message: 'Orders you place will show up here.',
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _orders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.line, width: AppSpacing.hairline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Order ${order.orderNumber}', style: Theme.of(context).textTheme.titleSmall),
                                    StatusBadge(status: order.status),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Total: ${formatKes(order.total)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if (order.owing > 0.001)
                                  Text(
                                    'Owing: ${formatKes(order.owing)}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.warning),
                                  ),
                                if (order.shippingAddress != null && order.shippingAddress!.isNotEmpty)
                                  Text('Delivering to ${order.shippingAddress}', style: Theme.of(context).textTheme.bodySmall)
                                else if (order.store != null)
                                  Text('Collect at ${order.store!.name}', style: Theme.of(context).textTheme.bodySmall),
                                const SizedBox(height: AppSpacing.sm),
                                ...order.lines.map((line) => Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        '${line.description} x ${line.quantity} (${formatKes(line.lineTotal)})',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    )),
                                if (order.placedAt != null) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Placed: ${_dateFormat.format(order.placedAt!.toLocal())}',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
