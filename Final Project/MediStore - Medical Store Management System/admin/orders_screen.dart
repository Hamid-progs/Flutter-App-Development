import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String selectedStatus = 'All';

  final statusOptions = ['All', 'pending', 'confirmed', 'delivered', 'cancelled'];

  final statusColors = {
    'pending': Colors.orange,
    'confirmed': Colors.blue,
    'delivered': Colors.green,
    'cancelled': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    try {
      var query = supabase
          .from('orders')
          .select('*, medicines(name), profiles(email)')
          .order('created_at', ascending: false);

      final data = await query;
      setState(() {
        orders = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _updateOrderStatus(String id, String status) async {
    try {
      await supabase
          .from('orders')
          .update({'status': status})
          .eq('id', id);
      _showSuccess('Order status updated');
      _loadOrders();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  List<Map<String, dynamic>> get filteredOrders {
    if (selectedStatus == 'All') return orders;
    return orders.where((o) => o['status'] == selectedStatus).toList();
  }

  void _showStatusDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:  Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['pending', 'confirmed', 'delivered', 'cancelled']
              .map((s) => ListTile(
                    title: Text(s[0].toUpperCase() + s.substring(1)),
                    leading: Radio<String>(
                      value: s,
                      groupValue: order['status'],
                      activeColor:  Color(0xFF0F6E56),
                      onChanged: (v) {
                        Navigator.pop(context);
                        _updateOrderStatus(order['id'].toString(), v!);
                      },
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:  Text('Cancel')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
          margin:  EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:  EdgeInsets.symmetric(horizontal: 12),
            itemCount: statusOptions.length,
            itemBuilder: (_, i) {
              final s = statusOptions[i];
              final isSelected = s == selectedStatus;
              return GestureDetector(
                onTap: () => setState(() => selectedStatus = s),
                child: Container(
                  margin:  EdgeInsets.only(right: 8),
                  padding:
                       EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ?  Color(0xFF0F6E56)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s[0].toUpperCase() + s.substring(1),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: isLoading
              ?  Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F6E56)))
              : filteredOrders.isEmpty
                  ?  Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No orders found',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color:  Color(0xFF0F6E56),
                      child: ListView.builder(
                        padding:  EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredOrders.length,
                        itemBuilder: (_, i) {
                          final o = filteredOrders[i];
                          final status = o['status'] ?? 'pending';
                          final statusColor =
                              statusColors[status] ?? Colors.grey;
                          final medicine = o['medicines'] as Map? ?? {};
                          final profile = o['profiles'] as Map? ?? {};

                          return Card(
                            margin:  EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
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
                                              fontSize: 15)),
                                      Container(
                                        padding:  EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              statusColor.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status[0].toUpperCase() +
                                              status.substring(1),
                                          style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                   SizedBox(height: 8),
                                  Row(
                                    children: [
                                       Icon(Icons.medication,
                                          size: 16, color: Colors.grey),
                                       SizedBox(width: 4),
                                      Text(
                                          medicine['name'] ??
                                              'Unknown Medicine',
                                          style:  TextStyle(
                                              color: Colors.black87)),
                                    ],
                                  ),
                                   SizedBox(height: 4),
                                  Row(
                                    children: [
                                       Icon(Icons.person,
                                          size: 16, color: Colors.grey),
                                       SizedBox(width: 4),
                                      Text(
                                          profile['email'] ??
                                              'Unknown User',
                                          style:  TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13)),
                                    ],
                                  ),
                                   SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          'Qty: ${o['quantity']}  •  PKR ${o['total_price']}',
                                          style:  TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0F6E56))),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _showStatusDialog(o),
                                        icon:  Icon(Icons.edit,
                                            size: 16),
                                        label:  Text('Update'),
                                        style: TextButton.styleFrom(
                                            foregroundColor:
                                                 Color(0xFF0F6E56)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
