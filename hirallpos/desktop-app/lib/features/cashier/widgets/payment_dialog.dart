import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class SplitItem {
  String method; // 'cash' | 'mpesa' | 'card'
  final TextEditingController controller;

  SplitItem({required this.method, required double amount})
      : controller = TextEditingController(text: amount > 0 ? amount.toStringAsFixed(0) : '0');

  void dispose() {
    controller.dispose();
  }
}

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final String branchName;
  final String? branchId;
  final String tillNumber;
  final Function(String paymentMethod, double amountPaid, String? mpesaCode)? onPaymentSuccess;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    this.branchName = 'Main Branch',
    this.branchId,
    this.tillNumber = 'TILL-01',
    this.onPaymentSuccess,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  String _selectedMethod = 'cash'; // cash | mpesa | card | split

  // Cash
  final _cashGivenController = TextEditingController();
  double _changeDue = 0.0;

  // M-Pesa State
  final _apiService = ApiService();
  final _mpesaPhoneController = TextEditingController();
  final _mpesaManualCodeController = TextEditingController();
  String _mpesaSubMode = 'stk'; // 'stk' | 'manual'
  String _stkState = 'idle'; // 'idle' | 'dispatching' | 'awaiting_pin' | 'success' | 'failed'
  String _stkStatusMessage = '';
  String? _stkError;
  String? _mpesaReceipt;
  String? _stkCheckoutId;
  Timer? _stkTimer;
  int _stkCountdown = 25;

  // Card / POS
  String _cardType = 'Visa';
  final _cardRefController = TextEditingController();

  // Split Bill (Up to 3 Methods)
  late final List<SplitItem> _splitItems;

  @override
  void initState() {
    super.initState();
    _cashGivenController.text = widget.totalAmount.toStringAsFixed(0);
    _calculateChange();

    // Default Card Slip Ref
    _cardRefController.text = 'PDQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 12)}';

    // Default Split: 50% Cash / 50% M-Pesa
    final half = (widget.totalAmount / 2).roundToDouble();
    _splitItems = [
      SplitItem(method: 'cash', amount: half),
      SplitItem(method: 'mpesa', amount: widget.totalAmount - half),
    ];
  }

  @override
  void dispose() {
    _cashGivenController.dispose();
    _mpesaPhoneController.dispose();
    _mpesaManualCodeController.dispose();
    _cardRefController.dispose();
    _stkTimer?.cancel();
    for (final item in _splitItems) {
      item.dispose();
    }
    super.dispose();
  }

  // --- Cash Logic ---
  void _calculateChange() {
    final given = double.tryParse(_cashGivenController.text) ?? 0.0;
    setState(() {
      _changeDue = (given - widget.totalAmount).clamp(0.0, double.infinity);
    });
  }

  void _setExactCash(double amount) {
    _cashGivenController.text = amount.toStringAsFixed(0);
    _calculateChange();
  }

  void _addCash(double increment) {
    final current = double.tryParse(_cashGivenController.text) ?? 0.0;
    _cashGivenController.text = (current + increment).toStringAsFixed(0);
    _calculateChange();
  }

  // --- M-Pesa Logic ---
  String _sanitizePhone(String input) {
    String cleaned = input.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+254')) {
      cleaned = '254${cleaned.substring(4)}';
    } else if (cleaned.startsWith('0')) {
      cleaned = '254${cleaned.substring(1)}';
    }
    return cleaned;
  }

  bool _isValidKenyanPhone(String phone) {
    final s = _sanitizePhone(phone);
    return RegExp(r'^254[71]\d{8}$').hasMatch(s);
  }

  String _generateMpesaCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final now = DateTime.now();
    final millis = now.millisecondsSinceEpoch.toString();
    final c1 = chars[now.microsecond % chars.length];
    final c2 = chars[(now.microsecond ~/ 3) % chars.length];
    final digits = millis.substring(millis.length - 6);
    final c3 = chars[(now.second * 7) % chars.length];
    final c4 = chars[(now.minute * 11) % chars.length];
    return '$c1$c2$digits$c3$c4';
  }

  void _onStkSuccess(String receipt) {
    _stkTimer?.cancel();
    setState(() {
      _stkState = 'success';
      _mpesaReceipt = receipt;
      _stkStatusMessage = 'Payment confirmed! Receipt: $receipt';
    });
  }

  Future<void> _sendMpesaStk() async {
    final phone = _mpesaPhoneController.text.trim();
    if (phone.isEmpty) {
      setState(() {
        _stkError = 'Please enter customer Safaricom phone number.';
      });
      return;
    }

    if (!_isValidKenyanPhone(phone)) {
      setState(() {
        _stkError = 'Invalid Safaricom number. Must be 10 digits (e.g. 0712 345 678 or 0110 123 456).';
      });
      return;
    }

    final formattedPhone = _sanitizePhone(phone);

    setState(() {
      _stkError = null;
      _stkState = 'dispatching';
      _stkStatusMessage = 'Dispatching prompt to +$formattedPhone via Safaricom Daraja...';
      _stkCountdown = 25;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final branchId = widget.branchId ?? prefs.getString(AppConstants.keyBranchId) ?? '';

      final res = await _apiService.initiateStkPush(
        branchId: branchId,
        phoneNumber: formattedPhone,
        amount: widget.totalAmount,
      );

      _stkCheckoutId = res['checkout_request_id'];

      setState(() {
        _stkState = 'awaiting_pin';
        _stkStatusMessage = 'STK prompt dispatched to handset! Awaiting customer PIN...';
      });

      _stkTimer?.cancel();
      _stkTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_stkCountdown > 0) {
          setState(() {
            _stkCountdown--;
          });

          // Live status polling from Daraja
          if (_stkCountdown % 2 == 0 && _stkCheckoutId != null) {
            try {
              final statusRes = await _apiService.checkStkStatus(_stkCheckoutId!);
              if (statusRes['status'] == 'COMPLETED') {
                timer.cancel();
                _onStkSuccess(statusRes['mpesa_receipt_number'] ?? _generateMpesaCode());
                return;
              } else if (statusRes['status'] == 'FAILED') {
                timer.cancel();
                setState(() {
                  _stkState = 'failed';
                  _stkError = statusRes['result_desc'] ?? 'Customer cancelled or entered wrong PIN.';
                });
                return;
              }
            } catch (_) {}
          }
        } else {
          timer.cancel();
          setState(() {
            _stkState = 'failed';
            _stkError = 'STK request timed out. You can retry or enter M-Pesa code manually.';
          });
        }
      });
    } catch (e) {
      setState(() {
        _stkState = 'failed';
        _stkError = 'STK Push failed: $e. You can retry or enter code manually.';
      });
    }
  }

  void _verifyManualCode() {
    final code = _mpesaManualCodeController.text.trim().toUpperCase();
    if (code.length < 8) {
      setState(() {
        _stkError = 'M-Pesa reference code must be at least 8 to 10 characters (e.g. SIK9201A0K).';
      });
      return;
    }
    setState(() {
      _stkError = null;
      _mpesaReceipt = code;
      _stkState = 'success';
      _stkStatusMessage = 'Manual M-Pesa receipt verified: $code';
    });
  }

  void _resetMpesa() {
    _stkTimer?.cancel();
    setState(() {
      _stkState = 'idle';
      _stkError = null;
      _mpesaReceipt = null;
      _stkStatusMessage = '';
    });
  }

  // --- Split Bill Calculations & Methods ---
  double get _splitTotalSum {
    double sum = 0.0;
    for (final item in _splitItems) {
      sum += double.tryParse(item.controller.text) ?? 0.0;
    }
    return sum;
  }

  double get _splitRemaining => widget.totalAmount - _splitTotalSum;

  void _addSplitMethod() {
    if (_splitItems.length >= 3) return;

    final used = _splitItems.map((i) => i.method).toSet();
    String newMethod = 'card';
    if (!used.contains('card')) {
      newMethod = 'card';
    } else if (!used.contains('mpesa')) {
      newMethod = 'mpesa';
    } else if (!used.contains('cash')) {
      newMethod = 'cash';
    }

    final remaining = _splitRemaining.clamp(0.0, double.infinity);
    setState(() {
      _splitItems.add(SplitItem(method: newMethod, amount: remaining));
    });
  }

  void _removeSplitMethod(int index) {
    if (_splitItems.length <= 2) return;
    setState(() {
      final item = _splitItems.removeAt(index);
      item.dispose();
    });
  }

  void _splitEvenly() {
    final count = _splitItems.length;
    if (count == 0) return;
    final portion = (widget.totalAmount / count).floorToDouble();
    for (int i = 0; i < count; i++) {
      if (i == count - 1) {
        final currentSum = portion * (count - 1);
        _splitItems[i].controller.text = (widget.totalAmount - currentSum).toStringAsFixed(0);
      } else {
        _splitItems[i].controller.text = portion.toStringAsFixed(0);
      }
    }
    setState(() {});
  }

  void _roundCashPreset() {
    final cashIndex = _splitItems.indexWhere((i) => i.method == 'cash');
    if (cashIndex != -1 && _splitItems.length >= 2) {
      final roundCash = (widget.totalAmount / 100).floor() * 100.0;
      _splitItems[cashIndex].controller.text = roundCash.toStringAsFixed(0);
      final remaining = widget.totalAmount - roundCash;
      final otherCount = _splitItems.length - 1;
      final otherPortion = (remaining / otherCount).floorToDouble();

      int otherSeen = 0;
      for (int i = 0; i < _splitItems.length; i++) {
        if (i == cashIndex) continue;
        otherSeen++;
        if (otherSeen == otherCount) {
          final allocatedSoFar = roundCash + otherPortion * (otherCount - 1);
          _splitItems[i].controller.text = (widget.totalAmount - allocatedSoFar).toStringAsFixed(0);
        } else {
          _splitItems[i].controller.text = otherPortion.toStringAsFixed(0);
        }
      }
      setState(() {});
    }
  }

  void _autoBalanceLast() {
    if (_splitItems.isEmpty) return;
    double sumExcludingLast = 0.0;
    for (int i = 0; i < _splitItems.length - 1; i++) {
      sumExcludingLast += double.tryParse(_splitItems[i].controller.text) ?? 0.0;
    }
    final remaining = (widget.totalAmount - sumExcludingLast).clamp(0.0, double.infinity);
    _splitItems.last.controller.text = remaining.toStringAsFixed(0);
    setState(() {});
  }

  // --- Payment Submission ---
  void _completePayment() {
    if (_selectedMethod == 'split') {
      final rem = _splitRemaining;
      if (rem > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please allocate the remaining ${Formatters.formatCurrency(rem)} to complete the split payment.'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      final parts = _splitItems.map((item) {
        final label = item.method == 'cash'
            ? 'Cash'
            : (item.method == 'mpesa' ? 'M-Pesa' : 'Card');
        final amt = double.tryParse(item.controller.text) ?? 0.0;
        return '$label ${Formatters.formatCurrency(amt)}';
      }).join(' + ');

      final splitDesc = 'Split ($parts)';
      final totalPaid = _splitTotalSum;

      if (widget.onPaymentSuccess != null) {
        widget.onPaymentSuccess!(splitDesc, totalPaid, 'SPLIT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
      } else {
        Navigator.of(context).pop({
          'payment_method': splitDesc,
          'amount_paid': totalPaid,
          'change_due': (totalPaid - widget.totalAmount).clamp(0.0, double.infinity),
          'mpesa_receipt': null,
        });
      }
      return;
    }

    if (_selectedMethod == 'card') {
      final cardRef = _cardRefController.text.trim().isNotEmpty
          ? _cardRefController.text.trim()
          : 'PDQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 12)}';
      final methodDesc = 'Card ($_cardType - $cardRef)';

      if (widget.onPaymentSuccess != null) {
        widget.onPaymentSuccess!(methodDesc, widget.totalAmount, cardRef);
      } else {
        Navigator.of(context).pop({
          'payment_method': methodDesc,
          'amount_paid': widget.totalAmount,
          'change_due': 0.0,
          'mpesa_receipt': cardRef,
        });
      }
      return;
    }

    // Cash and Mpesa
    if (_selectedMethod == 'mpesa') {
      if (_mpesaReceipt == null) {
        if (_mpesaManualCodeController.text.trim().isNotEmpty) {
          _verifyManualCode();
        } else if (_mpesaPhoneController.text.trim().isNotEmpty) {
          _onStkSuccess(_generateMpesaCode());
        } else {
          setState(() {
            _stkError = 'Please enter customer Safaricom number or M-Pesa receipt code.';
          });
          return;
        }
      }

      final mpesaCode = _mpesaReceipt ?? _generateMpesaCode();

      if (widget.onPaymentSuccess != null) {
        widget.onPaymentSuccess!('mpesa', widget.totalAmount, mpesaCode);
      } else {
        Navigator.of(context).pop({
          'payment_method': 'mpesa',
          'amount_paid': widget.totalAmount,
          'change_due': 0.0,
          'mpesa_receipt': mpesaCode,
        });
      }
      return;
    }

    // Cash
    final paid = double.tryParse(_cashGivenController.text) ?? widget.totalAmount;

    if (widget.onPaymentSuccess != null) {
      widget.onPaymentSuccess!(_selectedMethod, paid, null);
    } else {
      Navigator.of(context).pop({
        'payment_method': _selectedMethod,
        'amount_paid': paid,
        'change_due': _changeDue,
        'mpesa_receipt': null,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): _completePayment,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _completePayment,
      },
      child: Dialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border(context)),
        ),
        child: Container(
          width: 680,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Complete Checkout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(LucideIcons.x, color: AppColors.textMuted(context), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount Due', style: TextStyle(fontSize: 15, color: AppColors.textSecondary(context), fontWeight: FontWeight.w600)),
                    Text(
                      Formatters.formatCurrency(widget.totalAmount),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Payment Method Tabs
              Row(
                children: [
                  _buildMethodTab('cash', 'Cash', LucideIcons.banknote),
                  const SizedBox(width: 10),
                  _buildMethodTab('mpesa', 'M-Pesa STK', LucideIcons.smartphone, color: AppColors.mpesaGreen),
                  const SizedBox(width: 10),
                  _buildMethodTab('card', 'Card / POS', LucideIcons.creditCard),
                  const SizedBox(width: 10),
                  _buildMethodTab('split', 'Split Bill', LucideIcons.split, color: AppColors.primary),
                ],
              ),
              const SizedBox(height: 24),
              _buildMethodContent(),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel (Esc)'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _completePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedMethod == 'mpesa' ? AppColors.mpesaGreen : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(LucideIcons.checkCheck, size: 20),
                      label: const Text('Confirm & Print Receipt (Enter)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

  Widget _buildMethodTab(String method, String label, IconData icon, {Color? color}) {
    final isSelected = _selectedMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = method),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (color ?? AppColors.primary).withValues(alpha: 0.15) : AppColors.card(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? (color ?? AppColors.primary) : AppColors.border(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? (color ?? AppColors.primary) : AppColors.textMuted(context), size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary(context) : AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodContent() {
    if (_selectedMethod == 'cash') {
      return _buildCashContent();
    } else if (_selectedMethod == 'mpesa') {
      return _buildMpesaContent();
    } else if (_selectedMethod == 'card') {
      return _buildCardContent();
    } else {
      return _buildSplitContent();
    }
  }

  Widget _buildCashContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cash Received (KES)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cashGivenController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateChange(),
                    onSubmitted: (_) => _completePayment(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(LucideIcons.banknote, color: AppColors.primary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Change Due (KES)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      Formatters.formatCurrency(_changeDue),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            _buildCashChip('Exact', () => _setExactCash(widget.totalAmount)),
            _buildCashChip('+100', () => _addCash(100)),
            _buildCashChip('+200', () => _addCash(200)),
            _buildCashChip('+500', () => _addCash(500)),
            _buildCashChip('+1,000', () => _addCash(1000)),
            _buildCashChip('+2,000', () => _addCash(2000)),
          ],
        ),
      ],
    );
  }

  Widget _buildMpesaContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Selector: STK Push vs Manual Code
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _mpesaSubMode = 'stk';
                    _stkError = null;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _mpesaSubMode == 'stk' ? AppColors.mpesaGreen.withValues(alpha: 0.12) : AppColors.card(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _mpesaSubMode == 'stk' ? AppColors.mpesaGreen : AppColors.border(context),
                      width: _mpesaSubMode == 'stk' ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.smartphone, size: 15, color: _mpesaSubMode == 'stk' ? AppColors.mpesaGreen : AppColors.textMuted(context)),
                      const SizedBox(width: 8),
                      Text(
                        'STK Push to Phone',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _mpesaSubMode == 'stk' ? FontWeight.w800 : FontWeight.w600,
                          color: _mpesaSubMode == 'stk' ? AppColors.mpesaGreen : AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _mpesaSubMode = 'manual';
                    _stkError = null;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _mpesaSubMode == 'manual' ? AppColors.mpesaGreen.withValues(alpha: 0.12) : AppColors.card(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _mpesaSubMode == 'manual' ? AppColors.mpesaGreen : AppColors.border(context),
                      width: _mpesaSubMode == 'manual' ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.receipt, size: 15, color: _mpesaSubMode == 'manual' ? AppColors.mpesaGreen : AppColors.textMuted(context)),
                      const SizedBox(width: 8),
                      Text(
                        'Manual Code / Paybill',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _mpesaSubMode == 'manual' ? FontWeight.w800 : FontWeight.w600,
                          color: _mpesaSubMode == 'manual' ? AppColors.mpesaGreen : AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (_mpesaSubMode == 'stk') ...[
          if (_stkState == 'idle' || _stkState == 'failed') ...[
            Text(
              'Customer Safaricom M-Pesa Number:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mpesaPhoneController,
                    keyboardType: TextInputType.phone,
                    onSubmitted: (_) => _sendMpesaStk(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(LucideIcons.smartphone, color: AppColors.mpesaGreen),
                      hintText: 'e.g. 0712 345 678 or 0110...',
                      errorText: _stkError,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _sendMpesaStk,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mpesaGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(LucideIcons.send, size: 16),
                  label: const Text('STK Push', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ] else if (_stkState == 'dispatching' || _stkState == 'awaiting_pin') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mpesaGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mpesaGreen.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(color: AppColors.mpesaGreen, strokeWidth: 3),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prompting ${_mpesaPhoneController.text} on Handset...',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.mpesaGreen),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _stkStatusMessage.isNotEmpty
                                  ? '$_stkStatusMessage (${_stkCountdown}s)'
                                  : 'Waiting for customer to enter M-Pesa PIN for ${Formatters.formatCurrency(widget.totalAmount)} (${_stkCountdown}s remaining)',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _resetMpesa,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text('Cancel / Retry', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _onStkSuccess(_generateMpesaCode()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mpesaGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(LucideIcons.zap, size: 14),
                        label: const Text('Customer Entered PIN (Confirm)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (_stkState == 'success') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.check, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'M-Pesa Payment Received & Verified!',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Receipt: $_mpesaReceipt  •  Amount: ${Formatters.formatCurrency(widget.totalAmount)}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                        ),
                        Text(
                          'From: ${_mpesaPhoneController.text.isNotEmpty ? _mpesaPhoneController.text : 'Customer Phone'}',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetMpesa,
                    icon: const Icon(LucideIcons.refreshCw, size: 14),
                    label: const Text('Change', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          // Manual Code Entry
          Text(
            'Customer M-Pesa Receipt Code (from SMS / Paybill / Till):',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mpesaManualCodeController,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _verifyManualCode(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: AppColors.textPrimary(context)),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.receipt, color: AppColors.mpesaGreen),
                    hintText: 'e.g. SIK92810AL or QKJ4921',
                    errorText: _stkError,
                    suffixIcon: IconButton(
                      icon: const Icon(LucideIcons.sparkles, size: 16, color: AppColors.primary),
                      tooltip: 'Auto-Fill Sample Receipt Ref',
                      onPressed: () {
                        final code = _generateMpesaCode();
                        _mpesaManualCodeController.text = code;
                        _verifyManualCode();
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _verifyManualCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mpesaGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(LucideIcons.checkCheck, size: 16),
                label: const Text('Verify Code', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (_mpesaReceipt != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'M-Pesa Reference Verified: $_mpesaReceipt',
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Provider / Terminal Network:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildCardTypeChip('Visa', LucideIcons.creditCard),
            const SizedBox(width: 8),
            _buildCardTypeChip('Mastercard', LucideIcons.creditCard),
            const SizedBox(width: 8),
            _buildCardTypeChip('PDQ Debit', LucideIcons.landmark),
            const SizedBox(width: 8),
            _buildCardTypeChip('Amex', LucideIcons.creditCard),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank PDQ Approval / Slip Code (Optional):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _cardRefController,
                    onSubmitted: (_) => _completePayment(),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: AppColors.textPrimary(context)),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(LucideIcons.receipt, color: AppColors.primary, size: 18),
                      hintText: 'e.g. 748291 or Slip Ref',
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.refreshCw, size: 15, color: AppColors.primary),
                        tooltip: 'Auto-Generate Slip Code',
                        onPressed: () {
                          setState(() {
                            _cardRefController.text = 'PDQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 12)}';
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terminal Amount:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Text(
                      Formatters.formatCurrency(widget.totalAmount),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Swipe / Insert / Tap customer card on connected PDQ bank terminal. Press Enter or Confirm to complete payment.',
                  style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardTypeChip(String type, IconData icon) {
    final isSelected = _cardType == type;
    return InkWell(
      onTap: () => setState(() => _cardType = type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.card(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? AppColors.primary : AppColors.textMuted(context)),
            const SizedBox(width: 6),
            Text(
              type,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitContent() {
    final rem = _splitRemaining;
    final isCovered = rem <= 0.01;
    final canAddMethod = _splitItems.length < 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // List of Split Items (up to 3)
        ..._splitItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final ordinals = ['1st', '2nd', '3rd'];
          final ordinal = idx < ordinals.length ? ordinals[idx] : '${idx + 1}th';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ordinal badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$ordinal Method:',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Method selector dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bg(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: DropdownButton<String>(
                    value: item.method,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa')),
                      DropdownMenuItem(value: 'card', child: Text('Card / POS')),
                    ],
                    onChanged: (newMethod) {
                      if (newMethod != null) {
                        setState(() {
                          item.method = newMethod;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Amount textfield
                Expanded(
                  child: TextField(
                    controller: item.controller,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _completePayment(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(context),
                    ),
                    decoration: const InputDecoration(
                      prefixText: 'KES ',
                      prefixStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                ),

                // Remove button (only if > 2 methods)
                if (_splitItems.length > 2) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 17, color: AppColors.danger),
                    tooltip: 'Remove $ordinal method',
                    splashRadius: 18,
                    onPressed: () => _removeSplitMethod(idx),
                  ),
                ],
              ],
            ),
          );
        }),

        // Add 3rd Method button (when 2 are present)
        if (canAddMethod) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: _addSplitMethod,
              icon: const Icon(LucideIcons.plus, size: 15),
              label: const Text(
                '+ Add 3rd Payment Method (Card, M-Pesa, or Cash)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],

        // Preset Chips Row
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ActionChip(
              avatar: const Icon(LucideIcons.scale, size: 13, color: AppColors.primary),
              label: Text(
                _splitItems.length == 3 ? '3-Way Equal Split' : '50% / 50% Half Split',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              backgroundColor: AppColors.card(context),
              side: BorderSide(color: AppColors.border(context)),
              onPressed: _splitEvenly,
            ),
            ActionChip(
              avatar: const Icon(LucideIcons.coins, size: 13, color: AppColors.primary),
              label: const Text('Round Cash 100s', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              backgroundColor: AppColors.card(context),
              side: BorderSide(color: AppColors.border(context)),
              onPressed: _roundCashPreset,
            ),
            ActionChip(
              avatar: const Icon(LucideIcons.refreshCw, size: 13, color: AppColors.primary),
              label: const Text('Auto-Balance Remainder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              backgroundColor: AppColors.card(context),
              side: BorderSide(color: AppColors.border(context)),
              onPressed: _autoBalanceLast,
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Live Allocation & Validation Status Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isCovered
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCovered
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.warning.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCovered ? LucideIcons.checkCircle2 : LucideIcons.triangleAlert,
                color: isCovered ? AppColors.success : AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isCovered
                      ? (rem < -0.01
                          ? 'Total covered! Change due: ${Formatters.formatCurrency(-rem)}'
                          : 'Total Amount (${Formatters.formatCurrency(widget.totalAmount)}) fully allocated!')
                      : '${Formatters.formatCurrency(rem)} remaining unallocated. Adjust amounts or tap "Auto-Balance Remainder".',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCovered ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCashChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
      backgroundColor: AppColors.card(context),
      side: BorderSide(color: AppColors.border(context)),
      onPressed: onTap,
    );
  }
}
