import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/printing_service.dart';
import '../../../core/services/wireless_bridge_service.dart';
import '../../shell/widgets/mobile_pairing_dialog.dart';
import '../models/cart_item.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/receipt_dialog.dart';
import '../widgets/supervisor_void_dialog.dart';
import '../widgets/printer_settings_dialog.dart';

import '../../../core/network/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class CashierScreen extends StatefulWidget {
  final String organizationId;
  final String organizationName;
  final String branchId;
  final String branchName;
  final String tillNumber;

  const CashierScreen({
    super.key,
    this.organizationId = '',
    this.organizationName = 'GIFTMART SUPERMARKET',
    this.branchId = '',
    this.branchName = 'Main Branch',
    this.tillNumber = 'TILL-01',
  });

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final _searchController = TextEditingController();
  final _barcodeFocusNode = FocusNode();
  final ApiService _apiService = ApiService();
  StreamSubscription<String>? _barcodeSub;

  int _pendingSyncSalesCount = 0;
  bool _isLoadingCatalog = false;
  String? _scanErrorMessage;

  List<Map<String, dynamic>> _catalog = [];
  final List<CartItem> _cart = [];
  final List<List<CartItem>> _heldSales = [];
  CartItem? _lastScannedItem;
  DateTime _lastScanTime = DateTime.fromMillisecondsSinceEpoch(0);

  final Map<String, Map<String, dynamic>> _barcodeIndex = {};
  final Map<String, Map<String, dynamic>> _skuIndex = {};
  final Map<String, Map<String, dynamic>> _nameIndex = {};

  bool _isSubmittingBarcode = false;
  String? _lastProcessedBarcode;
  DateTime _lastProcessedTime = DateTime.fromMillisecondsSinceEpoch(0);

  void _indexProduct(Map<String, dynamic> p) {
    final itemBc = ((p['barcode'] ?? '') as String).trim();
    if (itemBc.isNotEmpty) _barcodeIndex[itemBc] = p;

    final List<dynamic> bcs = p['barcodes'] is List ? p['barcodes'] : [itemBc];
    for (final b in bcs) {
      final s = b.toString().trim();
      if (s.isNotEmpty) _barcodeIndex[s] = p;
    }

    final itemSku = ((p['sku'] ?? '') as String).toLowerCase().trim();
    if (itemSku.isNotEmpty) _skuIndex[itemSku] = p;

    final itemName = ((p['name'] ?? '') as String).toLowerCase().trim();
    if (itemName.isNotEmpty) _nameIndex[itemName] = p;
  }

  @override
  void initState() {
    super.initState();
    PrintingService.instance.init().then((_) {
      if (mounted) setState(() {});
    });
    if (!WirelessBridgeService.instance.isRunning) {
      WirelessBridgeService.instance.startServer();
    }
    _barcodeSub = WirelessBridgeService.instance.barcodeStream.listen((barcode) {
      if (mounted && barcode.isNotEmpty) {
        _searchController.text = barcode;
        _handleBarcodeOrSearchSubmit(barcode);
      }
    });
    _loadCatalog();
    HardwareKeyboard.instance.addHandler(_handleCashierKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocusNode.requestFocus();
    });
  }

  /// Safely parse a price value that may come as a String (BigDecimal from Rust),
  /// an int, a double, or null from the JSON API response.
  double _parsePrice(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  /// Returns true if the string looks like a numeric barcode:
  /// contains only digits and/or '/' (scanner misread when NumLock is off).
  bool _looksLikeEan(String s) {
    if (s.isEmpty) return false;
    return RegExp(r'^[\d/]+$').hasMatch(s);
  }

  Future<void> _loadCatalog() async {
    final prefs = await SharedPreferences.getInstance();
    String orgId = widget.organizationId;
    if (orgId.isEmpty) {
      orgId = prefs.getString(AppConstants.keyOrgId) ?? '67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad';
    }
    String branchId = widget.branchId;
    if (branchId.isEmpty) {
      branchId = prefs.getString(AppConstants.keyBranchId) ?? '';
    }
    setState(() => _isLoadingCatalog = true);
    try {
      final prods = await _apiService.getProducts(orgId, branchId: branchId.isNotEmpty ? branchId : null);
      if (mounted) {
        setState(() {
          _barcodeIndex.clear();
          _skuIndex.clear();
          _nameIndex.clear();
          _catalog = prods.map((p) {
            final mapped = {
              'id': p['id'].toString(),
              'name': p['name'].toString(),
              'sku': (p['sku'] ?? '').toString(),
              'barcode': (p['barcode'] ?? '').toString(),
              'barcodes': p['barcodes'] ?? [p['barcode']],
              'price': _parsePrice(p['selling_price']),
              'cost': _parsePrice(p['cost_price']),
              'taxRate': _parsePrice(p['tax_rate'], fallback: 16.0),
              'stock': _parsePrice(p['current_stock'], fallback: 0.0),
              'trackStock': p['track_stock'] != false,
              'allowNegativeStock': p['allow_negative_stock'] == true,
            };
            _indexProduct(mapped);
            return mapped;
          }).toList();
          _isLoadingCatalog = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCatalog = false);
    }
  }

  @override
  void dispose() {
    _barcodeSub?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleCashierKeyEvent);
    _searchController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  bool _handleCashierKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    final isControlPressed = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;

    // F1: Quick Item Dialog
    if (key == LogicalKeyboardKey.f1) {
      _openQuickItemDialog();
      return true;
    }

    // F2 or Ctrl+Enter: Pay & Checkout
    if (key == LogicalKeyboardKey.f2 || (isControlPressed && (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter))) {
      if (_cart.isNotEmpty) {
        _handleCheckout();
      }
      return true;
    }

    // Enter / Numpad Enter: Always submit Barcode if search field has text
    // (Bypasses Windows Flutter limitation where Numpad Enter doesn't trigger onSubmitted while focused)
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _searchController.clear();
        _handleBarcodeOrSearchSubmit(query);
        return true;
      }
    }
    if (key == LogicalKeyboardKey.space && !_barcodeFocusNode.hasFocus && _cart.isNotEmpty) {
      _handleCheckout();
      return true;
    }

    // F3 or Ctrl+D: Apply Discount
    if (key == LogicalKeyboardKey.f3 || (isControlPressed && key == LogicalKeyboardKey.keyD)) {
      _openDiscountDialog();
      return true;
    }

    // F4 or Ctrl+H: Hold / Park Sale
    if (key == LogicalKeyboardKey.f4 || (isControlPressed && key == LogicalKeyboardKey.keyH)) {
      _holdCurrentSale();
      return true;
    }

    // F5 or Ctrl+R: Recall Sale / Refresh Catalog
    if (key == LogicalKeyboardKey.f5 || (isControlPressed && key == LogicalKeyboardKey.keyR)) {
      _recallHeldSale();
      return true;
    }

    // F6 or Ctrl+P: Print Test Receipt
    if (key == LogicalKeyboardKey.f6 || (isControlPressed && key == LogicalKeyboardKey.keyP)) {
      _testPrintReceipt();
      return true;
    }

    // Escape: Clear Search or Void Sale
    if (key == LogicalKeyboardKey.escape) {
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        setState(() {});
      } else if (_cart.isNotEmpty) {
        _requestSupervisorVoidTransaction();
      }
      return true;
    }

    // Ctrl+F or Slash when search is not focused
    if ((isControlPressed && key == LogicalKeyboardKey.keyF) || (key == LogicalKeyboardKey.slash && !_barcodeFocusNode.hasFocus)) {
      _barcodeFocusNode.requestFocus();
      return true;
    }

    // + / - shortcuts to adjust quantity of last scanned item
    if (_searchController.text.isEmpty && _cart.isNotEmpty) {
      if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd) {
        final target = _lastScannedItem ?? _cart.first;
        setState(() => target.quantity += 1);
        return true;
      } else if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
        final target = _lastScannedItem ?? _cart.first;
        if (target.quantity > 1) {
          setState(() => target.quantity -= 1);
        }
        return true;
      }
    }

    return false;
  }

  Future<void> _handleBarcodeOrSearchSubmit(String input) async {
    final query = input.replaceAll(RegExp(r'[\r\n\t]'), '').trim();
    if (query.isEmpty) {
      return;
    }

    final now = DateTime.now();
    // Debounce duplicate rapid events (within 400ms) for identical barcode
    if (_lastProcessedBarcode == query && now.difference(_lastProcessedTime).inMilliseconds < 400) {
      return;
    }
    if (_isSubmittingBarcode) return;
    _isSubmittingBarcode = true;
    _lastProcessedBarcode = query;
    _lastProcessedTime = now;
    _lastScanTime = now;

    try {
      double qtyMultiplier = 1.0;
      String cleanBarcode = query;

      // Support multiplier format e.g. "5*6161101234567" or "3*MILK"
      if (query.contains('*')) {
        final parts = query.split('*');
        if (parts.length == 2) {
          qtyMultiplier = double.tryParse(parts[0].trim()) ?? 1.0;
          cleanBarcode = parts[1].trim();
        }
      }

      // EAN-13/UPC barcodes are digit-only. When NumLock is off on a scanner's
      // numpad, the '/' key fires instead of '7'. Normalize those misreads.
      cleanBarcode = cleanBarcode.replaceAll('/', '7').replaceAll(RegExp(r'[\r\n\t\s]'), '').trim();

      // Instant O(1) in-memory index lookup (0.001ms)
      Map<String, dynamic>? found = _barcodeIndex[cleanBarcode] ??
          _skuIndex[cleanBarcode.toLowerCase()] ??
          _nameIndex[cleanBarcode.toLowerCase()];

      if (found == null) {
        // Fallback scan through catalog
        final matches = _catalog.where((p) {
          final itemBc = ((p['barcode'] ?? '') as String).trim();
          final itemSku = ((p['sku'] ?? '') as String).toLowerCase().trim();
          final itemName = ((p['name'] ?? '') as String).toLowerCase().trim();
          final List<dynamic> bcs = p['barcodes'] is List ? p['barcodes'] : [itemBc];
          final matchesBc = itemBc == cleanBarcode || bcs.map((e) => e.toString().trim()).contains(cleanBarcode);
          return matchesBc || itemSku == cleanBarcode.toLowerCase() || itemName == cleanBarcode.toLowerCase();
        }).toList();

        if (matches.isNotEmpty) {
          found = matches.first;
          _indexProduct(found);
        }
      }

      if (found != null) {
        _addToCart(found, quantity: qtyMultiplier);
      } else {
        // Not in local cache — try a live barcode API lookup
        try {
          final prefs = await SharedPreferences.getInstance();
          String orgId = widget.organizationId;
          if (orgId.isEmpty) {
            orgId = prefs.getString(AppConstants.keyOrgId) ?? '67fe86f9-3f43-4db3-9d2d-aaa5fafcf3ad';
          }
          final branchId = widget.branchId.isNotEmpty ? widget.branchId : (prefs.getString(AppConstants.keyBranchId) ?? '');
          final liveProd = await _apiService.getProducts(orgId, branchId: branchId.isNotEmpty ? branchId : null, barcode: cleanBarcode);
          if (liveProd.isNotEmpty) {
            final p = liveProd.first;
            final mapped = {
              'id': p['id'].toString(),
              'name': p['name'].toString(),
              'sku': (p['sku'] ?? '').toString(),
              'barcode': (p['barcode'] ?? '').toString(),
              'barcodes': p['barcodes'] ?? [p['barcode']],
              'price': _parsePrice(p['selling_price']),
              'cost': _parsePrice(p['cost_price']),
              'taxRate': _parsePrice(p['tax_rate'], fallback: 16.0),
              'stock': _parsePrice(p['current_stock'], fallback: 0.0),
              'trackStock': p['track_stock'] != false,
              'allowNegativeStock': p['allow_negative_stock'] == true,
            };
            _catalog.add(mapped);
            _indexProduct(mapped);
            _addToCart(mapped, quantity: qtyMultiplier);
          } else {
            // Barcode/Item NOT in database catalog: REJECT AND ALERT
            if (mounted) {
              setState(() {
                _scanErrorMessage = 'Product with barcode "$cleanBarcode" is NOT in the database catalog.';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Barcode "$cleanBarcode" not found in catalog. Non-registered items cannot be rung up.'),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFFDC2626),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'DISMISS',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            }
          }
        } catch (_) {
          if (mounted) {
            setState(() {
              _scanErrorMessage = 'Barcode "$cleanBarcode" not found. Check network connection.';
            });
          }
        }
      }
    } finally {
      _searchController.clear();
      _barcodeFocusNode.requestFocus();
      _isSubmittingBarcode = false;
    }
  }

  void _addToCart(Map<String, dynamic> product, {double quantity = 1.0}) {
    final stock = _parsePrice(product['stock'], fallback: 999999.0);
    final trackStock = product['trackStock'] != false;
    final allowNegative = product['allowNegativeStock'] == true;

    final existingIndex = _cart.indexWhere((item) => item.id == product['id']);
    if (existingIndex != -1) {
      final newQty = _cart[existingIndex].quantity + quantity;
      if (trackStock && !allowNegative && newQty > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stock Limit: Only ${stock.toInt()} in stock for "${product['name']}". Cannot scan more!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      setState(() {
        _scanErrorMessage = null;
        _cart[existingIndex].quantity = newQty;
        _lastScannedItem = _cart[existingIndex];
      });
    } else {
      if (trackStock && !allowNegative && quantity > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stock Limit: Only ${stock.toInt()} in stock for "${product['name']}". Cannot add more!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      final price = _parsePrice(product['price']);
      final cost = _parsePrice(product['cost'] ?? product['price']);
      final newItem = CartItem(
        id: product['id'].toString(),
        name: product['name'].toString(),
        sku: (product['sku'] ?? '').toString(),
        barcode: (product['barcode'] ?? '').toString(),
        unitPrice: price,
        costPrice: cost,
        quantity: quantity,
        taxRate: _parsePrice(product['taxRate'], fallback: 16.0),
        availableStock: stock,
        trackStock: trackStock,
        allowNegativeStock: allowNegative,
      );
      setState(() {
        _scanErrorMessage = null;
        _cart.insert(0, newItem);
        _lastScannedItem = newItem;
      });
    }
  }

  void _updateQuantity(int index, double delta) {
    final currentQty = _cart[index].quantity;
    if (delta < 0 && currentQty <= 1) {
      _requestSupervisorVoidItem(index);
      return;
    }
    final newQty = currentQty + delta;
    if (delta > 0 && _cart[index].trackStock && !_cart[index].allowNegativeStock && newQty > _cart[index].availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot exceed available stock (${_cart[index].availableStock.toInt()} in stock).',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _cart[index].quantity = newQty;
    });
    _barcodeFocusNode.requestFocus();
  }

  void _requestSupervisorVoidItem(int index) {
    if (index < 0 || index >= _cart.length) return;
    final item = _cart[index];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SupervisorVoidDialog(
        branchName: widget.branchName,
        item: item,
        isTransactionVoid: false,
        onAuthorizedQuantity: (voidQty) {
          setState(() {
            if (voidQty >= item.quantity) {
              _cart.removeAt(index);
              if (_lastScannedItem?.id == item.id) {
                _lastScannedItem = null;
              }
            } else {
              item.quantity -= voidQty;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                voidQty >= item.quantity
                    ? 'Item "${item.name}" voided completely. Authorized by Supervisor.'
                    : 'Voided $voidQty unit(s) of "${item.name}" (remaining: ${item.quantity.toInt()}). Authorized by Supervisor.',
              ),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 2),
            ),
          );
          _barcodeFocusNode.requestFocus();
        },
        onAuthorized: () {
          setState(() {
            _cart.removeAt(index);
            if (_lastScannedItem?.id == item.id) {
              _lastScannedItem = null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item "${item.name}" voided. Authorized by Supervisor.'),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 2),
            ),
          );
          _barcodeFocusNode.requestFocus();
        },
      ),
    );
  }

  void _requestSupervisorVoidTransaction() {
    if (_cart.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SupervisorVoidDialog(
        branchName: widget.branchName,
        isTransactionVoid: true,
        totalItemCount: _cart.length,
        totalAmount: _cartNetTotal,
        onAuthorized: () {
          setState(() {
            _cart.clear();
            _lastScannedItem = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entire register sale voided. Authorized by Supervisor.'),
              backgroundColor: AppColors.danger,
              duration: Duration(seconds: 2),
            ),
          );
          _barcodeFocusNode.requestFocus();
        },
      ),
    );
  }

  void _openQuickItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border(context)),
        ),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Manual Till Item Ring Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(LucideIcons.x, size: 18, color: AppColors.textMuted(context))),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: TextStyle(color: AppColors.textPrimary(context)),
                decoration: const InputDecoration(labelText: 'Item Name / Description', hintText: 'e.g. Loose Bananas 1kg, Shopping Bag'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppColors.textPrimary(context)),
                      decoration: const InputDecoration(labelText: 'Unit Price (KES)', hintText: 'e.g. 150'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppColors.textPrimary(context)),
                      decoration: const InputDecoration(labelText: 'Quantity', hintText: '1'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      final name = nameController.text.trim();
                      final price = double.tryParse(priceController.text) ?? 0.0;
                      final qty = double.tryParse(qtyController.text) ?? 1.0;

                      if (name.isNotEmpty && price > 0) {
                        final newItem = CartItem(
                          id: 'manual-${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          unitPrice: price,
                          costPrice: price * 0.8,
                          quantity: qty,
                          taxRate: 16.0,
                        );
                        setState(() {
                          _cart.insert(0, newItem);
                          _lastScannedItem = newItem;
                        });
                        Navigator.pop(ctx);
                        _barcodeFocusNode.requestFocus();
                      }
                    },
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Add to Till Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double get _cartSubtotal => _cart.fold(0.0, (sum, item) => sum + item.grossTotal);
  double get _cartDiscount => _cart.fold(0.0, (sum, item) => sum + item.discountAmount);
  double get _cartTaxAmount => _cart.fold(0.0, (sum, item) => sum + item.taxAmount);
  double get _cartNetTotal => _cart.fold(0.0, (sum, item) => sum + item.netTotal);
  double get _totalQuantity => _cart.fold(0.0, (sum, item) => sum + item.quantity);

  void _handleCheckout() {
    if (_cart.isEmpty) return;
    if (DateTime.now().difference(_lastScanTime).inMilliseconds < 800) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PaymentDialog(
        totalAmount: _cartNetTotal,
        branchName: widget.branchName,
        branchId: widget.branchId,
        tillNumber: widget.tillNumber,
        onPaymentSuccess: (paymentMethod, amountPaid, mpesaCode) {
          Navigator.pop(ctx);
          _completeSaleAndPrint(paymentMethod, amountPaid, mpesaCode);
        },
      ),
    );
  }

  void _completeSaleAndPrint(String paymentMethod, double amountPaid, String? mpesaCode) {
    final cartSnapshot = List<CartItem>.from(_cart);
    final receiptNo = 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';

    final saleData = {
      'receiptNo': receiptNo,
      'dateTime': DateTime.now(),
      'cashier': 'Active Cashier',
      'storeName': widget.organizationName,
      'branchName': widget.branchName,
      'tillNumber': widget.tillNumber,
      'items': cartSnapshot,
      'subtotal': _cartSubtotal,
      'discount': _cartDiscount,
      'tax': _cartTaxAmount,
      'total': _cartNetTotal,
      'paymentMethod': paymentMethod,
      'amountPaid': amountPaid,
      'change': amountPaid > _cartNetTotal ? amountPaid - _cartNetTotal : 0.0,
      'mpesaCode': mpesaCode,
    };

    // Fast background thermal receipt auto-print (zero UI blocking)
    PrintingService.instance.autoPrintReceipt(saleData);

    // Save locally for instant real-time reports & offline ledger
    _persistCompletedSaleLocally(saleData);

    // Post sale to backend (background) — deducts stock, records sale & payments
    _postSaleToBackend(cartSnapshot, paymentMethod, amountPaid, mpesaCode, receiptNo);

    showDialog(
      context: context,
      builder: (ctx) => ReceiptDialog(
        saleData: saleData,
        onNewSale: () {
          Navigator.pop(ctx);
          setState(() {
            _cart.clear();
            _lastScannedItem = null;
          });
          _barcodeFocusNode.requestFocus();
        },
      ),
    );

    setState(() {
      _pendingSyncSalesCount++;
    });
  }

  Future<void> _postSaleToBackend(
    List<CartItem> items,
    String paymentMethod,
    double amountPaid,
    String? mpesaCode,
    String receiptNo,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orgId = widget.organizationId.isNotEmpty
          ? widget.organizationId
          : (prefs.getString(AppConstants.keyOrgId) ?? '');
      final branchId = widget.branchId.isNotEmpty
          ? widget.branchId
          : (prefs.getString(AppConstants.keyBranchId) ?? '');

      final subtotal = items.fold(0.0, (s, i) => s + i.grossTotal);
      final discount = items.fold(0.0, (s, i) => s + i.discountAmount);
      final tax = items.fold(0.0, (s, i) => s + i.taxAmount);
      final grand = items.fold(0.0, (s, i) => s + i.netTotal);

      // Decrement stock in local catalog cache immediately
      try {
        final catKey = 'hirall_branch_catalog_${widget.branchName}';
        final savedCat = prefs.getString(catKey);
        if (savedCat != null && savedCat.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(savedCat);
          final updated = decoded.map((e) {
            final map = Map<String, dynamic>.from(e);
            for (final sold in items) {
              if (sold.sku == map['sku'] || (sold.barcode.isNotEmpty && sold.barcode == map['barcode']) || sold.name == map['name']) {
                final cur = double.tryParse(map['stock']?.toString() ?? '0') ?? 0.0;
                map['stock'] = cur - sold.quantity;
              }
            }
            return map;
          }).toList();
          await prefs.setString(catKey, jsonEncode(updated));
        }
      } catch (_) {}

      final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

      final payload = {
        'client_sale_id': _uuid(),
        if (orgId.isNotEmpty) 'organization_id': orgId,
        'branch_id': branchId,
        'sale_number': receiptNo,
        'subtotal': subtotal,
        'tax_total': tax,
        'discount_total': discount,
        'grand_total': grand,
        'payment_status': 'PAID',
        'offline_created_at': DateTime.now().toUtc().toIso8601String(),
        'items': items.map((item) {
          final prodId = uuidRegex.hasMatch(item.id)
              ? item.id
              : '04d218a0-55ea-4c43-aad3-cb5cc82e8738';
          return {
            'product_id': prodId,
            'product_name': item.name,
            'sku': item.sku.isNotEmpty ? item.sku : item.id,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'tax_rate': item.taxRate,
            'tax_amount': item.taxAmount,
            'discount_amount': item.discountAmount,
            'total_amount': item.netTotal,
          };
        }).toList(),
        'payments': [
          {
            'payment_method': paymentMethod.toUpperCase().replaceAll(' ', '_'),
            'amount': amountPaid,
            'currency': 'KES',
            if (mpesaCode != null && mpesaCode.isNotEmpty) 'reference': mpesaCode,
            'change_given': amountPaid > grand ? amountPaid - grand : 0.0,
          }
        ],
      };

      await _apiService.recordSale(payload);
      if (mounted) {
        setState(() {
          if (_pendingSyncSalesCount > 0) _pendingSyncSalesCount--;
        });
      }
    } catch (e) {
      // Sale will remain in pending sync count — retry on next session
      debugPrint('Sale sync failed: $e');
    }
  }

  Future<void> _persistCompletedSaleLocally(Map<String, dynamic> sale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const key = 'hirall_recorded_sales';
      final existingJson = prefs.getString(key);
      List<dynamic> list = [];
      if (existingJson != null && existingJson.isNotEmpty) {
        list = jsonDecode(existingJson);
      }
      final itemsSnapshot = (sale['items'] as List<CartItem>).map((i) => {
        'name': i.name,
        'sku': i.sku,
        'quantity': i.quantity,
        'unitPrice': i.unitPrice,
        'costPrice': i.costPrice,
        'taxAmount': i.taxAmount,
        'discountAmount': i.discountAmount,
        'netTotal': i.netTotal,
      }).toList();

      final record = {
        'receiptNo': sale['receiptNo'],
        'dateTime': (sale['dateTime'] as DateTime).toIso8601String(),
        'storeName': sale['storeName'],
        'branchName': sale['branchName'],
        'tillNumber': sale['tillNumber'],
        'subtotal': sale['subtotal'],
        'discount': sale['discount'],
        'tax': sale['tax'],
        'total': sale['total'],
        'paymentMethod': sale['paymentMethod'],
        'amountPaid': sale['amountPaid'],
        'mpesaCode': sale['mpesaCode'],
        'items': itemsSnapshot,
      };

      list.insert(0, record);
      if (list.length > 500) list = list.sublist(0, 500);
      await prefs.setString(key, jsonEncode(list));
    } catch (_) {}
  }

  /// Generate a UUID v4 for client-side sale deduplication.
  String _uuid() {
    final r = DateTime.now().microsecondsSinceEpoch;
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(
      RegExp(r'[xy]'),
      (m) {
        final v = (r + m.start * 16) % 16;
        return (m.group(0) == 'x' ? v : (v & 0x3 | 0x8)).toRadixString(16);
      },
    );
  }

  void _openPrinterSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => PrinterSettingsDialog(
        branchName: widget.branchName,
        tillNumber: widget.tillNumber,
      ),
    ).then((_) => setState(() {}));
  }

  void _testPrintReceipt() {
    PrintingService.instance.printTestReceipt(
      branchName: widget.branchName,
      tillNumber: widget.tillNumber,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fast test receipt sent to thermal printer! (Press F6 anytime)'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openDiscountDialog() {
    if (_cart.isEmpty) return;

    final discountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border(context)),
        ),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Apply Discount (F3)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(LucideIcons.x, size: 18, color: AppColors.textMuted(context))),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: discountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppColors.textPrimary(context)),
                decoration: const InputDecoration(labelText: 'Discount Percentage (%)', hintText: 'e.g. 5, 10, 15'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final pct = double.tryParse(discountController.text) ?? 0.0;
                      if (pct > 0 && pct <= 100) {
                        setState(() {
                          if (_lastScannedItem != null) {
                            _lastScannedItem!.discountPercent = pct;
                          } else {
                            for (var item in _cart) {
                              item.discountPercent = pct;
                            }
                          }
                        });
                        Navigator.pop(ctx);
                        _barcodeFocusNode.requestFocus();
                      }
                    },
                    child: const Text('Apply Discount'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _holdCurrentSale() {
    if (_cart.isEmpty) return;
    setState(() {
      _heldSales.add(List<CartItem>.from(_cart));
      _cart.clear();
      _lastScannedItem = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sale parked and held (${_heldSales.length} on hold). Press F5 to recall.'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
    _barcodeFocusNode.requestFocus();
  }

  void _recallHeldSale() {
    if (_heldSales.isEmpty) {
      _loadCatalog();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No held sales in queue. Product catalog refreshed.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final recalled = _heldSales.removeLast();
    setState(() {
      _cart.clear();
      _cart.addAll(recalled);
      _lastScannedItem = _cart.isNotEmpty ? _cart.first : null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Held sale restored (${_cart.length} items).'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    _barcodeFocusNode.requestFocus();
  }

  Widget _buildKeyboardShortcutsBar(BuildContext context) {
    final shortcuts = [
      {'key': 'F1', 'label': 'Quick Item'},
      {'key': 'F2', 'label': 'Pay / Checkout'},
      {'key': 'F3', 'label': 'Discount'},
      {'key': 'F4', 'label': 'Hold Sale'},
      {'key': 'F5', 'label': 'Recall Sale'},
      {'key': 'F6', 'label': 'Print Test'},
      {'key': 'Esc', 'label': 'Void Sale'},
      {'key': '+ / -', 'label': 'Adjust Qty'},
    ];
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: shortcuts.map((s) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.bg(context),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.border(context)),
              ),
              child: Text(
                s['key']!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              s['label']!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (!_barcodeFocusNode.hasFocus) {
            final query = _searchController.text.trim();
            if (query.isNotEmpty) {
              _searchController.clear();
              _handleBarcodeOrSearchSubmit(query);
            }
          }
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
          if (!_barcodeFocusNode.hasFocus) {
            final query = _searchController.text.trim();
            if (query.isNotEmpty) {
              _searchController.clear();
              _handleBarcodeOrSearchSubmit(query);
            }
          }
        },
        const SingleActivator(LogicalKeyboardKey.f2): () {
          if (_cart.isNotEmpty) _handleCheckout();
        },
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (_cart.isNotEmpty && !_barcodeFocusNode.hasFocus) _handleCheckout();
        },
        const SingleActivator(LogicalKeyboardKey.escape): _requestSupervisorVoidTransaction,
        const SingleActivator(LogicalKeyboardKey.f1): _openQuickItemDialog,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.bg(context),
          bottomNavigationBar: _buildKeyboardShortcutsBar(context),
          body: Row(
            children: [
              // Left: Live Counter Till Scanned Goods Feed (65%)
              Expanded(
                flex: 65,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Barcode Scanner Header
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _barcodeFocusNode,
                              textInputAction: TextInputAction.go,
                              onChanged: (val) {
                                final clean = val.replaceAll(RegExp(r'[\r\n\t]'), '').trim();
                                if (val.contains('\n') || val.contains('\r')) {
                                  _searchController.clear();
                                  if (clean.isNotEmpty) {
                                    _handleBarcodeOrSearchSubmit(clean);
                                  }
                                  return;
                                }
                                // Instant auto-ringup: If a complete barcode matching the catalog is entered/scanned
                                String codeToCheck = clean;
                                if (clean.contains('*')) {
                                  final parts = clean.split('*');
                                  if (parts.length == 2) codeToCheck = parts[1].trim();
                                }
                                if (codeToCheck.length >= 8 && _barcodeIndex.containsKey(codeToCheck)) {
                                  _searchController.clear();
                                  _handleBarcodeOrSearchSubmit(clean);
                                }
                              },
                              onSubmitted: (val) {
                                final clean = val.replaceAll(RegExp(r'[\r\n\t]'), '').trim();
                                if (clean.isNotEmpty) {
                                  _searchController.clear();
                                  _handleBarcodeOrSearchSubmit(clean);
                                }
                              },
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
                              decoration: InputDecoration(
                                hintText: 'Scan item barcode with laser scanner or enter code (e.g. 5*616110)...',
                                prefixIcon: const Icon(LucideIcons.scanBarcode, color: AppColors.primary, size: 22),
                                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: _searchController,
                                  builder: (context, value, child) {
                                    final hasText = value.text.isNotEmpty;
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (hasText)
                                          IconButton(
                                            icon: const Icon(LucideIcons.arrowRightCircle, color: AppColors.primary, size: 20),
                                            tooltip: 'Ring Up Item (Enter)',
                                            onPressed: () {
                                              final q = _searchController.text.trim();
                                              if (q.isNotEmpty) {
                                                _searchController.clear();
                                                _handleBarcodeOrSearchSubmit(q);
                                              }
                                            },
                                          ),
                                        if (hasText)
                                          IconButton(
                                            icon: const Icon(LucideIcons.x, size: 16),
                                            tooltip: 'Clear',
                                            onPressed: () => _searchController.clear(),
                                          ),
                                        if (!hasText)
                                          const Padding(
                                            padding: EdgeInsets.only(right: 12),
                                            child: Icon(LucideIcons.scanLine, color: AppColors.primary, size: 20),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _openQuickItemDialog,
                            icon: const Icon(LucideIcons.plusCircle, size: 16),
                            label: const Text('Quick Ring Up (F1)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface(context),
                              foregroundColor: AppColors.textPrimary(context),
                              side: BorderSide(color: AppColors.border(context)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => MobilePairingDialog(
                                  organizationName: widget.organizationName,
                                  branchName: widget.branchName,
                                ),
                              );
                            },
                            icon: const Icon(LucideIcons.smartphone, size: 16, color: AppColors.primary),
                            label: StreamBuilder<int>(
                              stream: WirelessBridgeService.instance.connectedDevicesCountStream,
                              initialData: WirelessBridgeService.instance.connectedDevicesCount,
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                return Text(
                                  count > 0 ? 'Mobile Scanner ($count)' : 'Pair Mobile',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: count > 0 ? AppColors.success : AppColors.textPrimary(context),
                                  ),
                                );
                              },
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface(context),
                              foregroundColor: AppColors.textPrimary(context),
                              side: BorderSide(color: AppColors.border(context)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Cloud Sync Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border(context)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                const Text('Cloud Sync Active', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
                                if (_pendingSyncSalesCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                    child: Text('$_pendingSyncSalesCount queued', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Thermal Printer Quick Settings Badge
                          InkWell(
                            onTap: _openPrinterSettingsDialog,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.printer,
                                    size: 16,
                                    color: PrintingService.instance.autoPrintEnabled ? AppColors.primary : AppColors.textSecondary(context),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    PrintingService.instance.autoPrintEnabled
                                        ? 'Auto-Print ON (${PrintingService.instance.paperWidthMm}mm)'
                                        : 'Auto-Print OFF',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: PrintingService.instance.autoPrintEnabled ? AppColors.primary : AppColors.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Last Scanned Item Banner (if any)
                      if (_lastScannedItem != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(LucideIcons.checkCircle2, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 10),
                                  Text(
                                    'JUST SCANNED:',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _lastScannedItem!.name,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                                  ),
                                ],
                              ),
                              Text(
                                '${Formatters.formatCurrency(_lastScannedItem!.unitPrice)} × ${_lastScannedItem!.quantity.toStringAsFixed(0)} = ${Formatters.formatCurrency(_lastScannedItem!.netTotal)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),

                      // Scanned Goods Table / Feed Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.shoppingBag, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'SCANNED GOODS AT REGISTER',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context), letterSpacing: 1),
                              ),
                            ],
                          ),
                          Text(
                            '${_cart.length} distinct lines • ${_totalQuantity.toStringAsFixed(0)} items',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Main Counter Till Goods Display Area
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          child: _cart.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: AppColors.bg(context),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.border(context)),
                                        ),
                                        child: Icon(LucideIcons.scanBarcode, size: 48, color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Counter Register is Ready for Scanning',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Pass items across the barcode scanner or type barcode/SKU above.',
                                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context)),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.bg(context),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.border(context)),
                                        ),
                                        child: Text(
                                          'Pro Tip: Type "5*616110..." to scan 5 quantities at once • Press F1 for manual item',
                                          style: TextStyle(fontSize: 11, color: AppColors.textMuted(context), fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: [
                                    // Table Column Headers
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.card(context),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                                        border: Border(bottom: BorderSide(color: AppColors.border(context))),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 36, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted(context)))),
                                          Expanded(flex: 4, child: Text('ITEM DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted(context), letterSpacing: 0.5))),
                                          Expanded(flex: 2, child: Text('BARCODE / SKU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted(context), letterSpacing: 0.5))),
                                          SizedBox(width: 90, child: Text('UNIT PRICE', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted(context), letterSpacing: 0.5))),
                                          const SizedBox(width: 14),
                                          SizedBox(width: 110, child: Center(child: Text('QUANTITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted(context), letterSpacing: 0.5)))),
                                          const SizedBox(width: 14),
                                          SizedBox(width: 100, child: Text('TOTAL (KES)', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted(context), letterSpacing: 0.5))),
                                          const SizedBox(width: 48),
                                        ],
                                      ),
                                    ),

                                    // Scanned Goods List
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount: _cart.length,
                                        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border(context)),
                                        itemBuilder: (context, index) {
                                          final item = _cart[index];
                                          final isLatest = index == 0;

                                          return Container(
                                            color: isLatest ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            child: Row(
                                              children: [
                                                // Line Index
                                                SizedBox(
                                                  width: 36,
                                                  child: Text(
                                                    '${_cart.length - index}',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isLatest ? AppColors.primary : AppColors.textMuted(context)),
                                                  ),
                                                ),

                                                // Item Name
                                                Expanded(
                                                  flex: 4,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item.name,
                                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (item.trackStock)
                                                        Text(
                                                          'Stock: ${item.availableStock.toInt()} available',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: item.quantity >= item.availableStock ? AppColors.warning : AppColors.textSecondary(context),
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      if (item.discountPercent > 0)
                                                        Text(
                                                          '${item.discountPercent.toStringAsFixed(0)}% Discount Applied',
                                                          style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600),
                                                        ),
                                                    ],
                                                  ),
                                                ),

                                                // Barcode / SKU
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    item.barcode.isNotEmpty ? item.barcode : (item.sku.isNotEmpty ? item.sku : 'GENERIC'),
                                                    style: TextStyle(fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: AppColors.textSecondary(context)),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),

                                                // Unit Price
                                                SizedBox(
                                                  width: 90,
                                                  child: Text(
                                                    Formatters.formatCurrency(item.unitPrice),
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
                                                  ),
                                                ),

                                                const SizedBox(width: 14),

                                                // Quantity Controls
                                                SizedBox(
                                                  width: 110,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      InkWell(
                                                        onTap: () => _updateQuantity(index, -1),
                                                        borderRadius: BorderRadius.circular(6),
                                                        child: Container(
                                                          padding: const EdgeInsets.all(4),
                                                          decoration: BoxDecoration(color: AppColors.bg(context), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border(context))),
                                                          child: Icon(LucideIcons.minus, size: 14, color: AppColors.textPrimary(context)),
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                                        child: Text(
                                                          item.quantity.toStringAsFixed(0),
                                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
                                                        ),
                                                      ),
                                                      InkWell(
                                                        onTap: () => _updateQuantity(index, 1),
                                                        borderRadius: BorderRadius.circular(6),
                                                        child: Container(
                                                          padding: const EdgeInsets.all(4),
                                                          decoration: BoxDecoration(color: AppColors.bg(context), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border(context))),
                                                          child: Icon(LucideIcons.plus, size: 14, color: AppColors.textPrimary(context)),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const SizedBox(width: 14),

                                                // Line Total
                                                SizedBox(
                                                  width: 100,
                                                  child: Text(
                                                    Formatters.formatCurrency(item.netTotal),
                                                    textAlign: TextAlign.right,
                                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
                                                  ),
                                                ),

                                                // Remove / Void Button (Requires Supervisor Auth)
                                                SizedBox(
                                                  width: 48,
                                                  child: IconButton(
                                                    icon: Icon(LucideIcons.trash2, size: 15, color: AppColors.danger.withValues(alpha: 0.85)),
                                                    tooltip: 'Void Item (Supervisor Auth Required)',
                                                    onPressed: () => _requestSupervisorVoidItem(index),
                                                  ),
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
                      ),
                    ],
                  ),
                ),
              ),

              // Right: Register Order & Checkout Station Panel (35%)
              Expanded(
                flex: 35,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    border: Border(left: BorderSide(color: AppColors.border(context))),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.receipt, color: AppColors.primary, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Till Register Order',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary(context)),
                              ),
                            ],
                          ),
                          if (_cart.isNotEmpty)
                            TextButton.icon(
                              onPressed: _requestSupervisorVoidTransaction,
                              icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.danger),
                              label: const Text('Void Sale (Esc)', style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),

                      Divider(height: 24, color: AppColors.border(context)),

                      // Total Due Huge Display Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.card(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TOTAL DUE',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.2),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_totalQuantity.toStringAsFixed(0)} Items',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              Formatters.formatCurrency(_cartNetTotal),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary(context),
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Order Summary Breakdown
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bg(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subtotal Gross', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
                                Text(Formatters.formatCurrency(_cartSubtotal), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('VAT (16% Included)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
                                Text(Formatters.formatCurrency(_cartTaxAmount), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Station / Branch', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context))),
                                Text('${widget.tillNumber} • ${widget.branchName}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Primary Charge & Checkout Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _cart.isEmpty ? null : _handleCheckout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(LucideIcons.arrowRightCircle, size: 22),
                          label: const Text(
                            'Charge & Checkout (F2)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
