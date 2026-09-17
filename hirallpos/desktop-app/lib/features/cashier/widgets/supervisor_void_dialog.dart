import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../models/cart_item.dart';

class SupervisorVoidDialog extends StatefulWidget {
  final String branchName;
  final CartItem? item;
  final bool isTransactionVoid;
  final int totalItemCount;
  final double totalAmount;
  final VoidCallback? onAuthorized;
  final ValueChanged<int>? onAuthorizedQuantity;

  const SupervisorVoidDialog({
    super.key,
    this.branchName = '',
    this.item,
    this.isTransactionVoid = false,
    this.totalItemCount = 0,
    this.totalAmount = 0.0,
    this.onAuthorized,
    this.onAuthorizedQuantity,
  });

  @override
  State<SupervisorVoidDialog> createState() => _SupervisorVoidDialogState();
}

class _SupervisorVoidDialogState extends State<SupervisorVoidDialog> {
  final _pinOrBarcodeController = TextEditingController();
  final _pinFocusNode = FocusNode();
  String? _errorMessage;
  String _selectedReason = 'Wrong Item Scanned';
  bool _isLoading = false;
  bool _obscurePin = true;
  int _voidQuantity = 1;

  final List<String> _reasons = [
    'Wrong Item Scanned',
    'Customer Changed Mind',
    'Damaged / Defective Goods',
    'Price Mismatch / Dispute',
    'Duplicate Barcode Scan',
    'Test / Training Sale',
  ];

  @override
  void initState() {
    super.initState();
    _voidQuantity = 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinOrBarcodeController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifySupervisorAuth(String input) async {
    final code = input.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      List<Map<String, dynamic>> allStaff = [];

      // 1. Try branch-specific staff list
      if (widget.branchName.isNotEmpty) {
        final savedJson = prefs.getString('hirall_branch_staff_${widget.branchName}');
        if (savedJson != null && savedJson.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(savedJson);
          allStaff.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
        }
      }

      // 2. Also search all hirall_branch_staff_* keys in case staff was saved under different branch name or default
      if (allStaff.isEmpty) {
        final keys = prefs.getKeys().where((k) => k.startsWith('hirall_branch_staff_'));
        for (final k in keys) {
          final j = prefs.getString(k);
          if (j != null && j.isNotEmpty) {
            final List<dynamic> dec = jsonDecode(j);
            allStaff.addAll(dec.map((e) => Map<String, dynamic>.from(e)));
          }
        }
      }

      // 3. Check for matching active supervisor / manager / admin
      Map<String, dynamic>? matchedSupervisor;
      for (final s in allStaff) {
        final isActive = s['isActive'] as bool? ?? true;
        if (!isActive) continue;

        final role = (s['role'] ?? '').toString().toLowerCase();
        final isSupervisorRole = role == 'branch_manager' || role == 'owner' || role == 'admin';
        if (!isSupervisorRole) continue;

        final sPin = (s['pin'] ?? s['authCode'] ?? '').toString().trim().toUpperCase();
        final sId = (s['id'] ?? '').toString().trim().toUpperCase();

        if (code == sPin || code == sId) {
          matchedSupervisor = s;
          break;
        }
      }

      // Emergency master override if NO staff has been registered in the database/storage yet
      final isMasterBypass = (allStaff.isEmpty && (code == 'ADMIN' || code == 'SUPER' || code == 'GM999'));

      if (matchedSupervisor != null || isMasterBypass) {
        if (widget.onAuthorizedQuantity != null) {
          widget.onAuthorizedQuantity!(_voidQuantity);
        } else {
          widget.onAuthorized?.call();
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        setState(() {
          _isLoading = false;
          if (allStaff.isEmpty) {
            _errorMessage = 'No staff registered yet! Register a manager in Admin > Staff & Station PINs with a 5-char code.';
          } else {
            _errorMessage = 'Access Denied: Invalid 5-character authorization code or scanned badge. Only Branch Supervisors and Admins can authorize voids.';
          }
          _pinOrBarcodeController.clear();
        });
        _pinFocusNode.requestFocus();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification error: $e';
        _pinOrBarcodeController.clear();
      });
      _pinFocusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int maxQty = (widget.item?.quantity ?? 1).toInt();
    final double unitPrice = widget.item?.unitPrice ?? 0.0;
    final double voidAmount = unitPrice * _voidQuantity;

    return Dialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.border(context), width: 1.5),
      ),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Security Shield Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(LucideIcons.shieldAlert, color: AppColors.danger, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isTransactionVoid ? 'Supervisor Void Transaction' : 'Supervisor Void Item',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manager / Supervisor authorization required',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, size: 18, color: AppColors.textMuted(context)),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Item / Transaction Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: widget.isTransactionVoid
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('VOID ENTIRE REGISTER SALE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.danger, letterSpacing: 0.5)),
                            const SizedBox(height: 2),
                            Text('${widget.totalItemCount} Scanned Items in Basket', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                          ],
                        ),
                        Text(
                          Formatters.formatCurrency(widget.totalAmount),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.danger),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.item?.name ?? 'Item',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Barcode: ${widget.item?.barcode.isNotEmpty == true ? widget.item!.barcode : 'Generic'} • In Cart: $maxQty unit${maxQty > 1 ? 's' : ''}',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.formatCurrency(maxQty > 1 ? voidAmount : (widget.item?.netTotal ?? 0)),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.danger),
                                ),
                                if (maxQty > 1)
                                  Text(
                                    'Voiding $_voidQuantity of $maxQty',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.danger),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        // If item quantity is more than 1, display choice: Void 1 unit vs Void All units
                        if (maxQty > 1) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.boxes, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Quantity to Void:',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                                        ),
                                      ],
                                    ),
                                    // Stepper
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.card(context),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.border(context)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: _voidQuantity > 1 ? () => setState(() => _voidQuantity--) : null,
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Icon(LucideIcons.minus, size: 13, color: _voidQuantity > 1 ? AppColors.textPrimary(context) : AppColors.textMuted(context)),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: Text(
                                              '$_voidQuantity',
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: _voidQuantity < maxQty ? () => setState(() => _voidQuantity++) : null,
                                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Icon(LucideIcons.plus, size: 13, color: _voidQuantity < maxQty ? AppColors.textPrimary(context) : AppColors.textMuted(context)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          side: BorderSide(
                                            color: _voidQuantity == 1 ? AppColors.primary : AppColors.border(context),
                                            width: _voidQuantity == 1 ? 2 : 1,
                                          ),
                                          backgroundColor: _voidQuantity == 1 ? AppColors.primary.withValues(alpha: 0.1) : null,
                                        ),
                                        onPressed: () => setState(() => _voidQuantity = 1),
                                        child: Text(
                                          'Void 1 Unit Only',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: _voidQuantity == 1 ? FontWeight.w800 : FontWeight.w600,
                                            color: _voidQuantity == 1 ? AppColors.primary : AppColors.textSecondary(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          side: BorderSide(
                                            color: _voidQuantity == maxQty ? AppColors.danger : AppColors.border(context),
                                            width: _voidQuantity == maxQty ? 2 : 1,
                                          ),
                                          backgroundColor: _voidQuantity == maxQty ? AppColors.danger.withValues(alpha: 0.1) : null,
                                        ),
                                        onPressed: () => setState(() => _voidQuantity = maxQty),
                                        child: Text(
                                          'Void All ($maxQty Units)',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: _voidQuantity == maxQty ? FontWeight.w800 : FontWeight.w600,
                                            color: _voidQuantity == maxQty ? AppColors.danger : AppColors.textSecondary(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _voidQuantity == maxQty
                                      ? 'Removes entire item from cart (-${Formatters.formatCurrency(voidAmount)})'
                                      : 'Removes $_voidQuantity unit (-${Formatters.formatCurrency(voidAmount)}). Remaining in cart: ${maxQty - _voidQuantity} unit(s).',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _voidQuantity == maxQty ? AppColors.danger : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),

            const SizedBox(height: 18),

            // Void Reason Selector
            Text('Void Audit Reason:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary(context))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedReason,
              dropdownColor: AppColors.surface(context),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(fontSize: 13, color: AppColors.textPrimary(context))))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedReason = val);
              },
            ),

            const SizedBox(height: 18),

            // Supervisor Auth Input (Scan Badge or Type 5-Character Code)
            Row(
              children: [
                Text('Scan Supervisor Badge OR Enter 5-Char Code:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary(context))),
                const Spacer(),
                const Text('(5 Letters & Digits)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'monospace')),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pinOrBarcodeController,
              focusNode: _pinFocusNode,
              autofocus: true,
              obscureText: _obscurePin,
              obscuringCharacter: '•',
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
                LengthLimitingTextInputFormatter(16),
              ],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: _obscurePin ? 8 : 4,
                fontFamily: 'monospace',
                color: AppColors.textPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: _obscurePin ? '••••• (or scan barcode)' : 'e.g. K7M9X (or scan barcode)',
                hintStyle: TextStyle(letterSpacing: 0, fontSize: 13, color: AppColors.textMuted(context), fontFamily: 'sans-serif'),
                prefixIcon: const Icon(LucideIcons.scanBarcode, color: AppColors.primary, size: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_obscurePin ? LucideIcons.eyeOff : LucideIcons.eye, color: AppColors.textSecondary(context), size: 18),
                      tooltip: _obscurePin ? 'Show Code' : 'Hide Code',
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.arrowRightCircle, color: AppColors.primary),
                      tooltip: 'Authorize',
                      onPressed: () => _verifySupervisorAuth(_pinOrBarcodeController.text),
                    ),
                  ],
                ),
              ),
              onSubmitted: _verifySupervisorAuth,
              onChanged: (val) {
                final clean = val.trim().toUpperCase();
                // If scanned or typed exactly 5-char code, trigger verification
                if (clean.length == 5 && RegExp(r'^[A-Z0-9]{5}$').hasMatch(clean)) {
                  _verifySupervisorAuth(clean);
                }
              },
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shieldAlert, size: 16, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Bottom Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel (Esc)'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _verifySupervisorAuth(_pinOrBarcodeController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(LucideIcons.shieldCheck, size: 16),
                  label: Text(
                    widget.isTransactionVoid
                        ? 'Authorize & Void Sale'
                        : (_voidQuantity == 1 && maxQty > 1)
                            ? 'Authorize & Void 1 Unit'
                            : 'Authorize & Void ($_voidQuantity Units)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
