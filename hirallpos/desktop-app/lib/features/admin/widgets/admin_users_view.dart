import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/network/api_service.dart';

class AdminUsersView extends StatefulWidget {
  final String organizationName;
  final String branchName;
  final String? branchId;

  const AdminUsersView({
    super.key,
    required this.organizationName,
    required this.branchName,
    this.branchId,
  });

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  String _searchQuery = '';
  String _selectedRoleFilter = 'all';

  static const Map<String, String> _roleDisplayMap = {
    'Branch Supervisor / Manager': 'branch_manager',
    'Organization Owner (Admin)': 'owner',
    'Counter Till Cashier': 'cashier',
    'Store Accountant / Auditor': 'accountant',
    'Storekeeper / Stock Controller': 'storekeeper',
    'Floor Server / Waiter': 'waiter',
  };

  static const List<String> _departmentOptions = [
    'POS Cashier & Checkout',
    'Branch Operations & Management',
    'Storekeeping & Stockroom',
    'Accounting & Financial Audit',
    'Hospitality & Dining Floor',
    'Floor Operations & Logistics',
  ];

  static const List<String> _tillLaneOptions = [
    'Lane 01 (Main Register)',
    'Lane 02 (Express Register)',
    'Management Station',
    'Audit Terminal',
    'Stockroom Intake',
    'All Lanes',
  ];

  List<Map<String, dynamic>> _staffList = [];

  @override
  void initState() {
    super.initState();
    _loadPersistedStaff();
  }

  bool _isLoading = false;
  bool _isDatabaseConnected = false;

  Future<void> _loadPersistedStaff() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final branchKey = 'hirall_branch_staff_${widget.branchName}';

    // 1. Fetch real staff from PostgreSQL database on backend
    try {
      final dbUsers = await ApiService().getUsers();
      if (dbUsers.isNotEmpty) {
        final List<Map<String, dynamic>> mapped = [];
        for (int i = 0; i < dbUsers.length; i++) {
          final u = dbUsers[i];
          final rawRole = (u['role'] ?? 'staff').toString().toLowerCase();
          String role = 'cashier';
          if (rawRole.contains('owner') || rawRole.contains('admin') || rawRole.contains('superadmin')) {
            role = 'owner';
          } else if (rawRole.contains('manager') || rawRole.contains('supervisor')) {
            role = 'branch_manager';
          } else if (rawRole.contains('accountant') || rawRole.contains('auditor')) {
            role = 'accountant';
          } else if (rawRole.contains('storekeeper') || rawRole.contains('inventory')) {
            role = 'storekeeper';
          } else if (rawRole.contains('waiter') || rawRole.contains('server')) {
            role = 'waiter';
          }

          final empNum = u['employee_number']?.toString() ?? 'EMP-${(i + 1).toString().padLeft(3, '0')}';
          final fullName = (u['name'] ?? 'Staff Member').toString();
          final phone = (u['phone'] ?? '').toString();
          final email = (u['email'] ?? '').toString();
          final department = u['department']?.toString() ??
              (role == 'owner' || role == 'branch_manager'
                  ? 'Branch Operations & Management'
                  : role == 'accountant'
                      ? 'Accounting & Financial Audit'
                      : role == 'storekeeper'
                          ? 'Storekeeping & Stockroom'
                          : role == 'waiter'
                              ? 'Hospitality & Dining Floor'
                              : 'POS Cashier & Checkout');
          final tillLane = u['till_lane']?.toString() ??
              (role == 'cashier'
                  ? 'Lane 01 (Main Register)'
                  : role == 'owner' || role == 'branch_manager'
                      ? 'Management Station'
                      : role == 'accountant'
                          ? 'Audit Terminal'
                          : role == 'storekeeper'
                              ? 'Stockroom Intake'
                              : 'All Lanes');
          final hasPin = u['has_pin'] == true;
          final status = (u['status'] ?? 'ACTIVE').toString().toUpperCase();

          mapped.add({
            'dbId': u['id']?.toString(),
            'id': empNum,
            'fullName': fullName,
            'name': fullName,
            'email': email,
            'phone': phone,
            'role': role,
            'department': department,
            'tillLane': tillLane,
            'station': tillLane,
            'pin': hasPin ? '••••' : 'N/A',
            'authCode': hasPin ? 'SET' : 'N/A',
            'isActive': status == 'ACTIVE',
            'todaySales': 0.0,
            'todayTransactions': 0,
            'voidsCount': 0,
            'lastActive': status == 'ACTIVE' ? 'Active in Database' : 'Disabled',
            'hourlyRate': 0.0,
            'shift': 'Full Shift',
            'clockIn': '08:00 AM',
            'hoursToday': '0.0h',
            'isOnDuty': status == 'ACTIVE',
          });
        }

        await prefs.setString(branchKey, jsonEncode(mapped));

        if (mounted) {
          setState(() {
            _staffList = mapped;
            _isDatabaseConnected = true;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    // 2. Offline fallback: load local storage and purge any legacy mock staff
    try {
      final savedJson = prefs.getString(branchKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(savedJson);
        final filtered = decoded
            .map((e) => Map<String, dynamic>.from(e))
            .where((s) {
              final name = (s['fullName'] ?? s['name'] ?? '').toString().toLowerCase();
              return !name.contains('faith chepkemoi') &&
                  !name.contains('dennis kipkoech') &&
                  !name.contains('kevin kiprotich') &&
                  !name.contains('store manager') &&
                  !name.contains('giftmart super-admin');
            })
            .toList();

        if (mounted) {
          setState(() {
            _staffList = filtered;
            _isDatabaseConnected = false;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _staffList = [];
        _isDatabaseConnected = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _persistStaff() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('hirall_branch_staff_${widget.branchName}', jsonEncode(_staffList));
    } catch (_) {}
  }

  String _generateFiveCharCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = Random.secure();
    return List.generate(5, (_) => chars[random.nextInt(chars.length)]).join();
  }

  static String _safeBarcodeData(dynamic raw, {String fallback = 'STAFF'}) {
    final cleanFallback = fallback.replaceAll(RegExp(r'[^A-Za-z0-9\-_]'), '').toUpperCase();
    final effectiveFallback = cleanFallback.isNotEmpty ? cleanFallback : 'STAFF';
    if (raw == null) return effectiveFallback;
    final str = raw.toString().trim();
    if (str.contains('•') || str.contains('·') || str.contains('*') || str.isEmpty) {
      return effectiveFallback;
    }
    final cleaned = str.replaceAll(RegExp(r'[^A-Za-z0-9\-_]'), '').toUpperCase();
    if (cleaned.isEmpty) {
      return effectiveFallback;
    }
    return cleaned;
  }

  void _showBadgeDialog(Map<String, dynamic> staff) {
    final rawAuth = (staff['authCode'] ?? '').toString().trim();
    final rawPin = (staff['pin'] ?? '').toString().trim();
    final fullName = (staff['fullName'] ?? staff['name'] ?? 'Staff Member').toString();
    final roleName = _formatRoleName(staff['role'] as String? ?? 'staff');
    final empId = (staff['id'] ?? '').toString();

    final bool hasValidCustomCode = !rawAuth.contains('•') && rawAuth != 'SET' && rawAuth != 'N/A' && rawAuth.isNotEmpty;
    final bool hasValidPinCode = !rawPin.contains('•') && rawPin != 'N/A' && rawPin.isNotEmpty;
    final displayCode = hasValidCustomCode
        ? rawAuth.toUpperCase()
        : hasValidPinCode
            ? rawPin.toUpperCase()
            : (empId.isNotEmpty ? empId.toUpperCase() : 'STAFF');
    final barcodeData = _safeBarcodeData(displayCode, fallback: 'STAFF');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.organizationName.toUpperCase(),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 0.5),
                          ),
                          Text(
                            '${widget.branchName.toUpperCase()} • SECURITY BADGE',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(LucideIcons.x, size: 18, color: Colors.black54),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Staff Details
              Text(
                fullName,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.black),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  roleName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'ID: $empId • ${staff['tillLane'] ?? 'Main Terminal'}',
                style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),

              // Scannable Barcode Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
                child: Column(
                  children: [
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: barcodeData,
                      width: 240,
                      height: 70,
                      drawText: false,
                      errorBuilder: (context, error) => const SizedBox(
                        width: 240,
                        height: 70,
                        child: Center(
                          child: Text(
                            'STAFF BADGE BARCODE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      displayCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        letterSpacing: 6,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'Scan this barcode directly with a laser scanner or enter the code at any POS till for authorization.',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, height: 1.3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: displayCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied code "$displayCode" to clipboard!'),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.copy, size: 14),
                      label: const Text('COPY CODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(LucideIcons.check, size: 14),
                      label: const Text('DONE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateAndFormatKenyanPhone(String input) {
    String digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('254') && digits.length == 12) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0') && digits.length == 10) {
      digits = digits.substring(1);
    }

    if (digits.length != 9 || (!digits.startsWith('7') && !digits.startsWith('1'))) {
      return null;
    }

    return '+254 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  void _confirmDeleteStaff(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: BorderSide(color: AppColors.border(context), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(LucideIcons.trash2, color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            Text(
              'DELETE RECORD: ${staff['id'] ?? ""}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        content: Text(
          'Confirm permanent deletion of "${staff['fullName']}" from ${widget.branchName}.\nAll station PINs and credentials will be removed.',
          style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13, height: 1.4),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () {
              final dbId = staff['dbId']?.toString();
              if (dbId != null && dbId.isNotEmpty) {
                ApiService().deleteUser(dbId).catchError((_) => false);
              }
              setState(() {
                _staffList.removeWhere((s) => s['id'] == staff['id'] || (dbId != null && s['dbId'] == dbId));
              });
              _persistStaff();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Staff member "${staff['fullName']}" deleted.'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            child: const Text('CONFIRM DELETE'),
          ),
        ],
      ),
    );
  }

  void _toggleStaffActive(Map<String, dynamic> staff) {
    final isNowActive = !(staff['isActive'] as bool? ?? true);
    setState(() {
      staff['isActive'] = isNowActive;
      staff['isOnDuty'] = isNowActive;
      staff['lastActive'] = isNowActive ? 'Active in Database' : 'Disabled';
    });
    _persistStaff();

    final dbId = staff['dbId']?.toString();
    if (dbId != null && dbId.isNotEmpty) {
      ApiService().updateUser(
        id: dbId,
        status: isNowActive ? 'ACTIVE' : 'DISABLED',
      ).catchError((_) => <String, dynamic>{});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isNowActive
            ? 'Staff "${staff['fullName']}" ACTIVATED.'
            : 'Staff "${staff['fullName']}" DEACTIVATED.'),
        backgroundColor: isNowActive ? AppColors.success : AppColors.warning,
      ),
    );
  }

  void _openAddOrEditUserDialog([Map<String, dynamic>? existingUser]) {
    final isEditing = existingUser != null;
    final empIdController = TextEditingController(text: isEditing ? existingUser['id'] : 'EMP-00${_staffList.length + 1}');
    final nameController = TextEditingController(text: isEditing ? existingUser['fullName'] : '');

    String rawPhone = '';
    if (isEditing && existingUser['phone'] != null) {
      final clean = existingUser['phone'].toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (clean.startsWith('254') && clean.length == 12) {
        rawPhone = clean.substring(3);
      } else {
        rawPhone = clean;
      }
    }
    final phoneController = TextEditingController(text: rawPhone);
    final emailController = TextEditingController(text: isEditing ? existingUser['email'] : '');
    final rawExistingCode = (existingUser?['authCode'] ?? existingUser?['pin'] ?? '').toString().trim();
    final bool hasUsableCode = !rawExistingCode.contains('•') &&
        rawExistingCode != 'SET' &&
        rawExistingCode != 'N/A' &&
        rawExistingCode.length == 5;
    final initialCode = isEditing
        ? (hasUsableCode ? rawExistingCode.toUpperCase() : _generateFiveCharCode())
        : _generateFiveCharCode();
    final pinController = TextEditingController(text: initialCode);
    String selectedDepartment = isEditing ? (existingUser['department'] ?? '') : '';
    String role = isEditing ? (existingUser['role'] ?? '') : '';
    String tillLane = isEditing ? (existingUser['tillLane'] ?? '') : '';
    bool isActive = isEditing ? (existingUser['isActive'] ?? true) : true;
    bool obscurePin = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: BorderSide(color: AppColors.border(context), width: 1.5),
          ),
          child: Container(
            width: 940, // BROAD SCREEN-PAINTER ERP MATRIX
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.94),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                    border: Border(bottom: BorderSide(color: AppColors.border(context), width: 1.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.layoutGrid, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            isEditing
                                ? 'Screen Painter: Change Staff Profile [${existingUser['id'] ?? ""}] - ${widget.branchName}'
                                : 'Screen Painter: Staff Profile & Station PIN - ${widget.branchName}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary(context)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Form Matrix
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // LEFT FRAME
                            Expanded(
                              child: _buildGroupBox(
                                context: context,
                                title: '01. Staff Identity & Communication',
                                child: Column(
                                  children: [
                                    _buildAlignedRow(
                                      context: context,
                                      label: 'Staff ID:',
                                      input: SizedBox(
                                        width: 140,
                                        child: TextField(
                                          controller: empIdController,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                                          decoration: _buildMechanicalInputDecoration(hint: 'EMP-009'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    _buildAlignedRow(
                                      context: context,
                                      label: 'Full Name:',
                                      input: Expanded(
                                        child: TextField(
                                          controller: nameController,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          decoration: _buildMechanicalInputDecoration(hint: 'e.g. John Doe'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    _buildAlignedRow(
                                      context: context,
                                      label: 'Phone (9 Digits):',
                                      input: Expanded(
                                        child: TextField(
                                          controller: phoneController,
                                          maxLength: 9,
                                          keyboardType: TextInputType.phone,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                                          decoration: InputDecoration(
                                            prefixText: '+254 ',
                                            prefixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'monospace'),
                                            hintText: '712345678',
                                            counterText: '',
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            isDense: true,
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(2)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    _buildAlignedRow(
                                      context: context,
                                      label: 'Work Email:',
                                      input: Expanded(
                                        child: TextField(
                                          controller: emailController,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: _buildMechanicalInputDecoration(hint: 'staff@store.local'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // RIGHT FRAME: 02. STORE ROLE & ASSIGNED TERMINAL LANE
                            Expanded(
                              child: _buildGroupBox(
                                context: context,
                                title: '02. Store Role & Assigned Terminal Lane',
                                child: Column(
                                  children: [
                                    _buildAlignedRow(
                                      context: context,
                                      label: 'Department:',
                                      input: Expanded(
                                        child: SearchableAutocompleteField(
                                          initialValue: selectedDepartment,
                                          hint: 'Search & select department...',
                                          icon: LucideIcons.building,
                                          options: _departmentOptions,
                                          onSelected: (val) => setDialogState(() => selectedDepartment = val),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    _buildAlignedRow(
                                      context: context,
                                      label: 'System Role:',
                                      input: Expanded(
                                        child: SearchableAutocompleteField(
                                          initialValue: role.isEmpty
                                              ? ''
                                              : _roleDisplayMap.entries
                                                  .firstWhere((e) => e.value == role, orElse: () => MapEntry(role, role))
                                                  .key,
                                          hint: 'Search & select role (e.g. Supervisor, Cashier)...',
                                          icon: LucideIcons.shieldCheck,
                                          options: _roleDisplayMap.keys.toList(),
                                          onSelected: (val) {
                                            setDialogState(() {
                                              role = _roleDisplayMap[val] ?? val;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    _buildAlignedRow(
                                      context: context,
                                      label: 'Till Lane:',
                                      input: Expanded(
                                        child: SearchableAutocompleteField(
                                          initialValue: tillLane,
                                          hint: 'Search & select till lane...',
                                          icon: LucideIcons.monitor,
                                          options: _tillLaneOptions,
                                          onSelected: (val) => setDialogState(() => tillLane = val),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // FULL-WIDTH FRAME 03: 5-CHARACTER AUTHORIZATION CODE & SCANNABLE BARCODE
                        _buildGroupBox(
                          context: context,
                          title: '03. 5-Character Authorization Code & Scannable Badge',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 120,
                                    child: Text(
                                      '5-Char Code:',
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 130,
                                    child: TextField(
                                      controller: pinController,
                                      maxLength: 5,
                                      obscureText: obscurePin,
                                      textCapitalization: TextCapitalization.characters,
                                      textAlign: TextAlign.center,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                                        LengthLimitingTextInputFormatter(5),
                                      ],
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4, fontFamily: 'monospace'),
                                      decoration: InputDecoration(
                                        hintText: 'K7M9X',
                                        counterText: '',
                                        isDense: true,
                                        prefixIcon: const Icon(LucideIcons.keyRound, size: 14),
                                        suffixIcon: IconButton(
                                          icon: Icon(obscurePin ? LucideIcons.eyeOff : LucideIcons.eye, size: 14),
                                          onPressed: () => setDialogState(() => obscurePin = !obscurePin),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(2)),
                                      ),
                                      onChanged: (val) {
                                        final up = val.toUpperCase();
                                        if (up != val) {
                                          pinController.value = pinController.value.copyWith(
                                            text: up,
                                            selection: TextSelection.collapsed(offset: up.length),
                                          );
                                        }
                                        setDialogState(() {});
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    onPressed: () {
                                      final newCode = _generateFiveCharCode();
                                      setDialogState(() {
                                        pinController.text = newCode;
                                        obscurePin = false;
                                      });
                                    },
                                    icon: const Icon(LucideIcons.refreshCw, size: 13),
                                    label: const Text('AUTO-GENERATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const Text('Authority: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isActive ? AppColors.success.withValues(alpha: 0.15) : AppColors.danger.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(2),
                                          border: Border.all(color: isActive ? AppColors.success : AppColors.danger),
                                        ),
                                        child: Text(
                                          isActive ? 'ACTIVE / AUTHORIZED' : 'DEACTIVATED / BLOCKED',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'monospace',
                                            color: isActive ? AppColors.success : AppColors.danger,
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: isActive,
                                        activeThumbColor: AppColors.success,
                                        onChanged: (val) => setDialogState(() => isActive = val),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Second Row: Scannable Barcode Preview
                              if (pinController.text.trim().isNotEmpty)
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 120,
                                      child: Text(
                                        'Scannable Badge:',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.grey.shade400),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          BarcodeWidget(
                                            barcode: Barcode.code128(),
                                            data: _safeBarcodeData(pinController.text.trim().toUpperCase(), fallback: 'CODE'),
                                            width: 140,
                                            height: 34,
                                            drawText: false,
                                            errorBuilder: (context, error) => const SizedBox(
                                              width: 140,
                                              height: 34,
                                              child: Center(
                                                child: Text('BARCODE PREVIEW', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                'LASER SCANNABLE CODE',
                                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black54, letterSpacing: 0.5),
                                              ),
                                              Text(
                                                pinController.text.trim().toUpperCase(),
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black, fontFamily: 'monospace', letterSpacing: 2),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        'Laser scanner can scan this barcode directly from screen or badge printout.',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context), fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: AppColors.border(context), thickness: 1.5),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isEditing)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmDeleteStaff(existingUser);
                          },
                          icon: const Icon(LucideIcons.trash2, size: 14),
                          label: const Text('DELETE RECORD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, fontFamily: 'monospace')),
                        )
                      else
                        const SizedBox(),

                      Row(
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('CANCEL [ESC]', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            ),
                            onPressed: () {
                              final cleanName = nameController.text.trim();
                              final cleanPhoneInput = phoneController.text.trim();
                              final cleanPin = pinController.text.trim();

                              if (cleanName.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a staff name.'), backgroundColor: AppColors.warning),
                                );
                                return;
                              }

                              final formattedPhone = _validateAndFormatKenyanPhone(cleanPhoneInput);
                              if (formattedPhone == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid Kenyan Phone: Must be 9 digits starting with 7 or 1 (e.g. 712 345 678).'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                                return;
                              }

                              final codeUpper = cleanPin.toUpperCase();
                              if (codeUpper.length != 5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter or autogenerate a valid 5-character alphanumeric Code (e.g. K7M9X).'),
                                    backgroundColor: AppColors.warning,
                                  ),
                                );
                                return;
                              }

                              if (role.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please search and select a System Role for this staff member.'),
                                    backgroundColor: AppColors.warning,
                                  ),
                                );
                                return;
                              }

                              final finalDepartment = selectedDepartment.trim().isEmpty ? 'POS Cashier & Checkout' : selectedDepartment.trim();
                              final finalTillLane = tillLane.trim().isEmpty ? 'All Lanes' : tillLane.trim();

                              for (final s in _staffList) {
                                if (isEditing && s['id'] == existingUser['id']) continue;

                                final sName = (s['fullName'] ?? '').toString().trim().toLowerCase();
                                final sPhone = (s['phone'] ?? '').toString().trim();
                                final sPin = (s['pin'] ?? s['authCode'] ?? '').toString().trim().toUpperCase();

                                if (sName == cleanName.toLowerCase() && sPhone == formattedPhone) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Duplicate Staff Error: "$cleanName" with phone "$formattedPhone" is already registered.'),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                  return;
                                }

                                if (sPhone == formattedPhone) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Duplicate Phone Error: Mobile number "$formattedPhone" is already assigned to "${s['fullName']}".'),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                  return;
                                }

                                if (sPin == codeUpper) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Duplicate Code Error: Authorization Code "$codeUpper" is already assigned to "${s['fullName']}".'),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                  return;
                                }
                              }

                              final email = emailController.text.trim().isNotEmpty
                                  ? emailController.text.trim()
                                  : '${cleanName.toLowerCase().replaceAll(' ', '.')}@store.local';

                              setState(() {
                                if (isEditing) {
                                  existingUser['fullName'] = cleanName;
                                  existingUser['name'] = cleanName;
                                  existingUser['phone'] = formattedPhone;
                                  existingUser['email'] = email;
                                  existingUser['pin'] = codeUpper;
                                  existingUser['authCode'] = codeUpper;
                                  existingUser['department'] = finalDepartment;
                                  existingUser['role'] = role;
                                  existingUser['tillLane'] = finalTillLane;
                                  existingUser['station'] = finalTillLane;
                                  existingUser['isActive'] = isActive;

                                  final dbId = existingUser['dbId']?.toString();
                                  if (dbId != null && dbId.isNotEmpty) {
                                    ApiService().updateUser(
                                      id: dbId,
                                      name: cleanName,
                                      phone: formattedPhone,
                                      email: email,
                                      pinCode: (codeUpper.isNotEmpty && !codeUpper.contains('•')) ? codeUpper : null,
                                      status: isActive ? 'ACTIVE' : 'DISABLED',
                                      role: role,
                                      department: finalDepartment,
                                      tillLane: finalTillLane,
                                    ).catchError((_) => <String, dynamic>{});
                                  }
                                } else {
                                  final newStaff = {
                                    'id': empIdController.text.trim(),
                                    'fullName': cleanName,
                                    'name': cleanName,
                                    'phone': formattedPhone,
                                    'email': email,
                                    'department': finalDepartment,
                                    'role': role,
                                    'branch': widget.branchName,
                                    'tillLane': finalTillLane,
                                    'station': finalTillLane,
                                    'pin': codeUpper,
                                    'authCode': codeUpper,
                                    'isActive': isActive,
                                    'todaySales': 0.0,
                                    'todayTransactions': 0,
                                    'voidsCount': 0,
                                    'lastActive': 'Active in Database',
                                    'hourlyRate': 0.0,
                                    'shift': 'Full Shift',
                                    'clockIn': '08:00 AM',
                                    'hoursToday': '0.0h',
                                    'isOnDuty': isActive,
                                  };
                                  _staffList.add(newStaff);

                                  ApiService().createUser(
                                    name: cleanName,
                                    email: email,
                                    phone: formattedPhone,
                                    pinCode: codeUpper.isNotEmpty ? codeUpper : null,
                                    role: role,
                                    employeeNumber: empIdController.text.trim(),
                                    department: finalDepartment,
                                    tillLane: finalTillLane,
                                  ).then((created) {
                                    if (created['id'] != null) {
                                      newStaff['dbId'] = created['id'].toString();
                                      _persistStaff();
                                    }
                                  }).catchError((_) {});
                                }
                              });
                              _persistStaff();

                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEditing
                                      ? 'Staff profile updated!'
                                      : 'Staff "$cleanName" registered with 5-Char Code $codeUpper!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            icon: const Icon(LucideIcons.check, size: 15),
                            label: Text(isEditing ? 'COMMIT [SAVE]' : 'COMMIT [REGISTER]', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, fontFamily: 'monospace')),
                          ),
                        ],
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

  Widget _buildGroupBox({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.border(context), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: AppColors.primary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Divider(height: 1, color: AppColors.border(context), thickness: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildAlignedRow({
    required BuildContext context,
    required String label,
    required Widget input,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        input,
      ],
    );
  }

  InputDecoration _buildMechanicalInputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(2)),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return const Color(0xFF8B5CF6);
      case 'branch_manager':
        return AppColors.primary;
      case 'accountant':
        return const Color(0xFF0EA5E9);
      case 'storekeeper':
        return const Color(0xFFF59E0B);
      case 'cashier':
        return AppColors.success;
      case 'waiter':
        return const Color(0xFFEC4899);
      default:
        return Colors.grey;
    }
  }

  String _formatRoleName(String role) {
    switch (role) {
      case 'owner':
        return 'ORGANIZATION OWNER';
      case 'branch_manager':
        return 'BRANCH SUPERVISOR';
      case 'accountant':
        return 'STORE ACCOUNTANT';
      case 'storekeeper':
        return 'STOREKEEPER';
      case 'cashier':
        return 'TILL CASHIER';
      case 'waiter':
        return 'FLOOR WAITER';
      default:
        return role.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {

    final filteredStaff = _staffList.where((u) {
      final name = (u['fullName'] ?? u['name'] ?? '').toString();
      final phone = (u['phone'] ?? '').toString();
      final email = (u['email'] ?? '').toString();
      final till = (u['tillLane'] ?? u['station'] ?? '').toString();
      final matchesQuery = name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          phone.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          till.toLowerCase().contains(_searchQuery.toLowerCase());
      final role = (u['role'] ?? 'staff').toString().toLowerCase();
      final matchesRole = _selectedRoleFilter == 'all' || role == _selectedRoleFilter;
      return matchesQuery && matchesRole;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Database Status Banner
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _isDatabaseConnected
                ? AppColors.success.withValues(alpha: 0.08)
                : const Color(0xFFF59E0B).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isDatabaseConnected ? AppColors.success.withValues(alpha: 0.3) : const Color(0xFFF59E0B),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isDatabaseConnected ? LucideIcons.database : LucideIcons.alertTriangle,
                size: 16,
                color: _isDatabaseConnected ? AppColors.success : const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isDatabaseConnected
                      ? 'LIVE DATABASE CONNECTED: Staff & PINs loaded directly from PostgreSQL Aurora database.'
                      : 'OFFLINE / BACKEND RESTART REQUIRED: Backend (http://127.0.0.1:8080/api/v1/auth/users) returned 404 because the backend process must be restarted with "cargo run".',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isDatabaseConnected ? AppColors.success : const Color(0xFFB45309),
                  ),
                ),
              ),
              InkWell(
                onTap: _loadPersistedStaff,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.refreshCw, size: 14, color: _isDatabaseConnected ? AppColors.success : const Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        'Refresh DB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _isDatabaseConnected ? AppColors.success : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Controls Row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary(context)),
                decoration: InputDecoration(
                  hintText: 'Search staff by name, phone (+254 7XX...), email, or till...',
                  prefixIcon: const Icon(LucideIcons.search, size: 16),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedRoleFilter,
                dropdownColor: AppColors.surface(context),
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary(context)),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(2)),
                ),
                items: [
                  DropdownMenuItem(value: 'all', child: Text('All Staff Roles', style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: 'owner', child: Text('Owners & Admins', style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: 'branch_manager', child: Text('Branch Supervisors', style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: 'cashier', child: Text('Till Cashiers', style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: 'accountant', child: Text('Accountants', style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: 'storekeeper', child: Text('Storekeepers', style: TextStyle(color: AppColors.textPrimary(context), fontWeight: FontWeight.w600))),
                ],
                onChanged: (val) => setState(() => _selectedRoleFilter = val!),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
              onPressed: () => _openAddOrEditUserDialog(),
              icon: const Icon(LucideIcons.userPlus, size: 16),
              label: const Text('Add Staff & PIN'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Staff Directory Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredStaff.isEmpty
                      ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.users, size: 48, color: AppColors.textMuted(context)),
                          const SizedBox(height: 12),
                          Text(
                            'No Staff Members Registered Yet',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Click "+ Add Staff & PIN" to register branch employees, assign station PINs, and set roles.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2))),
                            onPressed: () => _openAddOrEditUserDialog(),
                            icon: const Icon(LucideIcons.userPlus, size: 16),
                            label: const Text('Register First Employee'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                itemCount: filteredStaff.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border(context)),
                itemBuilder: (context, index) {
                  final staff = filteredStaff[index];
                  final roleStr = (staff['role'] ?? 'cashier').toString().toLowerCase();
                  final roleColor = _getRoleColor(roleStr);
                  final isCashier = roleStr == 'cashier';
                  final isActive = staff['isActive'] == true || (staff['status']?.toString().toUpperCase() == 'ACTIVE');
                  final fullName = (staff['fullName'] ?? staff['name'] ?? 'Staff Member').toString();
                  final initial = fullName.trim().isNotEmpty ? fullName.trim().substring(0, 1).toUpperCase() : 'S';
                  final phone = (staff['phone'] ?? '').toString();
                  final email = (staff['email'] ?? '').toString();
                  final tillLane = (staff['tillLane'] ?? staff['station'] ?? 'All Stations').toString();
                  final lastActive = (staff['lastActive'] ?? (isActive ? 'Active in Database' : 'Disabled')).toString();
                  final todaySales = (staff['todaySales'] as num?)?.toDouble() ?? 0.0;
                  final todayTransactions = (staff['todayTransactions'] as num?)?.toInt() ?? 0;
                  final voidsCount = (staff['voidsCount'] as num?)?.toInt() ?? 0;
                  final pinCode = (staff['pin'] ?? staff['authCode'] ?? 'N/A').toString();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        // Avatar Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isActive ? roleColor.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: isActive ? roleColor.withValues(alpha: 0.3) : AppColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                color: isActive ? roleColor : AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Name & Phone/Email
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isActive ? AppColors.textPrimary(context) : AppColors.textMuted(context),
                                      decoration: isActive ? TextDecoration.none : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.success.withValues(alpha: 0.12)
                                          : AppColors.danger.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      isActive ? 'ACTIVE' : 'DEACTIVATED',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'monospace',
                                        color: isActive ? AppColors.success : AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                phone.isNotEmpty ? '$phone • $email' : email,
                                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary(context), fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),

                        // Role Badge
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  _formatRoleName(roleStr),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: roleColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tillLane,
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                              ),
                            ],
                          ),
                        ),

                        // Station 5-Char Auth Code & Scannable Barcode
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () => _showBadgeDialog(staff),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.keyRound, size: 12, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'CODE: $pinCode',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.5,
                                              color: AppColors.textPrimary(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Click to view badge',
                                        style: TextStyle(fontSize: 9.5, color: AppColors.primary, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: BarcodeWidget(
                                      barcode: Barcode.code128(),
                                      data: _safeBarcodeData(
                                        (staff['id'] ?? staff['employee_number'] ?? '').toString().isNotEmpty
                                            ? (staff['id'] ?? staff['employee_number'] ?? '').toString()
                                            : (pinCode.contains('•') ? null : pinCode),
                                        fallback: 'STAFF',
                                      ),
                                      width: 60,
                                      height: 22,
                                      drawText: false,
                                      errorBuilder: (context, error) => const SizedBox(
                                        width: 60,
                                        height: 22,
                                        child: Center(
                                          child: Icon(LucideIcons.barcode, size: 16, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Today's Performance (for Cashiers)
                        Expanded(
                          flex: 3,
                          child: isCashier
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Today: ${Formatters.formatCurrency(todaySales)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary(context),
                                      ),
                                    ),
                                    Text(
                                      '$todayTransactions receipts • $voidsCount voids',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                                    ),
                                  ],
                                )
                              : Text(
                                  lastActive,
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                                ),
                        ),

                        // Actions: View Badge, Activate/Deactivate, Edit, Delete
                        IconButton(
                          icon: const Icon(LucideIcons.idCard, size: 16, color: AppColors.primary),
                          tooltip: 'View & Scan Staff Badge',
                          onPressed: () => _showBadgeDialog(staff),
                        ),
                        IconButton(
                          icon: Icon(
                            isActive ? LucideIcons.userCheck : LucideIcons.userX,
                            size: 16,
                            color: isActive ? AppColors.success : AppColors.danger,
                          ),
                          tooltip: isActive ? 'Deactivate Staff' : 'Activate Staff',
                          onPressed: () => _toggleStaffActive(staff),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.pencil, size: 16),
                          tooltip: 'Edit Staff Profile & Code',
                          onPressed: () => _openAddOrEditUserDialog(staff),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger),
                          tooltip: 'Delete Staff Member',
                          onPressed: () => _confirmDeleteStaff(staff),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SearchableAutocompleteField extends StatefulWidget {
  final String initialValue;
  final List<String> options;
  final String hint;
  final IconData? icon;
  final ValueChanged<String> onSelected;

  const SearchableAutocompleteField({
    super.key,
    required this.initialValue,
    required this.options,
    required this.onSelected,
    this.hint = 'Type to search or select...',
    this.icon,
  });

  @override
  State<SearchableAutocompleteField> createState() => _SearchableAutocompleteFieldState();
}

class _SearchableAutocompleteFieldState extends State<SearchableAutocompleteField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final Object _tapRegionGroupId = Object();
  OverlayEntry? _overlayEntry;
  List<String> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _filteredOptions = List.from(widget.options);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _filterOptions(_controller.text);
        _showOverlay();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SearchableAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text && !_focusNode.hasFocus) {
      _controller.text = widget.initialValue;
    }
    if (widget.options != oldWidget.options) {
      _filterOptions(_controller.text);
    }
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterOptions(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredOptions = List.from(widget.options);
      } else {
        _filteredOptions = widget.options
            .where((opt) => opt.toLowerCase().contains(q))
            .toList();
      }
    });
    _overlayEntry?.markNeedsBuild();
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.markNeedsBuild();
      return;
    }
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _overlayEntry = _createOverlayEntry();
    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      if (_overlayEntry!.mounted) {
        _overlayEntry!.remove();
      }
      _overlayEntry = null;
    }
  }

  void _selectOption(String option) {
    _controller.text = option;
    widget.onSelected(option);
    _hideOverlay();
    _focusNode.unfocus();
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (ctx) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, size.height + 4.0),
            child: TapRegion(
              groupId: _tapRegionGroupId,
              child: Material(
                elevation: 14,
                borderRadius: BorderRadius.circular(4),
                color: AppColors.surface(context),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _filteredOptions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Text(
                            'No matching options found',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textMuted(context),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: _filteredOptions.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: AppColors.border(context).withValues(alpha: 0.6),
                          ),
                          itemBuilder: (context, index) {
                            final option = _filteredOptions[index];
                            final isSelected = option.toLowerCase() == _controller.text.trim().toLowerCase();

                            return InkWell(
                              mouseCursor: SystemMouseCursors.click,
                              onTap: () => _selectOption(option),
                              hoverColor: AppColors.primary.withValues(alpha: 0.12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                color: isSelected ? AppColors.primary.withValues(alpha: 0.10) : Colors.transparent,
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                                      size: 14,
                                      color: isSelected ? AppColors.primary : AppColors.textMuted(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                          color: AppColors.textPrimary(context),
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
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _tapRegionGroupId,
      onTapOutside: (_) {
        if (_overlayEntry != null) {
          _hideOverlay();
          _focusNode.unfocus();
        }
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onTap: () {
            _filterOptions(_controller.text);
            _showOverlay();
          },
          onSubmitted: (val) {
            if (_filteredOptions.isNotEmpty) {
              _selectOption(_filteredOptions.first);
            } else if (val.trim().isNotEmpty) {
              _selectOption(val.trim());
            } else {
              _hideOverlay();
            }
          },
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted(context),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(2)),
            prefixIcon: widget.icon != null ? Icon(widget.icon, size: 14, color: AppColors.primary) : null,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 13),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    tooltip: 'Clear input',
                    onPressed: () {
                      _controller.clear();
                      _filterOptions('');
                      widget.onSelected('');
                      _showOverlay();
                    },
                  ),
                IconButton(
                  icon: const Icon(LucideIcons.chevronsUpDown, size: 14, color: AppColors.primary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'View suggestions',
                  onPressed: () {
                    if (_overlayEntry != null) {
                      _hideOverlay();
                      _focusNode.unfocus();
                    } else {
                      _filterOptions(_controller.text);
                      _showOverlay();
                      _focusNode.requestFocus();
                    }
                  },
                ),
              ],
            ),
          ),
          onChanged: (val) {
            _filterOptions(val);
            _showOverlay();
            widget.onSelected(val);
          },
        ),
      ),
    );
  }
}
