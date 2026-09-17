import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/network/api_service.dart';

class OutletsScreen extends StatefulWidget {
  final String? currentBranchId;
  final String currentBranchName;
  final Function(String newBranchId, String newBranchName)? onSwitchBranch;

  const OutletsScreen({
    super.key,
    this.currentBranchId,
    this.currentBranchName = 'Central Branch',
    this.onSwitchBranch,
  });

  @override
  State<OutletsScreen> createState() => _OutletsScreenState();
}

class _OutletsScreenState extends State<OutletsScreen> {
  String _selectedTab = 'branches'; // 'branches', 'tills', 'sync_status'
  
  List<Map<String, dynamic>> _branches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoading = true);
    try {
      final dbBranches = await ApiService().getBranches();
      if (dbBranches.isNotEmpty) {
        // Query live devices from PostgreSQL
        List<dynamic> allDevices = [];
        try {
          allDevices = await ApiService().getDevices();
        } catch (_) {}

        final mapped = dbBranches.map((b) {
          final item = Map<String, dynamic>.from(b as Map);
          final bName = (item['name'] ?? 'Branch').toString();
          final bCode = (item['code'] ?? 'BR').toString();
          final bLocation = (item['address'] ?? '').toString();
          final bPhone = (item['phone'] ?? '').toString();
          final isHQ = bCode.toUpperCase() == 'HQ' ||
              bName.toLowerCase().contains('hq') ||
              bName.toLowerCase().contains('central') ||
              bName.toLowerCase().contains('main');
          final id = (item['id'] ?? '').toString();

          // Only real registered devices for this branch
          final branchDevices = allDevices.where((d) {
            final dev = Map<String, dynamic>.from(d as Map);
            return (dev['branch_id'] ?? '').toString() == id;
          }).map((d) {
            final dev = Map<String, dynamic>.from(d as Map);
            return {
              'code': (dev['device_uuid'] ?? dev['device_name'] ?? 'TILL').toString(),
              'name': (dev['device_name'] ?? 'Register Lane').toString(),
              'cashier': 'Cashier',
              'status': (dev['sync_status'] ?? 'Online').toString(),
            };
          }).toList();

          return {
            'id': id,
            'dbId': id,
            'name': bName,
            'shortName': bName.split(' ').first,
            'code': bCode,
            'isHQ': isHQ,
            'location': bLocation,
            'manager': '',
            'phone': bPhone,
            'taxPin': '',
            'mpesaPaybill': '',
            'mpesaAccount': bCode,
            'receiptHeader': '$bName\n$bLocation',
            'receiptFooter': 'Thank you for shopping with us!',
            'tillLanes': branchDevices,
            'activeModules': ['cashier', 'storekeeping', 'accounting', 'hr_management', 'pos_outlets'],
            'todaySales': 0.0,
            'todayOrders': 0,
            'stockSkus': 0,
          };
        }).toList();

        if (mounted) {
          setState(() {
            _branches = mapped;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _branches = [];
        _isLoading = false;
      });
    }
  }

  // Reusable Form Field for Modals
  Widget _buildDialogField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hintText,
    IconData? prefixIcon,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted(context),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 16, color: AppColors.primary)
                : null,
            filled: true,
            fillColor: isDark ? AppColors.darkCard : const Color(0xFFF9F9F7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // 1. Branch Configuration Dialog
  void _openConfigureBranchDialog(Map<String, dynamic> branch) {
    final nameController = TextEditingController(text: branch['name']);
    final locationController = TextEditingController(text: branch['location']);
    final managerController = TextEditingController(text: branch['manager']);
    final phoneController = TextEditingController(text: branch['phone']);
    final paybillController = TextEditingController(text: branch['mpesaPaybill']);
    final accountController = TextEditingController(text: branch['mpesaAccount']);
    final headerController = TextEditingController(text: branch['receiptHeader']);
    final footerController = TextEditingController(text: branch['receiptFooter']);
    final taxPinController = TextEditingController(text: branch['taxPin']);

    final List<Map<String, String>> tills = List<Map<String, String>>.from(
      (branch['tillLanes'] as List).map((t) => Map<String, String>.from(t as Map)),
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.border(context)),
          ),
          child: Container(
            width: 640,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (Pinned)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.store, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Configure ${branch['shortName']}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary(context),
                                ),
                              ),
                              Text(
                                branch['isHQ'] == true
                                    ? 'Supermarket Headquarters & Main Hub'
                                    : 'Branch Store & Till Network',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (branch['isHQ'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CENTRAL HQ',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.border(context)),

                // Body (Scrollable)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: General Branch Info
                        const Text(
                          'BRANCH PROFILE & LOCATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDialogField(
                          context: context,
                          controller: nameController,
                          label: 'Branch Display Name *',
                          hintText: 'e.g. KERICHO HQ',
                          prefixIcon: LucideIcons.store,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildDialogField(
                                context: context,
                                controller: locationController,
                                label: 'Physical Location Address',
                                hintText: 'e.g. Primary Branch Headquarters',
                                prefixIcon: LucideIcons.mapPin,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _buildDialogField(
                                context: context,
                                controller: taxPinController,
                                label: 'KRA Tax PIN',
                                hintText: 'e.g. P051234567Z',
                                prefixIcon: LucideIcons.fileText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogField(
                                context: context,
                                controller: managerController,
                                label: 'Branch Supervisor / Manager',
                                hintText: 'e.g. Shift Supervisor',
                                prefixIcon: LucideIcons.user,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogField(
                                context: context,
                                controller: phoneController,
                                label: 'Branch Phone Number',
                                hintText: 'e.g. +254 700 000 000',
                                prefixIcon: LucideIcons.phone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // Section 2: M-Pesa & Till Payment Configuration
                        const Text(
                          'M-PESA SETTLEMENT & TILL LANES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDialogField(
                                context: context,
                                controller: paybillController,
                                label: 'M-Pesa Paybill / Buy Goods',
                                hintText: 'e.g. 247247 or Till No.',
                                prefixIcon: LucideIcons.creditCard,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDialogField(
                                context: context,
                                controller: accountController,
                                label: 'Account Reference Code',
                                hintText: 'e.g. KERICHO-01',
                                prefixIcon: LucideIcons.hash,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Till Lanes List
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active Checkout Lanes (${tills.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  final nextNum = tills.length + 1;
                                  tills.add({
                                    'code': 'TILL-0$nextNum',
                                    'name': 'Lane 0$nextNum (Checkout Register)',
                                    'cashier': 'Unassigned',
                                    'status': 'Online',
                                  });
                                });
                              },
                              icon: const Icon(LucideIcons.plus, size: 14),
                              label: const Text('Add Till Lane', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          child: Column(
                            children: List.generate(tills.length, (idx) {
                              final t = tills[idx];
                              return ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t['code'] ?? 'TILL',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                                  ),
                                ),
                                title: Text(
                                  t['name'] ?? '',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
                                ),
                                subtitle: Text(
                                  'Default Cashier: ${t['cashier']}',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.danger),
                                  onPressed: tills.length > 1
                                      ? () {
                                          setDialogState(() => tills.removeAt(idx));
                                        }
                                      : null,
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Section 3: Receipt Template
                        const Text(
                          '80MM THERMAL RECEIPT HEADERS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDialogField(
                          context: context,
                          controller: headerController,
                          label: 'Top Receipt Header Text',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 10),
                        _buildDialogField(
                          context: context,
                          controller: footerController,
                          label: 'Bottom Receipt Footer Greeting',
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: AppColors.border(context)),

                // Footer Actions (Pinned)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final newName = nameController.text.trim();
                          final newLoc = locationController.text.trim();
                          final newPhone = phoneController.text.trim();
                          final bId = (branch['dbId'] ?? branch['id'] ?? '').toString();

                          setState(() {
                            branch['name'] = newName;
                            branch['location'] = newLoc;
                            branch['manager'] = managerController.text.trim();
                            branch['phone'] = newPhone;
                            branch['taxPin'] = taxPinController.text.trim();
                            branch['mpesaPaybill'] = paybillController.text.trim();
                            branch['mpesaAccount'] = accountController.text.trim();
                            branch['receiptHeader'] = headerController.text.trim();
                            branch['receiptFooter'] = footerController.text.trim();
                            branch['tillLanes'] = tills;
                          });
                          Navigator.pop(ctx);

                          if (bId.isNotEmpty && !bId.startsWith('b')) {
                            try {
                              await ApiService().updateBranch(
                                id: bId,
                                name: newName,
                                address: newLoc,
                                phone: newPhone,
                              );
                              // Register tills directly into PostgreSQL devices table
                              for (final t in tills) {
                                final tCode = (t['code'] ?? '').trim();
                                final tName = (t['name'] ?? '').trim();
                                if (tCode.isNotEmpty && tName.isNotEmpty) {
                                  try {
                                    await ApiService().registerDevice(
                                      branchId: bId,
                                      deviceName: tName,
                                      deviceUuid: tCode,
                                      deviceType: 'POS_REGISTER',
                                    );
                                  } catch (_) {}
                                }
                              }
                              await _loadBranches();
                            } catch (_) {}
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Configuration saved for ${branch['shortName']}!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.check, size: 16),
                        label: const Text('Save Branch Configuration'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. Add New Supermarket Branch Dialog
  void _openAddBranchDialog() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final managerController = TextEditingController();
    final phoneController = TextEditingController();
    final paybillController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border(context)),
        ),
        child: Container(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.store, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Register New Branch',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                            Text(
                              'Provision checkout lanes and stockroom',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary(context)),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.border(context)),

              // Form Body
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildDialogField(
                      context: context,
                      controller: nameController,
                      label: 'Branch Name *',
                      hintText: 'e.g. Eldoret Mega Supermarket',
                      prefixIcon: LucideIcons.store,
                    ),
                    const SizedBox(height: 14),
                    _buildDialogField(
                      context: context,
                      controller: locationController,
                      label: 'Physical Address *',
                      hintText: 'e.g. Rupa Mall, Uganda Road, Eldoret',
                      prefixIcon: LucideIcons.mapPin,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDialogField(
                            context: context,
                            controller: managerController,
                            label: 'Branch Manager',
                            hintText: 'e.g. John Kiprop',
                            prefixIcon: LucideIcons.user,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDialogField(
                            context: context,
                            controller: phoneController,
                            label: 'Phone Number',
                            hintText: 'e.g. +254 711 000 111',
                            prefixIcon: LucideIcons.phone,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppColors.border(context)),

              // Footer Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        final loc = locationController.text.trim();
                        final phone = phoneController.text.trim();
                        final code = 'BR-${name.split(' ').first.toUpperCase()}';

                        Navigator.pop(ctx);
                        try {
                          await ApiService().createBranch(
                            name: name,
                            code: code,
                            address: loc.isNotEmpty ? loc : 'Branch Location',
                            phone: phone.isNotEmpty ? phone : null,
                          );
                          await _loadBranches();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Branch "$name" created in database!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save branch: $e'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Create & Provision Branch'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalOrgSales = 0;
    int totalOrgOrders = 0;
    int totalTills = 0;
    for (var b in _branches) {
      totalOrgSales += (b['todaySales'] as num).toDouble();
      totalOrgOrders += (b['todayOrders'] as int);
      totalTills += (b['tillLanes'] as List).length;
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Branches & Till Network', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context))),
                    Text('Configure Central HQ, Outlets, Checkout Lanes & M-Pesa Tills • Active: ${widget.currentBranchName}', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _openAddBranchDialog,
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('Register New Branch'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Top KPI Summary Cards
            Row(
              children: [
                _buildSummaryKpiCard(
                  title: 'ORGANIZATION REVENUE (TODAY)',
                  value: Formatters.formatCurrency(totalOrgSales),
                  sub: '$totalOrgOrders Total Checkouts across ${_branches.length} Branches',
                  icon: LucideIcons.badgePercent,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 16),
                _buildSummaryKpiCard(
                  title: 'TOTAL REGISTER LANES',
                  value: '$totalTills Active Tills',
                  sub: 'Central HQ & Outlet Network',
                  icon: LucideIcons.monitor,
                  color: const Color(0xFF0EA5E9),
                ),
                const SizedBox(width: 16),
                _buildSummaryKpiCard(
                  title: 'CENTRAL HQ STATUS',
                  value: widget.currentBranchName,
                  sub: 'Primary Headquarters',
                  icon: LucideIcons.building2,
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Branches Cards Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _branches.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.store, size: 48, color: AppColors.textMuted(context)),
                              const SizedBox(height: 12),
                              Text(
                                'No Supermarket Branches Configured',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Click "Register New Branch" above to add your first store location.',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context)),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  mainAxisExtent: 280,
                ),
                itemCount: _branches.length,
                itemBuilder: (context, index) {
                  final branch = _branches[index];
                  final bool isCurrent = (widget.currentBranchId != null && branch['id'] == widget.currentBranchId) ||
                      branch['name'].toString().toLowerCase() == widget.currentBranchName.toLowerCase() ||
                      branch['name'].toString().contains(widget.currentBranchName) ||
                      widget.currentBranchName.contains(branch['shortName'].toString());
                  final List tills = branch['tillLanes'] as List;

                  return Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent ? AppColors.primary : AppColors.border(context),
                        width: isCurrent ? 2 : 1,
                      ),
                      boxShadow: [
                        if (isCurrent)
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Branch HQ / Outlet Badge + Current Terminal Tag
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: branch['isHQ'] == true ? AppColors.primary.withValues(alpha: 0.15) : AppColors.bg(context),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: branch['isHQ'] == true ? AppColors.primary : AppColors.border(context)),
                                  ),
                                  child: Text(
                                    branch['isHQ'] == true ? 'CENTRAL HQ' : 'BRANCH OUTLET',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: branch['isHQ'] == true ? AppColors.primary : AppColors.textMuted(context),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${tills.length} Till Lanes',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
                                ),
                              ],
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.success),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(LucideIcons.checkCircle2, size: 12, color: AppColors.success),
                                    SizedBox(width: 5),
                                    Text('CURRENT STATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Branch Name & Location
                        Text(
                          branch['name'] as String,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.mapPin, size: 13, color: AppColors.textMuted(context)),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                branch['location'] as String,
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Performance & M-Pesa Grid
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TODAY\'S SALES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textMuted(context))),
                                  Text(Formatters.formatCurrency(branch['todaySales'] as num), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context))),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('M-PESA PAYBILL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textMuted(context))),
                                  Text('${branch['mpesaPaybill']} (${branch['mpesaAccount']})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CHECKOUTS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textMuted(context))),
                                  Text('${branch['todayOrders']} Orders', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                        Divider(height: 1, color: AppColors.border(context)),
                        const SizedBox(height: 10),

                        // Bottom Actions: Configure vs Switch Branch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => _openConfigureBranchDialog(branch),
                              icon: const Icon(LucideIcons.settings, size: 14),
                              label: const Text('Configure Branch & Tills', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                            if (!isCurrent)
                              ElevatedButton(
                                onPressed: () {
                                  final bId = (branch['id'] ?? branch['dbId'] ?? '').toString();
                                  final bName = (branch['name'] ?? 'Branch').toString();
                                  widget.onSwitchBranch?.call(bId, bName);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Active branch context switched to $bName'), backgroundColor: AppColors.success),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                                child: const Text('Switch Terminal Context', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryKpiCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted(context), letterSpacing: 0.8)),
                  const SizedBox(height: 3),
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context))),
                  Text(sub, style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
