import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => MedicinesScreenState();
}

class MedicinesScreenState extends State<MedicinesScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> medicines = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadMedicines();
  }

  Future<void> loadMedicines() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('medicines')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        medicines = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> deleteMedicine(String id) async {
    try {
      await supabase.from('medicines').delete().eq('id', id);
      _showSuccess('Medicine deleted successfully');
      loadMedicines();
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

  void showMedicineDialog({Map<String, dynamic>? medicine}) {
    final nameCtrl = TextEditingController(text: medicine?['name'] ?? '');
    final descCtrl = TextEditingController(text: medicine?['description'] ?? '');
    final priceCtrl =
        TextEditingController(text: medicine?['price']?.toString() ?? '');
    final stockCtrl =
        TextEditingController(text: medicine?['stock']?.toString() ?? '');
    final categoryCtrl =
        TextEditingController(text: medicine?['category'] ?? '');
    final manufacturerCtrl =
        TextEditingController(text: medicine?['manufacturer'] ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(medicine == null ? 'Add Medicine' : 'Edit Medicine',
              style:  TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(nameCtrl, 'Medicine Name', Icons.medication),
                 SizedBox(height: 12),
                _buildField(descCtrl, 'Description', Icons.description, maxLines: 2),
                 SizedBox(height: 12),
                _buildField(categoryCtrl, 'Category', Icons.category),
                 SizedBox(height: 12),
                _buildField(manufacturerCtrl, 'Manufacturer', Icons.business),
                 SizedBox(height: 12),
                _buildField(priceCtrl, 'Price (PKR)', Icons.attach_money,
                    keyboardType: TextInputType.number),
                 SizedBox(height: 12),
                _buildField(stockCtrl, 'Stock Quantity', Icons.inventory_2,
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:  Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor:  Color(0xFF0F6E56)),
              onPressed: saving
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty ||
                          priceCtrl.text.trim().isEmpty ||
                          stockCtrl.text.trim().isEmpty) {
                        _showError('Name, price and stock are required');
                        return;
                      }
                      setStateDialog(() => saving = true);
                      try {
                        final payload = {
                          'name': nameCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'category': categoryCtrl.text.trim(),
                          'manufacturer': manufacturerCtrl.text.trim(),
                          'price': double.tryParse(priceCtrl.text) ?? 0,
                          'stock': int.tryParse(stockCtrl.text) ?? 0,
                        };
                        if (medicine == null) {
                          await supabase.from('medicines').insert(payload);
                          _showSuccess('Medicine added successfully');
                        } else {
                          await supabase
                              .from('medicines')
                              .update(payload)
                              .eq('id', medicine['id']);
                          _showSuccess('Medicine updated successfully');
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        loadMedicines();
                      } catch (e) {
                        _showError(e.toString());
                      }
                      setStateDialog(() => saving = false);
                    },
              child: saving
                  ?  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(medicine == null ? 'Add' : 'Update',
                      style:  TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color:  Color(0xFF0F6E56)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:  BorderSide(color: Color(0xFF0F6E56), width: 2),
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

  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:  Text('Delete Medicine'),
        content:  Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:  Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              deleteMedicine(id);
            },
            child:  Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:  EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by name or category...',
              prefixIcon:  Icon(Icons.search, color: Color(0xFF0F6E56)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:  BorderSide(color: Color(0xFF0F6E56), width: 2),
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
                          Text('No medicines found',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadMedicines,
                      color:  Color(0xFF0F6E56),
                      child: ListView.builder(
                        padding:  EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredMedicines.length,
                        itemBuilder: (_, i) {
                          final m = filteredMedicines[i];
                          final isLowStock = (m['stock'] as int? ?? 0) < 10;
                          return Card(
                            margin:  EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                            child: ListTile(
                              contentPadding:  EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color:
                                       Color(0xFF0F6E56).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child:  Icon(Icons.medication,
                                    color: Color(0xFF0F6E56)),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(m['name'] ?? '',
                                        style:  TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  if (isLowStock)
                                    Container(
                                      padding:  EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child:  Text('Low Stock',
                                          style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   SizedBox(height: 4),
                                  Text(
                                      'Category: ${m['category'] ?? 'N/A'}  •  ${m['manufacturer'] ?? ''}',
                                      style:  TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                  Text(
                                      'PKR ${m['price']}  •  Stock: ${m['stock']}',
                                      style:  TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0F6E56))),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon:  Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () =>
                                        showMedicineDialog(medicine: m),
                                  ),
                                  IconButton(
                                    icon:  Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        confirmDelete(m['id'].toString()),
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
