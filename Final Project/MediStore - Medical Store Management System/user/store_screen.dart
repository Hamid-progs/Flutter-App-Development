import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> medicines = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('medicines')
          .select()
          .gt('stock', 0)
          .order('name');
      setState(() {
        medicines = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }



 _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  _showOrderDialog(Map<String, dynamic> medicine) {
    int quantity = 1;
    final maxStock = medicine['stock'] as int? ?? 1;
    bool placing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title:  Text('Place Order',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:  EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:  Color(0xFF0F6E56).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding:  EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:  Color(0xFF0F6E56).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:  Icon(Icons.medication,
                          color: Color(0xFF0F6E56), size: 28),
                    ),
                     SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(medicine['name'] ?? '',
                              style:  TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('PKR ${medicine['price']} per unit',
                              style:  TextStyle(
                                  color: Color(0xFF0F6E56),
                                  fontWeight: FontWeight.w600)),
                          Text('Available: $maxStock units',
                              style:  TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
               SizedBox(height: 20),
               Text('Quantity:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
               SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: quantity > 1
                        ? () => setStateDialog(() => quantity--)
                        : null,
                    icon:  Icon(Icons.remove_circle_outline),
                    color:  Color(0xFF0F6E56),
                    iconSize: 32,
                  ),
                  Container(
                    padding:  EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color:  Color(0xFF0F6E56)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$quantity',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    onPressed: quantity < maxStock
                        ? () => setStateDialog(() => quantity++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFF0F6E56),
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text('Total:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      'PKR ${((medicine['price'] as num) * quantity).toStringAsFixed(0)}',
                      style:  TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F6E56)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:  Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F6E56),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12)),
              onPressed: placing
                  ? null
                  : () async {
                      setStateDialog(() => placing = true);
                      try {
                        final user = supabase.auth.currentUser!;
                        final total =
                            (medicine['price'] as num) * quantity;
                        await supabase.from('orders').insert({
                          'user_id': user.id,
                          'medicine_id': medicine['id'],
                          'quantity': quantity,
                          'total_price': total,
                          'status': 'pending',
                        });
                        // Update stock
                        await supabase
                            .from('medicines')
                            .update({
                              'stock': maxStock - quantity
                            })
                            .eq('id', medicine['id']);

                        if (ctx.mounted) Navigator.pop(ctx);
                        _showSuccess('Order placed successfully!');
                        _loadMedicines();
                      } catch (e) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                      }
                      setStateDialog(() => placing = false);
                    },
              child: placing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Order Now',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get filteredMedicines {
    if (searchQuery.isEmpty) return medicines;
    return medicines
        .where((m) =>
            m['name']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            (m['category'] ?? '')
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color:  Color(0xFF0F6E56).withOpacity(0.05),
          padding:  EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search medicines...',
              prefixIcon:  Icon(Icons.search, color: Color(0xFF0F6E56)),
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                     BorderSide(color: Color(0xFF0F6E56), width: 2),
              ),
            ),
            onChanged: (v) => setState(() => searchQuery = v),
          ),
        ),
        Expanded(
          child: isLoading
              ?  Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F6E56)))
              : filteredMedicines.isEmpty
                  ?  Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medication_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No medicines available',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(

            onRefresh: _loadMedicines,
                      color: Color(0xFF0F6E56),
                      child: GridView.builder(
                        padding:  EdgeInsets.all(12),
                        gridDelegate:
                             SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredMedicines.length,
                        itemBuilder: (_, i) {
                          final m = filteredMedicines[i];
                          return GestureDetector(
                            onTap: () => _showOrderDialog(m),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 3,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 90,
                                    decoration: BoxDecoration(
                                      color:  Color(0xFF0F6E56)
                                          .withOpacity(0.08),
                                      borderRadius:  BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child:  Center(
                                      child: Icon(Icons.medication,
                                          size: 48,
                                          color: Color(0xFF0F6E56)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(m['name'] ?? '',
                                              style:  TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 14),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                          if (m['category'] != null)
                                            Text(m['category'],
                                                style:  TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Text('PKR ${m['price']}',
                                                  style:  TextStyle(
                                                      color:
                                                          Color(0xFF0F6E56),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15)),
                                              Container(
                                                padding:  EdgeInsets
                                                    .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6),
                                                ),
                                                child: Text(
                                                    '${m['stock']} left',
                                                    style: TextStyle(
                                                        color: Colors.green
                                                            .shade700,
                                                        fontSize: 11)),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style:
                                                  ElevatedButton.styleFrom(
                                                backgroundColor:
                                                     Color(0xFF0F6E56),
                                                padding:
                                                     EdgeInsets.symmetric(
                                                        vertical: 6),
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8),
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _showOrderDialog(m),
                                              child: const Text('Order',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
