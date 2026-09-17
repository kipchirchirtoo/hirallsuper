import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class WaiterScreen extends StatefulWidget {
  final String branchName;
  const WaiterScreen({super.key, this.branchName = 'Central Branch'});

  @override
  State<WaiterScreen> createState() => _WaiterScreenState();
}

class _WaiterScreenState extends State<WaiterScreen> {
  final List<Map<String, dynamic>> _tables = [];

  Map<String, dynamic>? _selectedTable;

  @override
  void initState() {
    super.initState();
    if (_tables.isNotEmpty) {
      _selectedTable = _tables.first;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return AppColors.success;
      case 'occupied':
        return AppColors.primary;
      case 'billing':
        return AppColors.warning;
      case 'reserved':
        return AppColors.accent;
      default:
        return AppColors.darkTextMuted;
    }
  }

  void _sendKitchenOrder() {
    if (_selectedTable == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('KOT (Kitchen Order Ticket) dispatched for ${_selectedTable!['num']}!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Row(
        children: [
          // Left: Floor Plan Grid (65%)
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Waiter & Floor Plan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('Branch: ${widget.branchName} • Live Table Management', style: const TextStyle(fontSize: 13, color: AppColors.darkTextSecondary)),
                        ],
                      ),
                      // Status legend
                      Row(
                        children: [
                          _buildLegendDot(AppColors.success, 'Available'),
                          const SizedBox(width: 14),
                          _buildLegendDot(AppColors.primary, 'Occupied'),
                          const SizedBox(width: 14),
                          _buildLegendDot(AppColors.warning, 'Billing'),
                          const SizedBox(width: 14),
                          _buildLegendDot(AppColors.accent, 'Reserved'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _tables.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.utensils, color: AppColors.darkTextMuted, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'No Dining Tables Configured',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Dining tables and floor plans will appear here if configured.',
                                  style: TextStyle(fontSize: 13, color: AppColors.darkTextSecondary),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 150,
                      ),
                      itemCount: _tables.length,
                      itemBuilder: (context, index) {
                        final table = _tables[index];
                        final isSelected = _selectedTable?['id'] == table['id'];
                        final statusColor = _getStatusColor(table['status'] as String);

                        return InkWell(
                          onTap: () => setState(() => _selectedTable = table),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? statusColor.withOpacity(0.15) : AppColors.darkCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? statusColor : AppColors.darkBorder,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      table['num'] as String,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('${table['capacity']} Seats', style: const TextStyle(fontSize: 12, color: AppColors.darkTextMuted)),
                                const Spacer(),
                                if (table['status'] == 'occupied' || table['status'] == 'billing')
                                  Text(
                                    Formatters.formatCurrency(table['orderTotal'] as num),
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: statusColor),
                                  )
                                else
                                  Text(
                                    (table['status'] as String).toUpperCase(),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Table Order Drawer (35%)
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(left: BorderSide(color: AppColors.darkBorder)),
              ),
              padding: const EdgeInsets.all(24),
              child: _selectedTable == null
                  ? const Center(
                      child: Text('Select a table to view or add orders', style: TextStyle(color: AppColors.darkTextMuted)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedTable!['num'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                                Text('Status: ${(_selectedTable!['status'] as String).toUpperCase()}', style: TextStyle(fontSize: 12, color: _getStatusColor(_selectedTable!['status'] as String), fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.darkCard, borderRadius: BorderRadius.circular(8)),
                              child: Text('${_selectedTable!['capacity']} Guests', style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        const Text('Active Table Items (KOT)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: (_selectedTable!['items'] as List).isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.utensilsCrossed, color: AppColors.darkTextMuted, size: 36),
                                      SizedBox(height: 10),
                                      Text('No active orders on this table', style: TextStyle(color: AppColors.darkTextMuted, fontSize: 13)),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: (_selectedTable!['items'] as List).length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final item = (_selectedTable!['items'] as List)[index];
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkCard,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: AppColors.darkBorder),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(item as String, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
                                          const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 16),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Order Subtotal', style: TextStyle(fontSize: 14, color: AppColors.darkTextSecondary)),
                            Text(
                              Formatters.formatCurrency(_selectedTable!['orderTotal'] as num),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _sendKitchenOrder,
                                icon: const Icon(LucideIcons.chefHat, size: 16),
                                label: const Text('Send KOT'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Bill generated & sent to Cashier checkout!')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                icon: const Icon(LucideIcons.receipt, size: 16),
                                label: const Text('Generate Bill'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.darkTextSecondary)),
      ],
    );
  }
}
