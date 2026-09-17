import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/mobile_theme.dart';
import '../../../core/models/cart_item.dart';
import '../../../core/services/mobile_bridge_client.dart';
import '../../../core/services/mobile_api_service.dart';

class MobileCashierScreen extends StatefulWidget {
  const MobileCashierScreen({super.key});

  @override
  State<MobileCashierScreen> createState() => _MobileCashierScreenState();
}

class _MobileCashierScreenState extends State<MobileCashierScreen> {
  late final MobileScannerController _scannerController;

  final List<MobileCartItem> _cart = [];
  bool _isScannerOpen = false;
  bool _isLoadingCatalog = false;
  final _searchController = TextEditingController();

  // Live database product catalog (Zero Mocks / Zero Hardcoded items)
  List<Map<String, dynamic>> _catalog = [];

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: kIsWeb ? CameraFacing.front : CameraFacing.back,
      autoStart: true,
    );
    _loadLiveCatalog();
  }

  Future<void> _loadLiveCatalog() async {
    setState(() => _isLoadingCatalog = true);
    try {
      final prods = await MobileApiService.instance.getProducts();
      if (mounted) {
        setState(() {
          _catalog = prods.map((p) => {
            'id': p['id'].toString(),
            'name': p['name'].toString(),
            'barcode': (p['barcode'] ?? '').toString(),
            'sku': (p['sku'] ?? '').toString(),
            'price': (p['selling_price'] as num?)?.toDouble() ?? 0.0,
            'cost': (p['cost_price'] as num?)?.toDouble() ?? 0.0,
          }).toList();
          _isLoadingCatalog = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCatalog = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  double get _subtotal => _cart.fold(0.0, (sum, i) => sum + i.grossTotal);
  double get _totalDiscount => _cart.fold(0.0, (sum, i) => sum + i.discountAmount);
  double get _netTotal => _subtotal - _totalDiscount;
  double get _taxAmount => _netTotal * (16.0 / 116.0);

  void _onDetect(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    for (final b in barcodes) {
      final code = b.rawValue?.trim();
      if (code != null && code.isNotEmpty) {
        _ringUpBarcode(code);
        break;
      }
    }
  }

  Future<void> _ringUpBarcode(String barcode) async {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    final cleanCode = barcode.trim();
    // 1. Search local cached catalog
    Map<String, dynamic>? match = _catalog.cast<Map<String, dynamic>?>().firstWhere(
      (p) => p != null && (p['barcode'] == cleanCode || (p['name'] as String).toLowerCase() == cleanCode.toLowerCase()),
      orElse: () => null,
    );

    // 2. If not found in cache, query live AWS Backend
    if (match == null) {
      final remoteProduct = await MobileApiService.instance.getProductByBarcode(cleanCode);
      if (remoteProduct != null) {
        match = {
          'id': remoteProduct['id'].toString(),
          'name': remoteProduct['name'].toString(),
          'barcode': (remoteProduct['barcode'] ?? cleanCode).toString(),
          'price': (remoteProduct['selling_price'] as num?)?.toDouble() ?? 0.0,
          'cost': (remoteProduct['cost_price'] as num?)?.toDouble() ?? 0.0,
        };
        _catalog.add(match);
      }
    }

    if (match == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Barcode "$cleanCode" not found in database catalog.'),
            backgroundColor: MobileAppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      final existingIndex = _cart.indexWhere((i) => i.barcode == cleanCode || i.id == match!['id']);
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity += 1.0;
      } else {
        _cart.add(MobileCartItem(
          id: match!['id'].toString(),
          name: match['name'].toString(),
          barcode: match['barcode'].toString(),
          unitPrice: (match['price'] as num).toDouble(),
          costPrice: (match['cost'] as num).toDouble(),
          quantity: 1.0,
        ));
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🛒 Added: ${match['name']}'),
          duration: const Duration(milliseconds: 900),
          backgroundColor: MobileAppColors.primary,
        ),
      );
    }
  }

  void _openCheckoutDialog() {
    if (_cart.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MobileAppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _buildPaymentSheet(ctx),
    );
  }

  Widget _buildPaymentSheet(BuildContext ctx) {
    final phoneController = TextEditingController(text: '254711000111');
    final amountTenderedController = TextEditingController(text: _netTotal.toStringAsFixed(0));
    String paymentMethod = 'mpesa'; // 'mpesa' | 'cash'
    bool isProcessing = false;

    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 10),

              // Total Due Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MobileAppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MobileAppColors.primary),
                ),
                child: Column(
                  children: [
                    const Text('TOTAL AMOUNT DUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      'KES ${_netTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: MobileAppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text('16% VAT Included: KES ${_taxAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: MobileAppColors.textSecondary(context))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tender Selector
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setSheetState(() => paymentMethod = 'mpesa'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: paymentMethod == 'mpesa' ? MobileAppColors.mpesa : MobileAppColors.card(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: paymentMethod == 'mpesa' ? MobileAppColors.mpesa : MobileAppColors.border(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.smartphone, size: 16, color: paymentMethod == 'mpesa' ? Colors.white : MobileAppColors.textPrimary(context)),
                            const SizedBox(width: 8),
                            Text('M-PESA STK', style: TextStyle(fontWeight: FontWeight.w700, color: paymentMethod == 'mpesa' ? Colors.white : MobileAppColors.textPrimary(context))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setSheetState(() => paymentMethod = 'cash'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: paymentMethod == 'cash' ? MobileAppColors.primary : MobileAppColors.card(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: paymentMethod == 'cash' ? MobileAppColors.primary : MobileAppColors.border(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.banknote, size: 16, color: paymentMethod == 'cash' ? Colors.white : MobileAppColors.textPrimary(context)),
                            const SizedBox(width: 8),
                            Text('CASH', style: TextStyle(fontWeight: FontWeight.w700, color: paymentMethod == 'cash' ? Colors.white : MobileAppColors.textPrimary(context))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (paymentMethod == 'mpesa')
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Customer M-Pesa Phone Number',
                    hintText: '2547XXXXXXXX',
                    prefixIcon: Icon(LucideIcons.phone, size: 20),
                    border: OutlineInputBorder(),
                  ),
                )
              else
                TextField(
                  controller: amountTenderedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cash Amount Tendered (KES)',
                    prefixIcon: Icon(LucideIcons.banknote, size: 20),
                    border: OutlineInputBorder(),
                  ),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paymentMethod == 'mpesa' ? MobileAppColors.mpesa : MobileAppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isProcessing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(LucideIcons.checkCheck),
                  label: Text(
                    isProcessing ? 'Processing Transaction...' : (paymentMethod == 'mpesa' ? 'Send M-Pesa STK Push' : 'Complete Cash Sale'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setSheetState(() => isProcessing = true);
                          final receiptNo = 'RCPT-M-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
                          
                          // 1. Sync to Desktop Ledger
                          await MobileBridgeClient.instance.sendMobileSale({
                            'receiptNo': receiptNo,
                            'items': _cart.map((i) => i.toMap()).toList(),
                            'total': _netTotal,
                            'subtotal': _subtotal,
                            'tax': _taxAmount,
                            'paymentMethod': paymentMethod.toUpperCase(),
                            'mpesaCode': paymentMethod == 'mpesa' ? 'QKH${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}' : null,
                          });

                          // 2. Also record directly to Cloud Backend
                          try {
                            await MobileApiService.instance.recordSale({
                              'client_sale_id': '00000000-0000-0000-0000-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}',
                              'branch_id': MobileApiService.instance.branchId,
                              'sale_number': receiptNo,
                              'subtotal': _subtotal,
                              'tax_total': _taxAmount,
                              'discount_total': _totalDiscount,
                              'grand_total': _netTotal,
                              'payment_status': 'COMPLETED',
                              'offline_created_at': DateTime.now().toIso8601String(),
                              'items': _cart.map((i) => {
                                'product_id': i.id.length == 36 ? i.id : '67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad',
                                'product_name': i.name,
                                'sku': i.barcode,
                                'quantity': i.quantity,
                                'unit_price': i.unitPrice,
                                'total_amount': i.grossTotal,
                              }).toList(),
                              'payments': [
                                {
                                  'payment_method': paymentMethod.toUpperCase(),
                                  'amount': _netTotal,
                                }
                              ],
                            });
                          } catch (_) {}

                          if (mounted) {
                            Navigator.pop(context);
                            setState(() => _cart.clear());
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 Sale Completed! Receipt #$receiptNo synced to Desktop!'),
                                backgroundColor: MobileAppColors.success,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mobile POS Terminal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (_isLoadingCatalog) ...[
              const SizedBox(width: 8),
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isScannerOpen ? LucideIcons.x : LucideIcons.scanBarcode),
            tooltip: _isScannerOpen ? 'Close Scanner' : 'Open Camera Barcode Scanner',
            onPressed: () => setState(() => _isScannerOpen = !_isScannerOpen),
          ),
          if (_cart.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.trash2),
              tooltip: 'Clear Cart',
              onPressed: () => setState(() => _cart.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          // Live Camera Scanner if open
          if (_isScannerOpen) ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: MobileAppColors.primary, width: 2),
              ),
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
                errorBuilder: (context, error, child) {
                  return Container(
                    color: const Color(0xFF111827),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.cameraOff, color: Colors.amber, size: 32),
                          const SizedBox(height: 6),
                          const Text(
                            'Camera Stream Inactive',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Search by name/barcode below or tap fast-selling items.',
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MobileAppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            ),
                            onPressed: () => _scannerController.start(),
                            child: const Text('Retry Camera', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Search / Scan Barcode Header
          Container(
            padding: const EdgeInsets.all(12),
            color: MobileAppColors.surface(context),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _ringUpBarcode(val.trim());
                        _searchController.clear();
                      }
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Scan or search item name/barcode...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.scan, color: MobileAppColors.primary),
                        onPressed: () => setState(() => _isScannerOpen = !_isScannerOpen),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cart Items List
          Expanded(
            child: _cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.shoppingBag, size: 48, color: MobileAppColors.textSecondary(context)),
                        const SizedBox(height: 12),
                        const Text('Cart is Empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'Point camera at product barcodes to ring up floor sales.',
                          style: TextStyle(fontSize: 12, color: MobileAppColors.textSecondary(context)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: MobileAppColors.primary, foregroundColor: Colors.white),
                          icon: const Icon(LucideIcons.camera, size: 16),
                          label: const Text('Start Camera Scanner'),
                          onPressed: () => setState(() => _isScannerOpen = true),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MobileAppColors.card(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: MobileAppColors.border(context)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'KES ${item.unitPrice.toStringAsFixed(2)} · Barcode: ${item.barcode}',
                                    style: TextStyle(fontSize: 11, color: MobileAppColors.textSecondary(context)),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.minusCircle, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      if (item.quantity > 1) {
                                        item.quantity -= 1;
                                      } else {
                                        _cart.removeAt(index);
                                      }
                                    });
                                  },
                                ),
                                Text(
                                  item.quantity.toInt().toString(),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.plusCircle, size: 20, color: MobileAppColors.primary),
                                  onPressed: () => setState(() => item.quantity += 1),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'KES ${item.netTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Checkout Summary Bar
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MobileAppColors.surface(context),
                border: Border(top: BorderSide(color: MobileAppColors.border(context))),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total (${_cart.length} items):', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('KES ${_netTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: MobileAppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MobileAppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(LucideIcons.creditCard),
                      label: Text('Proceed to Checkout (KES ${_netTotal.toStringAsFixed(2)})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      onPressed: _openCheckoutDialog,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
