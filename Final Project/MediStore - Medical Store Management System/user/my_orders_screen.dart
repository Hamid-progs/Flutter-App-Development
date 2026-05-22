import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  final statusColors = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'delivered': Colors.green,
    'cancelled': Colors.red,
  };

  final statusIcons = {
    'pending': Icons.hourglass_empty,
    'confirmed': Icons.check_circle_outline,
    'delivered': Icons.done_all,
    'cancelled': Icons.cancel_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser!;
      final data = await supabase
          .from('orders')
          .select('*, medicines(name, price)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      setState(() {
        orders = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _cancelOrder(String id) async {
    try {
      await supabase
          .from('orders')
          .update({'status': 'cancelled'})
          .eq('id', id);
      _showSuccess('Order cancelled');
      _loadOrders();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ?  Center(
            child: CircularProgressIndicator(color: Color(0xFF0F6E56)))
        : orders.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.receipt_long_outlined,
                        size: 80, color: Colors.grey),
                     SizedBox(height: 16),
                     Text('No orders yet',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 18)),
                     SizedBox(height: 8),
                     Text('Browse the store to place your first order!',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadOrders,
                color:  Color(0xFF0F6E56),
                child: ListView.builder(
                  padding:  EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    final status = o['status'] ?? 'pending';
                    final statusColor =
                        statusColors[status] ?? Colors.grey;
                    final statusIcon =
                        statusIcons[status] ?? Icons.info_outline;
                    final medicine = o['medicines'] as Map? ?? {};
                    final canCancel = status == 'pending';

                    return Card(
                      margin:  EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding:  EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    'Order #${o['id'].toString().substring(0, 8).toUpperCase()}',
                                    style:  TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                Container(
                                  padding:  EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon,
                                          color: statusColor, size: 14),
                                       SizedBox(width: 4),
                                      Text(
                                        status[0].toUpperCase() +
                                            status.substring(1),
                                        style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                             SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding:  EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:  Color(0xFF0F6E56)
                                        .withOpacity(0.08),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child:  Icon(Icons.medication,
                                      color: Color(0xFF0F6E56), size: 24),
                                ),
                                 SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          medicine['name'] ??
                                              'Unknown Medicine',
                                          style:  TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15)),
                                      Text(
                                          'Qty: ${o['quantity']}  •  PKR ${o['total_price']}',
                                          style:  TextStyle(
                                              color: Color(0xFF0F6E56),
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    _formatDate(o['created_at']),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                                if (canCancel)
                                  TextButton.icon(
                                    onPressed: () =>
                                        _confirmCancel(o['id'].toString()),
                                    icon: const Icon(Icons.cancel_outlined,
                                        size: 16),
                                    label: const Text('Cancel Order'),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        padding: EdgeInsets.zero),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
  }

  void _confirmCancel(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order'),
        content:
            const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(id);
            },
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
