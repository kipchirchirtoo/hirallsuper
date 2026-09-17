import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/network/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/grn_receiving_view.dart';
import '../widgets/grn_history_view.dart';
import '../widgets/branch_requisitions_view.dart';
import '../widgets/suppliers_view.dart';
import '../widgets/purchase_orders_view.dart';
import '../widgets/stocktake_view.dart';
import '../widgets/inventory_ledger_view.dart';
import '../widgets/csv_product_import_dialog.dart';

class StorekeepingScreen extends StatefulWidget {
  final String? branchId;
  final String branchName;
  final String organizationName;
  final Function(Map<String, dynamic> updatedProduct)? onInventoryChanged;

  const StorekeepingScreen({
    super.key,
    this.branchId,
    this.branchName = 'Giftmart Main Branch',
    this.organizationName = 'GIFTMART SUPERMARKET',
    this.onInventoryChanged,
  });

  @override
  State<StorekeepingScreen> createState() => _StorekeepingScreenState();
}

class _StorekeepingScreenState extends State<StorekeepingScreen> {
  String _effectiveBranchId = '';
  String _selectedTab = 'grn'; // 'catalog', 'grn', 'pos', 'vendors', 'stocktake', 'ledger'
  Map<String, dynamic>? _loadedPoForGrn;

  final _searchController = TextEditingController();
  final _barcodeFocusNode = FocusNode();
  String _selectedFilter = 'all';
  String _selectedCategory = 'all';

  final List<String> _categories = [
    'Dairy',
    'Bakery',
    'Groceries & Grains',
    'Cooking Oils & Fats',
    'Beverages & Soft Drinks',
    'Meat & Deli',
    'Personal Care',
    'Household & Detergents',
    'Stationery & Books',
    'Snacks & Confectionery',
  ];

  List<Map<String, dynamic>> _supermarketCatalog = [];
  final _apiService = ApiService();
  bool _isSyncingBackend = false;

  @override
  void initState() {
    super.initState();
    _loadPersistedCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPersistedCatalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _effectiveBranchId = (widget.branchId != null && widget.branchId!.isNotEmpty)
          ? widget.branchId!
          : (prefs.getString(AppConstants.keyBranchId) ?? '');

      await prefs.remove('hirall_supermarket_catalog_${widget.branchName}');
      await prefs.remove('hirall_supermarket_catalog');

      final saved = prefs.getString('hirall_branch_catalog_$_effectiveBranchId') ??
                    prefs.getString('hirall_branch_catalog_${widget.branchName}');
      if (saved != null && saved.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(saved);
        final filtered = decoded
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) {
              final id = (e['id'] ?? '').toString().toUpperCase();
              final isMock = id.startsWith('MOCK-');
              return !isMock;
            })
            .toList();
        setState(() {
          _supermarketCatalog = filtered;
        });
      } else {
        setState(() {
          _supermarketCatalog = [];
        });
      }
    } catch (_) {
      setState(() {
        _supermarketCatalog = [];
      });
    }

    // Always fetch latest live inventory from backend
    _syncCatalogFromBackend();
  }

  @override
  void reassemble() {
    super.reassemble();
    _syncCatalogFromBackend();
  }

  Future<void> _syncCatalogFromBackend() async {
    if (_isSyncingBackend) return;
    _isSyncingBackend = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final orgId = prefs.getString(AppConstants.keyOrgId) ?? '';
      if (_effectiveBranchId.isEmpty) {
        _effectiveBranchId = (widget.branchId != null && widget.branchId!.isNotEmpty)
            ? widget.branchId!
            : (prefs.getString(AppConstants.keyBranchId) ?? '');
      }
      final prods = await _apiService.getProducts(orgId, branchId: _effectiveBranchId);
      if (mounted) {
        if (prods.isEmpty) {
          setState(() {
            _supermarketCatalog = [];
          });
          await _persistCatalog();
        } else {
          final Map<String, Map<String, dynamic>> dedupMap = {};
          for (var p in prods) {
            final sku = (p['sku'] ?? '').toString();
            final barcode = (p['barcode'] ?? '').toString();
            final key = sku.isNotEmpty ? sku : (barcode.isNotEmpty ? barcode : p['id'].toString());
            if (dedupMap.containsKey(key)) continue;

            final name = (p['name'] ?? '').toString();
            final cost = double.tryParse(p['cost_price']?.toString() ?? '0') ?? 0.0;
            final price = double.tryParse(p['selling_price']?.toString() ?? '0') ?? 0.0;
            final taxRate = double.tryParse(p['tax_rate']?.toString() ?? '16') ?? 16.0;
            final stock = double.tryParse(p['current_stock']?.toString() ?? '0') ?? 0.0;

            final existing = _supermarketCatalog.firstWhere(
              (i) => i['sku'] == sku || (barcode.isNotEmpty && i['barcode'] == barcode),
              orElse: () => <String, dynamic>{},
            );

            dedupMap[key] = {
              'id': p['id'].toString(),
              'sku': sku,
              'barcode': barcode.isNotEmpty ? barcode : (existing['barcode'] ?? ''),
              'barcodes': (p['barcodes'] is List && (p['barcodes'] as List).isNotEmpty)
                  ? (p['barcodes'] as List).map((e) => e.toString()).toList()
                  : (existing['barcodes'] ?? (barcode.isNotEmpty ? [barcode] : [])),
              'name': name,
              'category': existing['category'] ?? 'Stationery & Books',
              'unit': existing['unit'] ?? 'PCS',
              'stock': stock,
              'reorder': existing['reorder'] ?? 10.0,
              'cost': cost,
              'price': price,
              'taxRate': taxRate,
              'shelf': existing['shelf'] ?? 'Aisle 1',
              'supplier': existing['supplier'] ?? 'Primary Supplier',
              'lastReceived': existing['lastReceived'] ?? 'Active',
            };
          }

          final remoteList = dedupMap.values.toList();
          setState(() {
            _supermarketCatalog = remoteList;
          });
          await _persistCatalog();
        }
      }
    } catch (e) {
      debugPrint('Sync catalog error: $e');
    } finally {
      _isSyncingBackend = false;
    }
  }

  Future<void> _persistCatalog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _effectiveBranchId.isNotEmpty
          ? 'hirall_branch_catalog_$_effectiveBranchId'
          : 'hirall_branch_catalog_${widget.branchName}';
      await prefs.setString(cacheKey, jsonEncode(_supermarketCatalog));
    } catch (_) {}
  }

  String _getOrgShortform(String orgName) {
    final clean = orgName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
    if (clean.isEmpty) return 'GS';
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      final single = words[0].toUpperCase();
      return single.length >= 3 ? single.substring(0, 3) : single;
    }
  }

  String _getCategoryCode(String category) {
    final catUpper = category.trim().toUpperCase();
    if (catUpper.contains('DAIRY')) return 'DAIRY';
    if (catUpper.contains('BAKERY') || catUpper.contains('BREAD')) return 'BAK';
    if (catUpper.contains('GRAIN') || catUpper.contains('GROCER') || catUpper.contains('FLOUR')) return 'GRN';
    if (catUpper.contains('OIL') || catUpper.contains('FAT')) return 'OIL';
    if (catUpper.contains('BEV') || catUpper.contains('DRINK') || catUpper.contains('WATER')) return 'BEV';
    if (catUpper.contains('MEAT') || catUpper.contains('BUTCHER') || catUpper.contains('DELI')) return 'MEAT';
    if (catUpper.contains('CARE') || catUpper.contains('BEAUTY') || catUpper.contains('SOAP')) return 'CARE';
    if (catUpper.contains('CLEAN') || catUpper.contains('HOUSE') || catUpper.contains('DETERGENT')) return 'CLN';
    if (catUpper.contains('STAT') || catUpper.contains('BOOK') || catUpper.contains('PEN')) return 'STAT';
    if (catUpper.contains('SNACK') || catUpper.contains('CANDY')) return 'SNCK';

    final sanitized = catUpper.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    return sanitized.length >= 4 ? sanitized.substring(0, 4) : (sanitized.isNotEmpty ? sanitized : 'GEN');
  }

  String _generateUniqueSku({
    required String orgName,
    required String category,
  }) {
    final orgShort = _getOrgShortform(orgName);
    final catCode = _getCategoryCode(category);
    final prefix = '$orgShort-$catCode';

    for (int attempts = 0; attempts < 1000; attempts++) {
      final rand = (1000 + Random().nextInt(8999)).toString();
      final candidateSku = '$prefix-$rand';

      final exists = _supermarketCatalog.any((item) =>
          (item['sku'] ?? '').toString().trim().toUpperCase() == candidateSku);

      if (!exists) {
        return candidateSku;
      }
    }

    return '$prefix-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
  }

  void _openCsvImportDialog() {
    CsvProductImportDialog.show(
      context: context,
      branchName: widget.branchName,
      organizationName: widget.organizationName,
      existingCatalog: _supermarketCatalog,
      onImport: (importedProducts) {
        setState(() {
          for (var p in importedProducts) {
            final idx = _supermarketCatalog.indexWhere((item) => item['barcode'] == p['barcode']);
            if (idx != -1) {
              _supermarketCatalog[idx] = p;
            } else {
              _supermarketCatalog.insert(0, p);
            }
          }
        });
        _persistCatalog();
      },
    );
  }

  /// Returns true if the string looks like a numeric barcode:
  /// contains only digits and/or '/' (scanner misread when NumLock is off).
  bool _looksLikeEan(String s) {
    if (s.isEmpty) return false;
    return RegExp(r'^[\d/]+$').hasMatch(s);
  }

  /// Called when the barcode scanner submits (Enter) on the inventory search field.
  /// If the barcode matches a catalog item → filter to show it.
  /// If not found → auto-open Register dialog with the barcode pre-filled.
  void _handleInventoryBarcodeSubmit(String input) {
    String barcode = input.trim();
    if (barcode.isEmpty) return;

    // EAN-13/UPC barcodes are digit-only. When NumLock is off on a scanner's
    // numpad, the '/' key fires instead of '7'. Normalize those misreads.
    if (_looksLikeEan(barcode)) {
      barcode = barcode.replaceAll('/', '7');
    }

    // Exact barcode match in catalog?
    final match = _supermarketCatalog.where((item) =>
        (item['barcode'] ?? '').toString().trim() == barcode).toList();

    if (match.isNotEmpty) {
      // Product exists — show confirmation, then clear so next scan starts fresh.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found: ${match.first['name']} (${match.first['sku']})'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      // Clear and re-focus so the next scan starts with an empty field.
      Future.delayed(const Duration(milliseconds: 50), () {
        _searchController.clear();
        setState(() {});
        _barcodeFocusNode.requestFocus();
      });
    } else {
      // Not in catalog — clear search and open register dialog with barcode pre-filled.
      _searchController.clear();
      setState(() {});
      _openRegisterProductDialog(initialBarcode: barcode);
    }
  }

  void _openRegisterProductDialog({String initialBarcode = ''}) {
    String cleanInitial = initialBarcode.trim();
    if (_looksLikeEan(cleanInitial)) {
      cleanInitial = cleanInitial.replaceAll('/', '7');
    }
    final nameController = TextEditingController();
    String selectedCategory = '';
    final skuController = TextEditingController();
    final List<String> registeredBarcodes = cleanInitial.isNotEmpty ? [cleanInitial] : [];
    final barcodeInputController = TextEditingController();
    final barcodeScanFocusNode = FocusNode();
    final costController = TextEditingController();
    final priceController = TextEditingController();
    final reorderController = TextEditingController();
    final initialStockController = TextEditingController();
    final shelfController = TextEditingController();
    final supplierController = TextEditingController();
    
    String selectedUnit = '';
    double taxRate = 16.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final cost = double.tryParse(costController.text) ?? 0.0;
          final price = double.tryParse(priceController.text) ?? 0.0;
          final profit = price - cost;
          final marginPct = cost > 0 ? (profit / cost) * 100 : 0.0;

          return Dialog(
            backgroundColor: AppColors.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppColors.border(context), width: 1.5),
            ),
            child: Container(
              width: 960,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.94),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      border: Border(bottom: BorderSide(color: AppColors.border(context), width: 1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Row(
                              children: List.generate(
                                4,
                                (i) => Container(
                                  width: 3.5,
                                  height: 16,
                                  margin: const EdgeInsets.only(right: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Screen Painter: Master Product & Barcode Registration - ${widget.branchName}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                color: AppColors.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _openCsvImportDialog();
                              },
                              icon: const Icon(LucideIcons.fileSpreadsheet, size: 14, color: AppColors.primary),
                              label: const Text('Bulk CSV Import', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary(context)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(context),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border(context)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '01. PRODUCT IDENTIFICATION & SKU MAPPING',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'monospace',
                                          color: AppColors.primary,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Divider(height: 1, color: AppColors.border(context)),
                                      const SizedBox(height: 16),

                                      _buildStackedLabel('Product Name *'),
                                      TextField(
                                        controller: nameController,
                                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
                                        decoration: _buildModernInputDecoration(hint: 'e.g. KASUKU EXERCISE BOOK 96PAGES'),
                                      ),
                                      const SizedBox(height: 16),

                                      _buildStackedLabel('Category * (Type to Search or Select)'),
                                      Autocomplete<String>(
                                        optionsBuilder: (TextEditingValue textEditingValue) {
                                          if (textEditingValue.text.isEmpty) return _categories;
                                          return _categories.where((c) => c.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                        },
                                        onSelected: (String selection) {
                                          setDialogState(() {
                                            selectedCategory = selection;
                                            skuController.text = _generateUniqueSku(
                                              orgName: widget.organizationName,
                                              category: selectedCategory,
                                            );
                                          });
                                        },
                                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                          return TextField(
                                            controller: textEditingController,
                                            focusNode: focusNode,
                                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
                                            decoration: InputDecoration(
                                              hintText: 'Type to search or select category (e.g. Stationery, Bakery)...',
                                              prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.primary),
                                              suffixIcon: const Icon(LucideIcons.chevronDown, size: 16),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                            ),
                                            onChanged: (val) {
                                              setDialogState(() {
                                                selectedCategory = val.trim();
                                                if (selectedCategory.isNotEmpty) {
                                                  skuController.text = _generateUniqueSku(
                                                    orgName: widget.organizationName,
                                                    category: selectedCategory,
                                                  );
                                                } else {
                                                  skuController.clear();
                                                }
                                              });
                                            },
                                          );
                                        },
                                        optionsViewBuilder: (context, onSelected, options) {
                                          return Align(
                                            alignment: Alignment.topLeft,
                                            child: Material(
                                              elevation: 6,
                                              borderRadius: BorderRadius.circular(6),
                                              color: AppColors.card(context),
                                              child: Container(
                                                width: 400,
                                                constraints: const BoxConstraints(maxHeight: 220),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppColors.border(context)),
                                                ),
                                                child: ListView.separated(
                                                  padding: EdgeInsets.zero,
                                                  shrinkWrap: true,
                                                  itemCount: options.length,
                                                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border(context)),
                                                  itemBuilder: (context, index) {
                                                    final opt = options.elementAt(index);
                                                    return ListTile(
                                                      dense: true,
                                                      title: Text(opt, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                                                      hoverColor: AppColors.primary.withValues(alpha: 0.1),
                                                      onTap: () => onSelected(opt),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      _buildStackedLabel('SKU Code *'),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                TextField(
                                                  controller: skuController,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    fontFamily: 'monospace',
                                                    color: AppColors.primary,
                                                  ),
                                                  decoration: _buildModernInputDecoration(hint: 'e.g. GS-STAT-5481 (Select category or click AUTO-GEN)'),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Format: [ORG]-[CAT]-[4-DIGITS]',
                                                  style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textSecondary(context)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                            ),
                                            onPressed: () {
                                              if (selectedCategory.trim().isEmpty) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Please search or select a category first to generate a SKU.'),
                                                    backgroundColor: AppColors.warning,
                                                  ),
                                                );
                                                return;
                                              }
                                              final newSku = _generateUniqueSku(
                                                orgName: widget.organizationName,
                                                category: selectedCategory,
                                              );
                                              setDialogState(() {
                                                skuController.text = newSku;
                                              });
                                            },
                                            icon: const Icon(LucideIcons.dices, size: 16),
                                            label: const Text('AUTO-GEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStackedLabel('Product Barcodes / Scanned Units * (Laser scan physical items or click AUTO-GEN)'),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: barcodeInputController,
                                              focusNode: barcodeScanFocusNode,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                fontFamily: 'monospace',
                                                color: AppColors.textPrimary(context),
                                              ),
                                              decoration: InputDecoration(
                                                hintText: 'Laser scan barcode or enter digits...',
                                                isDense: true,
                                                prefixIcon: const Icon(LucideIcons.scanLine, size: 15, color: AppColors.primary),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              onChanged: (val) {
                                                if (_looksLikeEan(val)) {
                                                  final normalized = val.replaceAll('/', '7');
                                                  if (normalized != val) {
                                                    barcodeInputController.value = TextEditingValue(
                                                      text: normalized,
                                                      selection: TextSelection.collapsed(offset: normalized.length),
                                                    );
                                                  }
                                                }
                                              },
                                              onSubmitted: (val) {
                                                final clean = val.trim().replaceAll('/', '7');
                                                if (clean.isNotEmpty) {
                                                  setDialogState(() {
                                                    if (!registeredBarcodes.contains(clean)) {
                                                      registeredBarcodes.add(clean);
                                                    }
                                                    final curStock = int.tryParse(initialStockController.text) ?? 0;
                                                    initialStockController.text = (curStock + 1).toString();
                                                  });
                                                  barcodeInputController.clear();
                                                  barcodeScanFocusNode.requestFocus();
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                              minimumSize: Size.zero,
                                            ),
                                            onPressed: () {
                                              final clean = barcodeInputController.text.trim().replaceAll('/', '7');
                                              if (clean.isNotEmpty) {
                                                setDialogState(() {
                                                  if (!registeredBarcodes.contains(clean)) {
                                                    registeredBarcodes.add(clean);
                                                  }
                                                  final curStock = int.tryParse(initialStockController.text) ?? 0;
                                                  initialStockController.text = (curStock + 1).toString();
                                                });
                                                barcodeInputController.clear();
                                                barcodeScanFocusNode.requestFocus();
                                              }
                                            },
                                            child: const Text('+ ADD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                                          ),
                                          const SizedBox(width: 6),
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                              minimumSize: Size.zero,
                                            ),
                                            onPressed: () {
                                              final genBarcode = '616' + DateTime.now().millisecondsSinceEpoch.toString().substring(3, 13);
                                              setDialogState(() {
                                                if (!registeredBarcodes.contains(genBarcode)) {
                                                  registeredBarcodes.add(genBarcode);
                                                }
                                              });
                                            },
                                            child: const Text('AUTO-GEN', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.card(context),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: registeredBarcodes.isEmpty
                                                ? AppColors.warning.withValues(alpha: 0.5)
                                                : AppColors.border(context),
                                            width: registeredBarcodes.isEmpty ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  registeredBarcodes.isEmpty ? LucideIcons.alertTriangle : LucideIcons.checkCircle2,
                                                  size: 13,
                                                  color: registeredBarcodes.isEmpty ? AppColors.warning : AppColors.success,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    registeredBarcodes.isEmpty
                                                        ? 'No barcodes scanned yet'
                                                        : '${registeredBarcodes.length} Barcode(s) Scanned',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      fontFamily: 'monospace',
                                                      color: registeredBarcodes.isEmpty ? AppColors.warning : AppColors.success,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (registeredBarcodes.isNotEmpty) ...[
                                                  const SizedBox(width: 8),
                                                  InkWell(
                                                    onTap: () {
                                                      setDialogState(() {
                                                        initialStockController.text = registeredBarcodes.length.toString();
                                                      });
                                                    },
                                                    child: Text(
                                                      'Set stock = ${registeredBarcodes.length}',
                                                      style: const TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppColors.primary,
                                                        decoration: TextDecoration.underline,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (registeredBarcodes.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: registeredBarcodes.asMap().entries.map((entry) {
                                                  final idx = entry.key;
                                                  final bc = entry.value;
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surface(context),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(LucideIcons.barcode, size: 14, color: AppColors.primary),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          bc,
                                                          style: TextStyle(
                                                            fontSize: 12.5,
                                                            fontWeight: FontWeight.w700,
                                                            fontFamily: 'monospace',
                                                            color: AppColors.textPrimary(context),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        InkWell(
                                                          onTap: () {
                                                            setDialogState(() {
                                                              registeredBarcodes.removeAt(idx);
                                                            });
                                                          },
                                                          child: Icon(LucideIcons.x, size: 13, color: AppColors.textSecondary(context)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildStackedLabel('Unit of Measure (Type or Search)'),
                                      Autocomplete<String>(
                                        optionsBuilder: (TextEditingValue textEditingValue) {
                                          const units = ['PCS', 'PACK', 'KG', 'BOTTLE', 'CRATE', 'BOX', 'TIN', 'LITRE', 'DOZEN'];
                                          if (textEditingValue.text.isEmpty) return units;
                                          return units.where((u) => u.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                        },
                                        onSelected: (String val) => setDialogState(() => selectedUnit = val),
                                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                          return TextField(
                                            controller: textEditingController,
                                            focusNode: focusNode,
                                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context)),
                                            decoration: InputDecoration(
                                              hintText: 'Type to search or select unit (e.g. PCS, PACK, KG, LITRE)...',
                                              prefixIcon: const Icon(LucideIcons.search, size: 14, color: AppColors.primary),
                                              suffixIcon: const Icon(LucideIcons.chevronDown, size: 14),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                            ),
                                            onChanged: (val) {
                                              selectedUnit = val.trim();
                                            },
                                          );
                                        },
                                        optionsViewBuilder: (context, onSelected, options) {
                                          return Align(
                                            alignment: Alignment.topLeft,
                                            child: Material(
                                              elevation: 6,
                                              borderRadius: BorderRadius.circular(6),
                                              color: AppColors.card(context),
                                              child: Container(
                                                width: 300,
                                                constraints: const BoxConstraints(maxHeight: 180),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: AppColors.border(context)),
                                                ),
                                                child: ListView.separated(
                                                  padding: EdgeInsets.zero,
                                                  shrinkWrap: true,
                                                  itemCount: options.length,
                                                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border(context)),
                                                  itemBuilder: (context, idx) {
                                                    final opt = options.elementAt(idx);
                                                    return ListTile(
                                                      dense: true,
                                                      title: Text(opt, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary(context))),
                                                      onTap: () => onSelected(opt),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 18),

                              Expanded(
                                flex: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface(context),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border(context)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '02. PRICING, MARGIN & SHELF INVENTORY',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'monospace',
                                          color: AppColors.primary,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Divider(height: 1, color: AppColors.border(context)),
                                      const SizedBox(height: 16),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildStackedLabel('Cost Price (KES) *'),
                                                TextField(
                                                  controller: costController,
                                                  keyboardType: TextInputType.number,
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                                                  onChanged: (_) => setDialogState(() {}),
                                                  decoration: _buildModernInputDecoration(hint: '50.00'),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildStackedLabel('Retail Price (KES) *'),
                                                TextField(
                                                  controller: priceController,
                                                  keyboardType: TextInputType.number,
                                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                                                  onChanged: (_) => setDialogState(() {}),
                                                  decoration: _buildModernInputDecoration(hint: '65.00'),
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
                                          color: profit >= 0 ? AppColors.success.withValues(alpha: 0.12) : AppColors.danger.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: profit >= 0 ? AppColors.success : AppColors.danger),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Margin: ${Formatters.formatCurrency(profit)} (${marginPct.toStringAsFixed(1)}%)',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'monospace',
                                                color: profit >= 0 ? AppColors.success : AppColors.danger,
                                              ),
                                            ),
                                            DropdownButton<double>(
                                              value: taxRate,
                                              dropdownColor: AppColors.card(context),
                                              underline: const SizedBox(),
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                                              isDense: true,
                                              items: const [
                                                DropdownMenuItem(value: 16.0, child: Text('16% Standard VAT')),
                                                DropdownMenuItem(value: 0.0, child: Text('0% Zero-Rated')),
                                              ],
                                              onChanged: (val) => setDialogState(() => taxRate = val!),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildStackedLabel('Initial Stock Qty'),
                                                TextField(
                                                  controller: initialStockController,
                                                  keyboardType: TextInputType.number,
                                                  style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary(context)),
                                                  decoration: _buildModernInputDecoration(hint: '0'),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildStackedLabel('Low-Stock Alert Level'),
                                                TextField(
                                                  controller: reorderController,
                                                  keyboardType: TextInputType.number,
                                                  style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary(context)),
                                                  decoration: _buildModernInputDecoration(hint: '15'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),

                                      _buildStackedLabel('Shelf Location'),
                                      TextField(
                                        controller: shelfController,
                                        style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary(context)),
                                        decoration: _buildModernInputDecoration(hint: 'Aisle 1'),
                                      ),
                                      const SizedBox(height: 14),

                                      _buildStackedLabel('Supplier'),
                                      TextField(
                                        controller: supplierController,
                                        style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary(context)),
                                        decoration: _buildModernInputDecoration(hint: 'e.g. Primary Distributor Ltd'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: AppColors.border(context), thickness: 1),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '// STRICT DUPLICATE GUARD: SKU & BARCODE UNIQUENESS ENFORCED',
                          style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textSecondary(context)),
                        ),
                        Row(
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('CANCEL (ESC)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                              onPressed: () {
                                final cleanName = nameController.text.trim();
                                final cleanSku = skuController.text.trim().toUpperCase();

                                if (cleanName.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter product name.'), backgroundColor: AppColors.warning),
                                  );
                                  return;
                                }

                                if (selectedCategory.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please search and select a category for this product.'),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                  return;
                                }

                                if (registeredBarcodes.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please scan at least one product barcode with laser or click AUTO-GEN.'),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                  return;
                                }

                                if (cleanSku.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please provide or generate a valid SKU code.'), backgroundColor: AppColors.warning),
                                  );
                                  return;
                                }

                                final skuMatches = _supermarketCatalog.where((i) =>
                                    (i['sku'] ?? '').toString().trim().toUpperCase() == cleanSku).toList();
                                if (skuMatches.isNotEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Duplicate SKU Error: SKU "$cleanSku" is already assigned to "${skuMatches.first['name']}".'),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                  return;
                                }

                                // Check duplicate barcodes across catalog
                                for (final bc in registeredBarcodes) {
                                  final bcMatches = _supermarketCatalog.where((i) {
                                    final List<dynamic> bcs = i['barcodes'] is List ? i['barcodes'] : [i['barcode']];
                                    return bcs.map((e) => e.toString().trim()).contains(bc.trim());
                                  }).toList();
                                  if (bcMatches.isNotEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Duplicate Barcode Error: Barcode "$bc" is already registered to "${bcMatches.first['name']}".'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                    return;
                                  }
                                }

                                final costVal = double.tryParse(costController.text) ?? 0.0;
                                final priceVal = double.tryParse(priceController.text) ?? (costVal * 1.25);
                                final stockVal = double.tryParse(initialStockController.text) ?? 0.0;
                                final reorderVal = double.tryParse(reorderController.text) ?? 10.0;
                                
                                final primaryBarcode = registeredBarcodes.first;
                                final sortedBarcodes = registeredBarcodes;

                                final newProduct = {
                                  'id': 'PROD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                  'sku': cleanSku,
                                  'barcode': primaryBarcode,
                                  'barcodes': sortedBarcodes,
                                  'name': cleanName,
                                  'category': selectedCategory,
                                  'unit': selectedUnit.trim().isNotEmpty ? selectedUnit.trim().toUpperCase() : 'PCS',
                                  'stock': stockVal,
                                  'reorder': reorderVal,
                                  'cost': costVal,
                                  'price': priceVal,
                                  'taxRate': taxRate,
                                  'shelf': shelfController.text.trim().isNotEmpty ? shelfController.text.trim() : 'General Shelf',
                                  'supplier': supplierController.text.trim().isNotEmpty ? supplierController.text.trim() : 'Primary Supplier',
                                  'lastReceived': 'Just now',
                                };

                                setState(() {
                                  _supermarketCatalog.insert(0, newProduct);
                                });

                                _persistCatalog();
                                widget.onInventoryChanged?.call(newProduct);

                                // Save to Postgres backend with initial stock balance and all barcodes
                                SharedPreferences.getInstance().then((prefs) {
                                  final branchId = _effectiveBranchId.isNotEmpty
                                      ? _effectiveBranchId
                                      : (prefs.getString(AppConstants.keyBranchId) ?? '');
                                  _apiService.createProduct({
                                    'sku': cleanSku,
                                    'name': cleanName,
                                    'cost_price': costVal,
                                    'selling_price': priceVal,
                                    'tax_rate': taxRate,
                                    'barcode': primaryBarcode,
                                    'barcodes': sortedBarcodes,
                                    'track_stock': true,
                                    'initial_stock': stockVal,
                                    if (branchId.isNotEmpty) 'branch_id': branchId,
                                  }).then((created) {
                                    if (created['id'] != null) {
                                      final idx = _supermarketCatalog.indexWhere((i) => i['sku'] == cleanSku);
                                      if (idx != -1 && mounted) {
                                        setState(() {
                                          _supermarketCatalog[idx]['id'] = created['id'].toString();
                                          if (created['current_stock'] != null) {
                                            _supermarketCatalog[idx]['stock'] = double.tryParse(created['current_stock'].toString()) ?? stockVal;
                                          }
                                        });
                                        _persistCatalog();
                                      }
                                    }
                                  }).catchError((e) {
                                    debugPrint('Backend createProduct error: $e');
                                  });
                                });

                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Product "$cleanName" registered with ${sortedBarcodes.length} barcode(s)! SKU: $cleanSku (Stock: $stockVal $selectedUnit)'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                                // Return focus to barcode field for next scan
                                Future.delayed(Duration.zero, () {
                                  _barcodeFocusNode.requestFocus();
                                });
                              },
                              icon: const Icon(LucideIcons.check, size: 16),
                              label: const Text('COMMIT [REGISTER PRODUCT]', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, fontFamily: 'monospace')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // Dialog closed (commit OR cancel/ESC) — always clear search field and restore scan focus
      // so the next barcode scan is captured cleanly without concatenating leftover characters.
      _searchController.clear();
      Future.delayed(const Duration(milliseconds: 80), () {
        if (mounted) {
          _searchController.clear();
          setState(() {});
          _barcodeFocusNode.requestFocus();
        }
      });
    });
  }

  Widget _buildStackedLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
    );
  }

  Widget _buildFieldLabel(String text, [BuildContext? ctx]) {
    return _buildStackedLabel(text);
  }

  InputDecoration _buildModernInputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    );
  }

  InputDecoration _buildMechanicalInputDecoration({String? hint}) {
    return _buildModernInputDecoration(hint: hint);
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
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: AppColors.textPrimary(context))),
        ),
        input,
      ],
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
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border(context), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: AppColors.primary, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Divider(height: 1, color: AppColors.border(context), thickness: 1),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  double _num(dynamic val, [double defaultVal = 0.0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? defaultVal;
  }

  String _str(dynamic val) {
    if (val == null) return '';
    return val.toString();
  }

  void _openQuickStockInDialog(Map<String, dynamic> item) {
    final qtyController = TextEditingController(text: '10');
    final costController = TextEditingController(text: _num(item['cost']).toStringAsFixed(2));
    final refController = TextEditingController(text: 'RCV-${DateTime.now().millisecondsSinceEpoch % 100000}');
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentStock = _num(item['stock']);
          final unit = _str(item['unit']).isNotEmpty ? _str(item['unit']) : 'PCS';

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(LucideIcons.packagePlus, color: Color(0xFF0D9488), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct Stock Intake',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary(context)),
                      ),
                      Text(
                        _str(item['name']),
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bg(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CURRENT IN-STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary(context))),
                            const SizedBox(height: 2),
                            Text(
                              '${currentStock.toStringAsFixed(0)} $unit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                color: currentStock <= 0 ? AppColors.danger : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('SKU / BARCODE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary(context))),
                            const SizedBox(height: 2),
                            Text(_str(item['sku']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: AppColors.primary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Quantity to Receive (+)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g. 50',
                      suffixText: unit,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Unit Cost (KES)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: costController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reference / Batch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: refController,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final addQty = double.tryParse(qtyController.text.trim()) ?? 0.0;
                        if (addQty <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid positive quantity to receive.')),
                          );
                          return;
                        }

                        final cost = double.tryParse(costController.text.trim()) ?? _num(item['cost']);
                        final ref = refController.text.trim().isNotEmpty ? refController.text.trim() : 'DIRECT_IN';

                        setDialogState(() => isSubmitting = true);

                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final orgId = prefs.getString(AppConstants.keyOrgId) ?? '';
                          final branchId = _effectiveBranchId.isNotEmpty
                              ? _effectiveBranchId
                              : (prefs.getString(AppConstants.keyBranchId) ?? '');

                          final res = await _apiService.recordStockMovement(
                            organizationId: orgId,
                            branchId: branchId,
                            productId: item['id']?.toString() ?? '',
                            sku: _str(item['sku']),
                            movementType: 'PURCHASE',
                            quantity: addQty,
                            unitCost: cost,
                            referenceType: 'DIRECT_RECEIPT',
                            referenceId: ref,
                            notes: 'Direct Master Inventory intake of $addQty $unit',
                          );

                          if (res['success'] == true) {
                            if (mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Successfully received +${addQty.toStringAsFixed(0)} $unit into database!'),
                                    ],
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              await _syncCatalogFromBackend();
                            }
                          } else {
                            if (context.mounted) {
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update DB: ${res['message'] ?? 'Unknown error'}'),
                                  backgroundColor: AppColors.danger,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setDialogState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.arrowDownToLine, size: 16),
                label: Text(isSubmitting ? 'Updating DB...' : 'Receive Into DB'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMasterCatalogView() {
    final filtered = _supermarketCatalog.where((item) {
      final stock = _num(item['stock']);
      final reorder = _num(item['reorder'], 10.0);
      final isLow = stock <= reorder && stock > 0;
      final isOut = stock <= 0;

      if (_selectedFilter == 'low_stock' && !isLow) return false;
      if (_selectedFilter == 'out_of_stock' && !isOut) return false;
      if (_selectedFilter == 'in_stock' && (isLow || isOut)) return false;

      if (_selectedCategory != 'all' && item['category'] != _selectedCategory) return false;

      final q = _searchController.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      final name = _str(item['name']).toLowerCase();
      final barcode = _str(item['barcode']).toLowerCase();
      final sku = _str(item['sku']).toLowerCase();
      final barcodes = (item['barcodes'] is List)
          ? (item['barcodes'] as List).map((b) => b.toString().toLowerCase()).toList()
          : <String>[];

      return name.contains(q) ||
          barcode.contains(q) ||
          sku.contains(q) ||
          barcodes.any((b) => b.contains(q));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Bar & Search
        Row(
          children: [
            Expanded(
              flex: 4,
              child: TextField(
                controller: _searchController,
                focusNode: _barcodeFocusNode,
                onChanged: (_) => setState(() {}),
                onSubmitted: _handleInventoryBarcodeSubmit,
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary(context)),
                decoration: InputDecoration(
                  hintText: 'Scan Barcode or search product name / SKU...',
                  prefixIcon: const Icon(LucideIcons.scanBarcode, color: AppColors.primary, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
            const SizedBox(width: 12),

            DropdownButton<String>(
              value: _supermarketCatalog.any((p) => p['category'] == _selectedCategory) ? _selectedCategory : 'all',
              dropdownColor: AppColors.card(context),
              style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13),
              items: [
                DropdownMenuItem(value: 'all', child: Text('All Categories', style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13))),
                ..._supermarketCatalog
                    .map((p) => (p['category'] ?? '').toString().trim())
                    .where((c) => c.isNotEmpty)
                    .toSet()
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: AppColors.textPrimary(context), fontSize: 13)))),
              ],
              onChanged: (val) => setState(() => _selectedCategory = val ?? 'all'),
            ),
            const SizedBox(width: 12),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: _syncCatalogFromBackend,
              icon: _isSyncingBackend
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.refreshCw, size: 16, color: AppColors.primary),
              label: const Text('Refresh Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            const SizedBox(width: 10),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: _openCsvImportDialog,
              icon: const Icon(LucideIcons.fileSpreadsheet, size: 16, color: AppColors.primary),
              label: const Text('Import CSV / Excel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ),
            const SizedBox(width: 10),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () => _openRegisterProductDialog(),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Register Master Product'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.packageOpen, size: 48, color: AppColors.textMuted(context)),
                          const SizedBox(height: 12),
                          Text('Master Product Catalog is Empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                          const SizedBox(height: 4),
                          Text('Scan barcodes or click "Register Master Product" to add items.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context))),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _openRegisterProductDialog(),
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('Register Master Product'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border(context)),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final stock = _num(item['stock']);
                        final reorder = _num(item['reorder'], 10.0);
                        final cost = _num(item['cost']);
                        final price = _num(item['price']);
                        final isOut = stock <= 0;
                        final isLow = stock <= reorder && !isOut;
                        final barcode = _str(item['barcode']);
                        final sku = _str(item['sku']);
                        final name = _str(item['name']);
                        final unit = _str(item['unit']).isNotEmpty ? _str(item['unit']) : 'PCS';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 160,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(barcode.isNotEmpty ? barcode : sku, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                                    Text(sku, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: AppColors.primary)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
                                    Text('Shelf: ${item['shelf'] ?? 'General Shelf'} • Category: ${item['category'] ?? 'General'}', style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context))),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 110,
                                child: Text(
                                  '${stock.toStringAsFixed(0)} $unit',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                    color: isOut ? AppColors.danger : (isLow ? AppColors.warning : AppColors.textPrimary(context)),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(Formatters.formatCurrency(cost), style: TextStyle(fontSize: 12, color: AppColors.textPrimary(context))),
                              ),
                              SizedBox(
                                width: 110,
                                child: Text(Formatters.formatCurrency(price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isOut
                                      ? AppColors.danger.withValues(alpha: 0.15)
                                      : (isLow ? AppColors.warning.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15)),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: isOut ? AppColors.danger : (isLow ? AppColors.warning : AppColors.success)),
                                ),
                                child: Text(
                                  isOut ? 'OUT OF STOCK' : (isLow ? 'LOW STOCK' : 'IN STOCK'),
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: isOut ? AppColors.danger : (isLow ? AppColors.warning : AppColors.success)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D9488),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                                onPressed: () => _openQuickStockInDialog(item),
                                icon: const Icon(LucideIcons.packagePlus, size: 14),
                                label: const Text('Stock In'),
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

  // ULTRA-COMPACT METRIC CARD (Reduced height and sleek padding)
  Widget _buildCompactMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? color : AppColors.border(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(child: Icon(icon, color: color, size: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                      color: AppColors.textMuted(context),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary(context)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SLEEK SIDEBAR ITEM WRAPPED IN MATERIAL
  Widget _buildSidebarItem({
    required String key,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          leading: Icon(
            icon,
            size: 16,
            color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textPrimary(context),
            ),
          ),
          onTap: () => setState(() => _selectedTab = key),
        ),
      ),
    );
  }

  Widget _buildSidebarSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
          color: AppColors.textMuted(context),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int lowStockCount = 0;
    int outOfStockCount = 0;
    double totalValuation = 0;
    for (var item in _supermarketCatalog) {
      final stock = _num(item['stock']);
      final reorder = _num(item['reorder'], 10.0);
      final cost = _num(item['cost']);
      if (stock <= 0) {
        outOfStockCount++;
      } else if (stock <= reorder) {
        lowStockCount++;
      }
      totalValuation += stock * cost;
    }

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Row(
        children: [
          // SIDEBAR (Left Navigation Panel)
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              border: Border(right: BorderSide(color: AppColors.border(context))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Sidebar Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(LucideIcons.boxes, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'STOREKEEPING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          letterSpacing: 0.8,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppColors.border(context)),

                // Categorized Navigation List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    children: [
                      _buildSidebarSectionHeader('Receiving & Transfers'),
                      _buildSidebarItem(key: 'grn', label: 'Receive Goods (GRN)', icon: LucideIcons.gitFork),
                      _buildSidebarItem(key: 'grn_history', label: 'GRN History & Register', icon: LucideIcons.receipt),
                      _buildSidebarItem(key: 'requisitions', label: 'Branch Stock Requests', icon: LucideIcons.gitPullRequest),
                      _buildSidebarItem(key: 'pos', label: 'Purchase Orders', icon: LucideIcons.fileSpreadsheet),
                      _buildSidebarItem(key: 'vendors', label: 'Local Vendors', icon: LucideIcons.truck),

                      _buildSidebarSectionHeader('Inventory'),
                      _buildSidebarItem(key: 'catalog', label: 'Master Inventory', icon: LucideIcons.package),
                      _buildSidebarItem(key: 'ledger', label: 'Inventory Ledger', icon: LucideIcons.history),

                      _buildSidebarSectionHeader('Stock Takes'),
                      _buildSidebarItem(key: 'stocktake', label: 'Store Stocktake', icon: LucideIcons.clipboardCheck),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // MAIN CONTENT AREA (Right Panel)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOP HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Storekeeping & Inventory',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'BRANCH: ${widget.branchName}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                color: AppColors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (_selectedTab != 'grn')
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () => setState(() => _selectedTab = 'grn'),
                              icon: const Icon(LucideIcons.packagePlus, size: 14),
                              label: const Text('Receive Goods (GRN)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onPressed: () async {
                              await _syncCatalogFromBackend();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Catalog synchronized with cloud server.'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(LucideIcons.refreshCw, size: 14),
                            label: const Text('Sync', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: _openCsvImportDialog,
                            icon: const Icon(LucideIcons.fileSpreadsheet, size: 14, color: AppColors.primary),
                            label: const Text('Import CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () => _openRegisterProductDialog(),
                            icon: const Icon(LucideIcons.plus, size: 14),
                            label: const Text('Register Master Product', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ULTRA-COMPACT KPI METRIC CARDS (Reduced Height)
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactMetricCard(
                          title: 'TOTAL CATALOG SKUS',
                          value: '${_supermarketCatalog.length} Products',
                          subtitle: '${_supermarketCatalog.map((p) => (p['category'] ?? '').toString().trim()).where((c) => c.isNotEmpty).toSet().length} Categories',
                          icon: LucideIcons.package,
                          color: AppColors.primary,
                          onTap: () => setState(() {
                            _selectedTab = 'catalog';
                            _selectedFilter = 'all';
                            _selectedCategory = 'all';
                          }),
                          isSelected: _selectedTab == 'catalog' && _selectedFilter == 'all' && _selectedCategory == 'all',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCompactMetricCard(
                          title: 'INVENTORY VALUATION',
                          value: Formatters.formatCurrency(totalValuation),
                          subtitle: 'Total Stock at Cost',
                          icon: LucideIcons.badgePercent,
                          color: const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCompactMetricCard(
                          title: 'LOW STOCK ALERTS',
                          value: '$lowStockCount Items',
                          subtitle: 'Below Reorder Limit',
                          icon: LucideIcons.alertTriangle,
                          color: AppColors.warning,
                          onTap: () => setState(() {
                            _selectedTab = 'catalog';
                            _selectedFilter = 'low_stock';
                          }),
                          isSelected: _selectedTab == 'catalog' && _selectedFilter == 'low_stock',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildCompactMetricCard(
                          title: 'OUT OF STOCK',
                          value: '$outOfStockCount Items',
                          subtitle: 'Needs Restock',
                          icon: LucideIcons.alertCircle,
                          color: AppColors.danger,
                          onTap: () => setState(() {
                            _selectedTab = 'catalog';
                            _selectedFilter = 'out_of_stock';
                          }),
                          isSelected: _selectedTab == 'catalog' && _selectedFilter == 'out_of_stock',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // MAIN VIEW CONTENT
                  Expanded(
                    child: _selectedTab == 'grn'
                        ? GrnReceivingView(
                            branchId: _effectiveBranchId,
                            branchName: widget.branchName,
                            organizationName: widget.organizationName,
                            catalog: _supermarketCatalog,
                            initialLoadedPo: _loadedPoForGrn,
                            onRefreshRequested: _syncCatalogFromBackend,
                            onInventoryChanged: (p) {
                              setState(() {
                                final idx = _supermarketCatalog.indexWhere((i) => i['sku'] == p['sku']);
                                if (idx != -1) {
                                  _supermarketCatalog[idx] = p;
                                }
                              });
                              _persistCatalog();
                              widget.onInventoryChanged?.call(p);
                            },
                          )
                        : (_selectedTab == 'grn_history'
                            ? GrnHistoryView(
                                branchName: widget.branchName,
                                organizationName: widget.organizationName,
                              )
                            : (_selectedTab == 'requisitions'
                                ? BranchRequisitionsView(
                                    branchName: widget.branchName,
                                    organizationName: widget.organizationName,
                                    catalog: _supermarketCatalog,
                                    onInventoryChanged: (p) {
                                      setState(() {
                                        final idx = _supermarketCatalog.indexWhere((i) => i['sku'] == p['sku']);
                                        if (idx != -1) {
                                          _supermarketCatalog[idx] = p;
                                        }
                                      });
                                      _persistCatalog();
                                      widget.onInventoryChanged?.call(p);
                                    },
                                  )
                                : (_selectedTab == 'pos'
                                    ? PurchaseOrdersView(
                                        branchName: widget.branchName,
                                        organizationName: widget.organizationName,
                                        catalog: _supermarketCatalog,
                                        onLoadPoIntoGrn: (po) {
                                          setState(() {
                                            _loadedPoForGrn = po;
                                            _selectedTab = 'grn';
                                          });
                                        },
                                      )
                                    : (_selectedTab == 'vendors'
                                        ? SuppliersView(branchName: widget.branchName)
                                        : (_selectedTab == 'stocktake'
                                            ? StocktakeView(
                                                branchId: _effectiveBranchId,
                                                branchName: widget.branchName,
                                                organizationName: widget.organizationName,
                                                catalog: _supermarketCatalog,
                                                onRefreshRequested: _syncCatalogFromBackend,
                                                onInventoryChanged: (p) {
                                                  setState(() {
                                                    final idx = _supermarketCatalog.indexWhere((i) => (p['sku'] != null && i['sku'] == p['sku']) || (p['id'] != null && i['id'] == p['id']));
                                                    if (idx != -1) {
                                                      _supermarketCatalog[idx] = p;
                                                    }
                                                  });
                                                  _persistCatalog();
                                                  widget.onInventoryChanged?.call(p);
                                                },
                                              )
                                            : (_selectedTab == 'ledger'
                                                ? InventoryLedgerView(
                                                    branchId: _effectiveBranchId,
                                                    branchName: widget.branchName,
                                                    catalog: _supermarketCatalog,
                                                    onInventoryChanged: (p) {
                                                      setState(() {
                                                        final idx = _supermarketCatalog.indexWhere((i) => (p['sku'] != null && i['sku'] == p['sku']) || (p['id'] != null && i['id'] == p['id']));
                                                        if (idx != -1) {
                                                          _supermarketCatalog[idx] = p;
                                                        }
                                                      });
                                                      _persistCatalog();
                                                      widget.onInventoryChanged?.call(p);
                                                    },
                                                  )
                                                : _buildMasterCatalogView())))))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
