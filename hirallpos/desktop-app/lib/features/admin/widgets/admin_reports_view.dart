import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/printing_service.dart';
import '../../../core/network/api_service.dart';

class AdminReportsView extends StatefulWidget {
  final String organizationName;
  final String currentBranchName;
  final String? branchId;

  const AdminReportsView({
    super.key,
    required this.organizationName,
    required this.currentBranchName,
    this.branchId,
  });

  @override
  State<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends State<AdminReportsView> {
  String _selectedBranchScope = 'global';
  String _selectedDateRange = 'today'; // 'today' | 'yesterday' | 'week' | 'month'

  List<Map<String, String>> _branches = [];
  List<Map<String, dynamic>> _sales = [];
  Map<String, dynamic> _backendSummary = {};

  @override
  void initState() {
    super.initState();
    _initBranches();
    _loadData();
  }

  void _initBranches() {
    _branches = [
      {'id': 'global', 'name': '🌐 Global Org (All Branches Aggregate)'},
      {'id': widget.currentBranchName.toLowerCase(), 'name': '🏬 ${widget.currentBranchName} Branch'},
    ];
  }

  Future<void> _loadData() async {
    try {
      // 1. Fetch real branch list from backend
      try {
        final apiBranches = await ApiService().getBranches();
        for (final b in apiBranches) {
          if (b is Map<String, dynamic>) {
            final id = (b['id'] ?? b['branch_id'] ?? '').toString().toLowerCase();
            final name = (b['name'] ?? b['branch_name'] ?? '').toString();
            if (id.isNotEmpty && name.isNotEmpty && !_branches.any((item) => item['id'] == id)) {
              _branches.add({'id': id, 'name': '🏬 $name'});
            }
          }
        }
      } catch (_) {}

      // 2. Fetch live financial summary from backend
      try {
        final summary = await ApiService().getFinancialSummary();
        _backendSummary = summary;
      } catch (_) {}

      // 3. Load recorded sales from live PostgreSQL database
      try {
        final dbSales = await ApiService().getSales();
        if (dbSales.isNotEmpty) {
          _sales = dbSales.map((s) {
            final m = Map<String, dynamic>.from(s as Map);
            final createdAtStr = (m['created_at'] ?? DateTime.now().toIso8601String()).toString();
            final grandTotal = double.tryParse(m['grand_total']?.toString() ?? '0') ?? 0.0;
            final subtotal = double.tryParse(m['subtotal']?.toString() ?? '0') ?? grandTotal;
            final taxTotal = double.tryParse(m['tax_total']?.toString() ?? '0') ?? 0.0;
            final discountTotal = double.tryParse(m['discount_total']?.toString() ?? '0') ?? 0.0;
            final paymentMethod = (m['payment_method'] ?? 'CASH').toString();
            final branchName = (m['branch_name'] ?? widget.currentBranchName).toString();
            final branchId = (m['branch_id'] ?? '').toString();
            final cashierName = (m['cashier_name'] ?? 'Staff').toString();
            final itemCount = (m['item_count'] as num?)?.toInt() ?? 1;

            return {
              'id': m['sale_number'] ?? m['id']?.toString() ?? 'SALE-001',
              'sale_number': m['sale_number'] ?? 'SALE-001',
              'dateTime': createdAtStr,
              'timestamp': createdAtStr,
              'date': createdAtStr,
              'total': grandTotal,
              'subtotal': subtotal,
              'tax': taxTotal,
              'discount': discountTotal,
              'paymentMethod': paymentMethod,
              'branchName': branchName,
              'branchId': branchId,
              'cashier': cashierName,
              'itemCount': itemCount,
              'items': <dynamic>[],
            };
          }).toList();
        } else {
          final prefs = await SharedPreferences.getInstance();
          final savedSales = prefs.getString('hirall_recorded_sales');
          if (savedSales != null && savedSales.isNotEmpty) {
            final List<dynamic> decoded = jsonDecode(savedSales);
            _sales = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
          } else {
            _sales = [];
          }
        }
      } catch (_) {
        final prefs = await SharedPreferences.getInstance();
        final savedSales = prefs.getString('hirall_recorded_sales');
        if (savedSales != null && savedSales.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(savedSales);
          _sales = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          _sales = [];
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() {});
    }
  }

  bool _isWithinDateRange(DateTime dt, String range) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (range) {
      case 'today':
        return dt.isAfter(todayStart);
      case 'yesterday':
        final yestStart = todayStart.subtract(const Duration(days: 1));
        return dt.isAfter(yestStart) && dt.isBefore(todayStart);
      case 'week':
        return dt.isAfter(todayStart.subtract(const Duration(days: 7)));
      case 'month':
        return dt.isAfter(todayStart.subtract(const Duration(days: 30)));
      default:
        return true;
    }
  }

  List<Map<String, dynamic>> _getFilteredSales() {
    return _sales.where((sale) {
      // Branch filter
      if (_selectedBranchScope != 'global') {
        final bName = (sale['branchName'] ?? '').toString().toLowerCase();
        final bId = (sale['branchId'] ?? '').toString().toLowerCase();
        final matchesBranch = bName.contains(_selectedBranchScope) ||
            bId == _selectedBranchScope ||
            _selectedBranchScope.contains(bName);
        if (!matchesBranch) return false;
      }

      // Date filter
      final dtStr = sale['dateTime']?.toString();
      if (dtStr != null) {
        final dt = DateTime.tryParse(dtStr);
        if (dt != null && !_isWithinDateRange(dt, _selectedDateRange)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Map<String, dynamic> _getReportMetrics() {
    final filteredSales = _getFilteredSales();

    double gross = 0.0;
    double discount = 0.0;
    double vat = 0.0;
    double mpesa = 0.0;
    double cash = 0.0;
    double card = 0.0;
    int orders = filteredSales.length;

    for (final s in filteredSales) {
      final total = double.tryParse(s['total']?.toString() ?? '0') ?? 0.0;
      final disc = double.tryParse(s['discount']?.toString() ?? '0') ?? 0.0;
      final tax = double.tryParse(s['tax']?.toString() ?? '0') ?? 0.0;
      final method = (s['paymentMethod'] ?? '').toString().toUpperCase();

      gross += total;
      discount += disc;
      vat += tax;

      if (method.contains('MPESA') || method.contains('M-PESA')) {
        mpesa += total;
      } else if (method.contains('CASH')) {
        cash += total;
      } else if (method.contains('CARD') || method.contains('VISA')) {
        card += total;
      } else {
        cash += total;
      }
    }

    // Fallback to backend live summary if local sales empty for today
    if (orders == 0 && _selectedDateRange == 'today' && _backendSummary.isNotEmpty) {
      gross = double.tryParse(_backendSummary['gross_sales']?.toString() ?? '0') ?? 0.0;
      vat = double.tryParse(_backendSummary['vat_collected']?.toString() ?? '0') ?? 0.0;
      orders = (_backendSummary['transaction_count'] as num?)?.toInt() ?? 0;
    }

    final net = gross - discount;
    final avgBasket = orders > 0 ? gross / orders : 0.0;

    final mpesaPct = gross > 0 ? ((mpesa / gross) * 100).round() : 0;
    final cashPct = gross > 0 ? ((cash / gross) * 100).round() : 0;
    final cardPct = gross > 0 ? ((card / gross) * 100).round() : 0;

    return {
      'grossSales': gross,
      'netSales': net,
      'discount': discount,
      'vatCollected': vat,
      'ordersCount': orders,
      'avgBasket': avgBasket,
      'mpesaSales': mpesa,
      'cashSales': cash,
      'cardSales': card,
      'mpesaPct': mpesaPct,
      'cashPct': cashPct,
      'cardPct': cardPct,
    };
  }

  List<Map<String, dynamic>> _getTopSellingProducts() {
    final filteredSales = _getFilteredSales();
    final Map<String, Map<String, dynamic>> aggregated = {};

    for (final sale in filteredSales) {
      final items = sale['items'];
      if (items is List) {
        for (final item in items) {
          if (item is Map) {
            final name = (item['name'] ?? 'Unknown Item').toString();
            final qty = double.tryParse(item['quantity']?.toString() ?? '1') ?? 1.0;
            final total = double.tryParse(item['netTotal']?.toString() ?? item['total']?.toString() ?? '0') ?? 0.0;
            final cost = double.tryParse(item['costPrice']?.toString() ?? '0') ?? 0.0;

            if (!aggregated.containsKey(name)) {
              aggregated[name] = {
                'name': name,
                'units': 0,
                'revenue': 0.0,
                'cost': 0.0,
              };
            }
            aggregated[name]!['units'] = (aggregated[name]!['units'] as int) + qty.toInt();
            aggregated[name]!['revenue'] = (aggregated[name]!['revenue'] as double) + total;
            aggregated[name]!['cost'] = (aggregated[name]!['cost'] as double) + (cost * qty);
          }
        }
      }
    }

    final list = aggregated.values.map((p) {
      final rev = p['revenue'] as double;
      final cost = p['cost'] as double;
      final marginPct = rev > 0 ? (((rev - cost) / rev) * 100).clamp(0, 100).toStringAsFixed(1) : '0.0';
      return {
        'name': p['name'] as String,
        'units': p['units'] as int,
        'revenue': rev,
        'margin': '$marginPct%',
      };
    }).toList();

    list.sort((a, b) => (b['units'] as int).compareTo(a['units'] as int));
    return list.take(6).toList();
  }

  Future<void> _printSummaryReport() async {
    final metrics = _getReportMetrics();
    final branchTitle = _selectedBranchScope == 'global' ? 'ALL BRANCHES (GLOBAL ORG)' : widget.currentBranchName;
    final topProducts = _getTopSellingProducts();

    final reportSale = {
      'storeName': widget.organizationName,
      'branchName': branchTitle,
      'tillNumber': 'REPORT-AUDIT',
      'receiptNo': 'RPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      'cashier': 'Store Administrator',
      'dateTime': DateTime.now(),
      'items': topProducts.map((p) => {
        'id': p['name'],
        'name': p['name'],
        'unitPrice': (p['units'] as int) > 0 ? (p['revenue'] as double) / (p['units'] as int) : 0.0,
        'quantity': (p['units'] as int).toDouble(),
        'taxRate': 16.0,
      }).toList(),
      'subtotal': metrics['grossSales'],
      'discount': metrics['discount'],
      'tax': metrics['vatCollected'],
      'total': metrics['grossSales'],
      'paymentMethod': 'SUMMARY (M-PESA/CASH/CARD)',
      'amountPaid': metrics['grossSales'],
      'change': 0.0,
      'mpesaCode': 'AUDIT-SUMMARY-${_selectedDateRange.toUpperCase()}',
    };

    final ok = await PrintingService.instance.printReceipt(reportSale, silent: false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? 'Financial Summary Report dispatched to thermal printer!'
              : 'Failed to print report.'),
          backgroundColor: ok ? AppColors.success : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _getReportMetrics();
    final topProducts = _getTopSellingProducts();
    final currentBranchValue = _branches.any((b) => b['id'] == _selectedBranchScope)
        ? _selectedBranchScope
        : 'global';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Branch Scope Selector
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: DropdownButton<String>(
                      value: currentBranchValue,
                      underline: const SizedBox(),
                      dropdownColor: AppColors.surface(context),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                      items: _branches.map((b) {
                        return DropdownMenuItem<String>(
                          value: b['id'],
                          child: Text(b['name'] ?? b['id']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBranchScope = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Date Range Segmented
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      children: [
                        _buildDatePill('today', 'Today'),
                        _buildDatePill('yesterday', 'Yesterday'),
                        _buildDatePill('week', 'Last 7 Days'),
                        _buildDatePill('month', 'This Month'),
                      ],
                    ),
                  ),
                ],
              ),

              // Export / Print Branded Report Button
              ElevatedButton.icon(
                onPressed: _printSummaryReport,
                icon: const Icon(LucideIcons.printer, size: 16),
                label: const Text('Print Branded Report'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Primary Financial KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'GROSS STORE REVENUE',
                  value: Formatters.formatCurrency(metrics['grossSales'] as double),
                  subtitle: (metrics['ordersCount'] as int) > 0
                      ? '${metrics['ordersCount']} orders recorded'
                      : 'No sales recorded yet',
                  icon: LucideIcons.trendingUp,
                  iconColor: AppColors.primary,
                  isPositive: (metrics['ordersCount'] as int) > 0,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: '16% VAT COLLECTED',
                  value: Formatters.formatCurrency(metrics['vatCollected'] as double),
                  subtitle: 'KRA eTIMS Fiscal Tax',
                  icon: LucideIcons.receipt,
                  iconColor: const Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: 'CHECKOUT TRANSACTIONS',
                  value: '${metrics['ordersCount']} receipts',
                  subtitle: (metrics['ordersCount'] as int) > 0
                      ? 'Avg: ${Formatters.formatCurrency(metrics['avgBasket'] as double)} / basket'
                      : '0 receipts processed',
                  icon: LucideIcons.shoppingBag,
                  iconColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetricCard(
                  title: 'M-PESA REVENUE SHARE',
                  value: Formatters.formatCurrency(metrics['mpesaSales'] as double),
                  subtitle: '${metrics['mpesaPct']}% of total tenders',
                  icon: LucideIcons.smartphone,
                  iconColor: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Payment Tender Breakdown & Velocity Chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Breakdown Card
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Tender Distribution',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time breakdown of customer payment channels',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                      ),
                      const SizedBox(height: 20),

                      // M-Pesa Row
                      _buildTenderRow(
                        name: 'Safaricom M-Pesa STK Push',
                        amount: metrics['mpesaSales'] as double,
                        pct: metrics['mpesaPct'] as int,
                        color: const Color(0xFF10B981),
                        icon: LucideIcons.smartphone,
                      ),
                      const SizedBox(height: 14),

                      // Cash Row
                      _buildTenderRow(
                        name: 'Till Cash Drawer',
                        amount: metrics['cashSales'] as double,
                        pct: metrics['cashPct'] as int,
                        color: AppColors.primary,
                        icon: LucideIcons.banknote,
                      ),
                      const SizedBox(height: 14),

                      // Card Row
                      _buildTenderRow(
                        name: 'Visa / Mastercard Terminal',
                        amount: metrics['cardSales'] as double,
                        pct: metrics['cardPct'] as int,
                        color: const Color(0xFF8B5CF6),
                        icon: LucideIcons.creditCard,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Top High Velocity SKUs
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Top Velocity Supermarket SKUs',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
                              ),
                              Text(
                                'Highest volume products rung up across till registers',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Top 6 Live', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      topProducts.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(LucideIcons.shoppingBag, size: 36, color: AppColors.textMuted(context)),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No Sales Transactions Recorded Yet',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Top-selling items and margins will populate as checkout orders are processed.',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Table(
                              columnWidths: const {
                                0: FlexColumnWidth(4),
                                1: FlexColumnWidth(2),
                                2: FlexColumnWidth(2.5),
                                3: FlexColumnWidth(1.5),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    border: Border(bottom: BorderSide(color: AppColors.border(context))),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text('PRODUCT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text('UNITS', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text('REVENUE', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text('MARGIN', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                    ),
                                  ],
                                ),
                                ...topProducts.map((p) => TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(p['name'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text('${p['units']} sold', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(Formatters.formatCurrency(p['revenue'] as double), textAlign: TextAlign.right, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(p['margin'] as String, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                                    ),
                                  ],
                                )),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePill(String key, String label) {
    final isSelected = _selectedDateRange == key;
    return InkWell(
      onTap: () => setState(() => _selectedDateRange = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    bool? isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.8),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isPositive == true ? AppColors.success : AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenderRow({
    required String name,
    required double amount,
    required int pct,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
                ),
              ],
            ),
            Text(
              '${Formatters.formatCurrency(amount)} ($pct%)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (pct / 100.0).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.border(context),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
