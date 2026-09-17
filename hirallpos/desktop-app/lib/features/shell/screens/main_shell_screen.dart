import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../cashier/screens/cashier_screen.dart';
import '../../storekeeping/screens/storekeeping_screen.dart';
import '../../outlets/screens/outlets_screen.dart';
import '../../accounting/screens/accounting_screen.dart';
import '../../waiter/screens/waiter_screen.dart';
import '../../hr/screens/hr_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../activation/screens/activation_screen.dart';
import '../../auth/screens/backoffice_login_screen.dart';
import '../../terminal/screens/pos_terminal_screen.dart';
import '../widgets/mobile_pairing_dialog.dart';
import '../../../core/services/wireless_bridge_service.dart';
import '../../../core/network/api_service.dart';
import 'module_hub_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final String organizationName;
  final String branchName;
  final String businessType;
  final List<String> enabledModules;

  const MainShellScreen({
    super.key,
    required this.organizationName,
    required this.branchName,
    required this.businessType,
    required this.enabledModules,
  });

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late String _currentBranch;
  late List<String> _currentModules;
  String _organizationId = '67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad';
  String _branchId = '5309fdb8-4344-43eb-9b5b-e9cedd308470';
  String _currentRole = 'cashier';
  String _currentUserName = 'Station Supervisor';
  List<Map<String, dynamic>> _branchesList = [];
  
  // Navigation State: 'terminal' (POS Station Sign-In), 'hub' (Backoffice Hub), or specific module key ('cashier', 'storekeeping', etc.)
  String _currentView = 'terminal';

  @override
  void initState() {
    super.initState();
    _currentBranch = widget.branchName;
    _currentModules = List<String>.from(widget.enabledModules);
    _currentView = 'terminal'; // Default landing is POS Terminal Screen
    _loadOrgAndBranch();
  }

  Future<void> _loadOrgAndBranch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOrg = prefs.getString(AppConstants.keyOrgId);
      final savedBranchId = prefs.getString(AppConstants.keyBranchId);
      final savedBranchName = prefs.getString(AppConstants.keyBranchName);

      if (savedOrg != null && savedOrg.isNotEmpty) {
        _organizationId = savedOrg;
      }
      if (savedBranchId != null && savedBranchId.isNotEmpty) {
        _branchId = savedBranchId;
      }
      if (savedBranchName != null && savedBranchName.isNotEmpty) {
        _currentBranch = savedBranchName;
      }

      // Fetch live branch roster from database
      final dbBranches = await ApiService().getBranches();
      if (dbBranches.isNotEmpty && mounted) {
        final mapped = dbBranches.map((b) => Map<String, dynamic>.from(b as Map)).toList();
        setState(() {
          _branchesList = mapped;
          // Match current branch ID
          final matchById = mapped.firstWhere(
            (b) => b['id'] == _branchId,
            orElse: () => <String, dynamic>{},
          );
          if (matchById.isNotEmpty) {
            _currentBranch = (matchById['name'] ?? _currentBranch).toString();
          } else {
            // Try matching by name
            final matchByName = mapped.firstWhere(
              (b) => (b['name'] ?? '').toString().toLowerCase() == _currentBranch.toLowerCase() ||
                     (b['code'] ?? '').toString().toLowerCase() == _currentBranch.toLowerCase(),
              orElse: () => mapped.first,
            );
            _branchId = (matchByName['id'] ?? _branchId).toString();
            _currentBranch = (matchByName['name'] ?? _currentBranch).toString();
          }
        });
        await prefs.setString(AppConstants.keyBranchId, _branchId);
        await prefs.setString(AppConstants.keyBranchName, _currentBranch);
      }
    } catch (_) {}
  }

  Future<void> _switchBranch(String newBranchId, String newBranchName) async {
    if (_branchId == newBranchId && _currentBranch == newBranchName) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyBranchId, newBranchId);
      await prefs.setString(AppConstants.keyBranchName, newBranchName);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _branchId = newBranchId;
        _currentBranch = newBranchName;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.store, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Active context switched to "$newBranchName". Stock and registers updated.',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  bool _isModuleAllowed(String moduleKey) {
    final role = _currentRole.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    if (role == 'owner' || role == 'superadmin' || role == 'super_admin') return true;
    if (role == 'branch_manager' || role == 'manager' || role == 'admin') {
      return true;
    }
    if (role == 'accountant') {
      return moduleKey == 'accounting' || moduleKey == 'pos_outlets';
    }
    if (role == 'storekeeper') {
      return moduleKey == 'storekeeping';
    }
    if (role == 'cashier') {
      return moduleKey == 'cashier';
    }
    if (role == 'waiter') {
      return moduleKey == 'waiter';
    }
    return false;
  }

  void _onSelectModuleFromHub(String moduleKey) {
    if (_isModuleAllowed(moduleKey)) {
      setState(() => _currentView = moduleKey);
    } else {
      _openBackofficeLoginDialog(targetModuleKey: moduleKey);
    }
  }

  void _openBackofficeLoginDialog({String? targetModuleKey}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BackofficeLoginScreen(
        organizationName: widget.organizationName,
        currentBranch: _currentBranch,
        targetModuleKey: targetModuleKey,
        onLoginSuccess: (auth) {
          final role = (auth['role'] ?? 'cashier').toString().toLowerCase();
          if (role == 'cashier' || role == 'waiter') {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Access Denied: Cashier accounts cannot access BackOffice Operations.',
                ),
                backgroundColor: AppColors.danger,
              ),
            );
            return;
          }

          Navigator.pop(ctx);
          setState(() {
            _currentRole = role;
            _currentUserName = auth['full_name'] ?? 'Authorized User';
            if (auth['branch_name'] != null) {
              _currentBranch = auth['branch_name'];
            }
            if (targetModuleKey != null && _isModuleAllowed(targetModuleKey)) {
              _currentView = targetModuleKey;
            } else {
              _currentView = 'hub'; // Go to Backoffice Hub
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Signed in as $_currentUserName (${_currentRole.toUpperCase()}) • Branch: $_currentBranch',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  void _lockToTerminal() {
    setState(() {
      _currentView = 'terminal';
    });
  }

  Widget _buildActiveViewWidget() {
    switch (_currentView) {
      case 'terminal':
        return PosTerminalScreen(
          organizationName: widget.organizationName,
          branchName: _currentBranch,
          businessType: widget.businessType,
          onStaffLogin: (role, staffName, targetStation) {
            setState(() {
              _currentRole = role;
              _currentUserName = staffName;
              _currentView = targetStation; // Boots directly into Cashier or Waiter station
            });
          },
          onOpenBackoffice: () => _openBackofficeLoginDialog(),
        );

      case 'hub':
        return ModuleHubScreen(
          organizationName: widget.organizationName,
          branchName: _currentBranch,
          businessType: widget.businessType,
          enabledModules: _currentModules,
          currentRole: _currentRole,
          currentUserName: _currentUserName,
          onSelectModule: _onSelectModuleFromHub,
          onLockTerminal: _lockToTerminal,
          onOpenBackofficeLogin: () => _openBackofficeLoginDialog(),
          onSwitchBranch: (newBranch) {
            final match = _branchesList.firstWhere(
              (b) => (b['name'] ?? '').toString().toLowerCase() == newBranch.toLowerCase() ||
                     (b['code'] ?? '').toString().toLowerCase() == newBranch.toLowerCase() ||
                     b['id'] == newBranch,
              orElse: () => <String, dynamic>{},
            );
            if (match.isNotEmpty) {
              _switchBranch((match['id'] ?? _branchId).toString(), (match['name'] ?? newBranch).toString());
            } else {
              setState(() => _currentBranch = newBranch);
            }
          },
        );

      case 'cashier':
        return CashierScreen(
          key: ValueKey('cashier_$_branchId'),
          organizationId: _organizationId,
          branchId: _branchId,
          branchName: _currentBranch,
        );
      case 'storekeeping':
        return StorekeepingScreen(
          key: ValueKey('store_$_branchId'),
          branchId: _branchId,
          branchName: _currentBranch,
          organizationName: widget.organizationName,
        );
      case 'accounting':
        return AccountingScreen(
          key: ValueKey('acc_$_branchId'),
          branchId: _branchId,
          branchName: _currentBranch,
        );
      case 'waiter':
        return WaiterScreen(
          key: ValueKey('waiter_$_branchId'),
          branchName: _currentBranch,
        );
      case 'hr_management':
        return HrScreen(
          key: ValueKey('hr_$_branchId'),
          branchName: _currentBranch,
        );
      case 'pos_outlets':
        return OutletsScreen(
          key: ValueKey('outlets_$_branchId'),
          currentBranchId: _branchId,
          currentBranchName: _currentBranch,
          onSwitchBranch: (newBranchId, newBranchName) {
            _switchBranch(newBranchId, newBranchName);
          },
        );
      case 'admin':
        return AdminDashboardScreen(
          key: ValueKey('admin_$_branchId'),
          branchId: _branchId,
          organizationName: widget.organizationName,
          branchName: _currentBranch,
          enabledModules: _currentModules,
          onModulesUpdated: (newMods) {
            setState(() => _currentModules = newMods);
          },
        );
      default:
        return PosTerminalScreen(
          organizationName: widget.organizationName,
          branchName: _currentBranch,
          businessType: widget.businessType,
          onStaffLogin: (role, staffName, targetStation) {
            setState(() {
              _currentRole = role;
              _currentUserName = staffName;
              _currentView = targetStation;
            });
          },
          onOpenBackoffice: () => _openBackofficeLoginDialog(),
        );
    }
  }

  String _getModuleTitle(String key) {
    switch (key) {
      case 'cashier':
        return 'Cashier & POS Checkout';
      case 'storekeeping':
        return 'Storekeeping & Inventory';
      case 'accounting':
        return 'Accounting & Finance';
      case 'waiter':
        return 'Waiter & Dining Tables';
      case 'hr_management':
        return 'Staff & HR Roster';
      case 'pos_outlets':
        return 'POS Outlets & Branches';
      case 'admin':
        return 'Super-Admin & Settings';
      default:
        return 'Operational Module';
    }
  }

  IconData _getModuleIcon(String key) {
    switch (key) {
      case 'cashier':
        return LucideIcons.shoppingCart;
      case 'storekeeping':
        return LucideIcons.package;
      case 'accounting':
        return LucideIcons.calculator;
      case 'waiter':
        return LucideIcons.utensils;
      case 'hr_management':
        return LucideIcons.users;
      case 'pos_outlets':
        return LucideIcons.store;
      case 'admin':
        return LucideIcons.settings;
      default:
        return LucideIcons.layoutGrid;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. If currently in Terminal or Hub mode, render without extra sub-bars
    if (_currentView == 'terminal' || _currentView == 'hub') {
      return _buildActiveViewWidget();
    }

    // 2. If inside a dedicated operational module workspace, show Top Navigation Bar
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Column(
        children: [
          // Top Operational Module Navigation Bar
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              border: Border(bottom: BorderSide(color: AppColors.border(context))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width > 32 ? MediaQuery.of(context).size.width - 32 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                // Left: Back to Hub / Lock Station Buttons + Breadcrumbs
                Row(
                  children: [
                    // Lock / Terminal Button
                    IconButton(
                      icon: const Icon(LucideIcons.arrowLeftCircle, color: AppColors.primary, size: 20),
                      tooltip: 'Exit to POS Station Terminal',
                      onPressed: _lockToTerminal,
                    ),
                    const SizedBox(width: 4),

                    // Back to Backoffice Hub Button
                    InkWell(
                      onTap: () => setState(() => _currentView = 'hub'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.layoutGrid, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Module Hub',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(LucideIcons.chevronRight, size: 14, color: AppColors.textMuted(context)),
                    const SizedBox(width: 12),
                    Icon(_getModuleIcon(_currentView), size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      _getModuleTitle(_currentView),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                    ),
                  ],
                ),

                // Center: Quick Module Switcher Tabs (RBAC Filtered)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.bg(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Row(
                    children: [
                      ..._currentModules.where((modKey) => _isModuleAllowed(modKey)).map((modKey) {
                        final isSelected = modKey == _currentView;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () => setState(() => _currentView = modKey),
                            borderRadius: BorderRadius.circular(7),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getModuleIcon(modKey),
                                    size: 13,
                                    color: isSelected ? Colors.white : AppColors.textSecondary(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getModuleShortLabel(modKey),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? Colors.white : AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      // Admin tab if allowed
                      if (_isModuleAllowed('admin'))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () => setState(() => _currentView = 'admin'),
                            borderRadius: BorderRadius.circular(7),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _currentView == 'admin' ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.settings,
                                    size: 13,
                                    color: _currentView == 'admin' ? Colors.white : AppColors.textSecondary(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Admin',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: _currentView == 'admin' ? FontWeight.w700 : FontWeight.w500,
                                      color: _currentView == 'admin' ? Colors.white : AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Right: Theme Toggle + Staff Auth Badge + Branch + Lock Station
                Row(
                  children: [
                    // Mobile Scanner Bridge Button
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => MobilePairingDialog(
                            organizationName: widget.organizationName,
                            branchName: _currentBranch,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.smartphone, size: 13, color: AppColors.primary),
                            const SizedBox(width: 6),
                            StreamBuilder<int>(
                              stream: WirelessBridgeService.instance.connectedDevicesCountStream,
                              initialData: WirelessBridgeService.instance.connectedDevicesCount,
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return Text(
                                  count > 0 ? 'Mobile ($count)' : 'Mobile Hub',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: count > 0 ? AppColors.success : AppColors.textSecondary(context),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Theme Toggle Button
                    InkWell(
                      onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Icon(
                          isDark ? LucideIcons.sun : LucideIcons.moon,
                          size: 14,
                          color: isDark ? const Color(0xFFFBBF24) : AppColors.textPrimary(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Backoffice Switch Staff Button
                    InkWell(
                      onTap: () => _openBackofficeLoginDialog(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.user, size: 12, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              '$_currentUserName (${_currentRole.toUpperCase()})',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      tooltip: 'Switch Active Branch',
                      offset: const Offset(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppColors.border(context)),
                      ),
                      color: AppColors.surface(context),
                      onSelected: (val) {
                        if (val == '__manage_outlets__') {
                          setState(() => _currentView = 'pos_outlets');
                          return;
                        }
                        final selected = _branchesList.firstWhere(
                          (b) => b['id'] == val,
                          orElse: () => <String, dynamic>{},
                        );
                        if (selected.isNotEmpty) {
                          _switchBranch(val, (selected['name'] ?? 'Branch').toString());
                        }
                      },
                      itemBuilder: (ctx) {
                        return [
                          const PopupMenuItem<String>(
                            enabled: false,
                            height: 28,
                            child: Text(
                              'SELECT OPERATING BRANCH',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const PopupMenuDivider(height: 1),
                          if (_branchesList.isEmpty)
                            PopupMenuItem<String>(
                              value: _branchId,
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.check, size: 14, color: AppColors.success),
                                  const SizedBox(width: 8),
                                  Text(_currentBranch, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            )
                          else
                            ..._branchesList.map((b) {
                              final bId = (b['id'] ?? '').toString();
                              final bName = (b['name'] ?? 'Branch').toString();
                              final bCode = (b['code'] ?? 'BR').toString();
                              final isSelected = bId == _branchId;
                              return PopupMenuItem<String>(
                                value: bId,
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? LucideIcons.checkCircle2 : LucideIcons.store,
                                      size: 14,
                                      color: isSelected ? AppColors.success : AppColors.textSecondary(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            bName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                              color: isSelected ? AppColors.primary : AppColors.textPrimary(context),
                                            ),
                                          ),
                                          Text(
                                            'CODE: $bCode • Branch Stock Isolated',
                                            style: TextStyle(fontSize: 10, color: AppColors.textMuted(context)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success)),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          const PopupMenuDivider(height: 1),
                          const PopupMenuItem<String>(
                            value: '__manage_outlets__',
                            child: Row(
                              children: [
                                Icon(LucideIcons.plusCircle, size: 14, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Register & Manage Outlets',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ];
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.store, size: 13, color: AppColors.primary),
                            const SizedBox(width: 5),
                            Text(
                              _currentBranch,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                            ),
                            const SizedBox(width: 4),
                            Icon(LucideIcons.chevronDown, size: 12, color: AppColors.textSecondary(context)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(LucideIcons.lock, size: 16, color: AppColors.textSecondary(context)),
                      tooltip: 'Lock to Terminal Screen',
                      onPressed: _lockToTerminal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),

          // Main Dedicated Module Dashboard Workspace
          Expanded(
            child: _buildActiveViewWidget(),
          ),
        ],
      ),
    );
  }

  String _getModuleShortLabel(String key) {
    switch (key) {
      case 'cashier':
        return 'Cashier';
      case 'storekeeping':
        return 'Storekeeping';
      case 'accounting':
        return 'Accounting';
      case 'waiter':
        return 'Waiter';
      case 'hr_management':
        return 'Staff & HR';
      case 'pos_outlets':
        return 'Outlets';
      case 'admin':
        return 'Admin';
      default:
        return key;
    }
  }
}
