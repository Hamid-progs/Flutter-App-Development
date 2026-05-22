import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;
  int totalMedicines = 0;
  int totalOrders = 0;
  int totalUsers = 0;
  int lowStockCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => isLoading = true);
    try {
      final medicines = await supabase.from('medicines').select('id, stock');
      final orders = await supabase.from('orders').select('id');
      final users = await supabase.from('profiles').select('id');

      setState(() {
        totalMedicines = medicines.length;
        totalOrders = orders.length;
        totalUsers = users.length;
        lowStockCount =
            medicines.where((m) => (m['stock'] as int? ?? 0) < 10).length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      color:  Color(0xFF0F6E56),
      child: isLoading
          ?  Center(
              child: CircularProgressIndicator(color: Color(0xFF0F6E56)))
          : SingleChildScrollView(
              physics:  AlwaysScrollableScrollPhysics(),
              padding:  EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Overview',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                   SizedBox(height: 4),
                   Text('Welcome back, Admin!',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                   SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:  NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _StatCard(
                        title: 'Total Medicines',
                        value: '$totalMedicines',
                        icon: Icons.medication,
                        color:  Color(0xFF0F6E56),
                      ),
                      _StatCard(
                        title: 'Total Orders',
                        value: '$totalOrders',
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                      ),
                      _StatCard(
                        title: 'Total Users',
                        value: '$totalUsers',
                        icon: Icons.people,
                        color: Colors.purple,
                      ),
                      _StatCard(
                        title: 'Low Stock',
                        value: '$lowStockCount',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                   SizedBox(height: 24),
                  if (lowStockCount > 0)
                    Container(
                      padding:  EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                           Icon(Icons.warning_amber_rounded,
                              color: Colors.orange),
                           SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$lowStockCount medicine(s) are running low on stock. Please restock soon.',
                              style:
                                   TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset:  Offset(0, 4),
          ),
        ],
      ),
      padding:  EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding:  EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(title,
                  style:
                       TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
