import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Data class defining a crop with its visual representation.
class CropItem {
  final String id;       // lowercase English key used by the API (e.g. 'wheat')
  final String nameEn;   // English label
  final String nameHi;   // Hindi label
  final String emoji;    // Emoji icon used as image placeholder
  final Color bgColor;   // Background color for the circular container

  const CropItem({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.emoji,
    required this.bgColor,
  });
}

/// Complete crop catalog with visual properties.
class CropCatalog {
  CropCatalog._();

  static const List<CropItem> allCrops = [
    CropItem(id: 'wheat', nameEn: 'Wheat', nameHi: 'गेहूं', emoji: '🌾', bgColor: Color(0xFFFFF8E1)),
    CropItem(id: 'rice', nameEn: 'Rice', nameHi: 'धान', emoji: '🍚', bgColor: Color(0xFFF1F8E9)),
    CropItem(id: 'cotton', nameEn: 'Cotton', nameHi: 'कपास', emoji: '☁️', bgColor: Color(0xFFF3E5F5)),
    CropItem(id: 'tomato', nameEn: 'Tomato', nameHi: 'टमाटर', emoji: '🍅', bgColor: Color(0xFFFFEBEE)),
    CropItem(id: 'potato', nameEn: 'Potato', nameHi: 'आलू', emoji: '🥔', bgColor: Color(0xFFFFF3E0)),
    CropItem(id: 'onion', nameEn: 'Onion', nameHi: 'प्याज', emoji: '🧅', bgColor: Color(0xFFFCE4EC)),
    CropItem(id: 'mustard', nameEn: 'Mustard', nameHi: 'सरसों', emoji: '🌻', bgColor: Color(0xFFFFF9C4)),
    CropItem(id: 'sugarcane', nameEn: 'Sugarcane', nameHi: 'गन्ना', emoji: '🎋', bgColor: Color(0xFFE8F5E9)),
    CropItem(id: 'maize', nameEn: 'Maize', nameHi: 'मक्का', emoji: '🌽', bgColor: Color(0xFFFFF8E1)),
    CropItem(id: 'soybean', nameEn: 'Soybean', nameHi: 'सोयाबीन', emoji: '🫘', bgColor: Color(0xFFE8F5E9)),
    CropItem(id: 'chilli', nameEn: 'Chilli', nameHi: 'मिर्च', emoji: '🌶️', bgColor: Color(0xFFFFCDD2)),
    CropItem(id: 'brinjal', nameEn: 'Brinjal', nameHi: 'बैंगन', emoji: '🍆', bgColor: Color(0xFFE8EAF6)),
    CropItem(id: 'banana', nameEn: 'Banana', nameHi: 'केला', emoji: '🍌', bgColor: Color(0xFFFFF9C4)),
    CropItem(id: 'mango', nameEn: 'Mango', nameHi: 'आम', emoji: '🥭', bgColor: Color(0xFFFFF3E0)),
    CropItem(id: 'watermelon', nameEn: 'Watermelon', nameHi: 'तरबूज', emoji: '🍉', bgColor: Color(0xFFFFEBEE)),
    CropItem(id: 'cucumber', nameEn: 'Cucumber', nameHi: 'खीरा', emoji: '🥒', bgColor: Color(0xFFE8F5E9)),
    CropItem(id: 'bitter gourd', nameEn: 'Bitter Gourd', nameHi: 'करेला', emoji: '🌿', bgColor: Color(0xFFC8E6C9)),
    CropItem(id: 'moong', nameEn: 'Moong', nameHi: 'मूंग', emoji: '🫛', bgColor: Color(0xFFF1F8E9)),
    CropItem(id: 'guar', nameEn: 'Guar', nameHi: 'ग्वार', emoji: '🌱', bgColor: Color(0xFFE0F2F1)),
    CropItem(id: 'cabbage', nameEn: 'Cabbage', nameHi: 'पत्ता गोभी', emoji: '🥬', bgColor: Color(0xFFE8F5E9)),
    CropItem(id: 'cauliflower', nameEn: 'Cauliflower', nameHi: 'फूल गोभी', emoji: '🥦', bgColor: Color(0xFFF1F8E9)),
    CropItem(id: 'carrot', nameEn: 'Carrot', nameHi: 'गाजर', emoji: '🥕', bgColor: Color(0xFFFFF3E0)),
    CropItem(id: 'pea', nameEn: 'Pea', nameHi: 'मटर', emoji: '🟢', bgColor: Color(0xFFE8F5E9)),
    CropItem(id: 'groundnut', nameEn: 'Groundnut', nameHi: 'मूंगफली', emoji: '🥜', bgColor: Color(0xFFEFEBE9)),
    CropItem(id: 'bajra', nameEn: 'Bajra', nameHi: 'बाजरा', emoji: '🌿', bgColor: Color(0xFFFFF8E1)),
    CropItem(id: 'jowar', nameEn: 'Jowar', nameHi: 'ज्वार', emoji: '🌾', bgColor: Color(0xFFF5F5F5)),
    CropItem(id: 'apple', nameEn: 'Apple', nameHi: 'सेब', emoji: '🍎', bgColor: Color(0xFFFFCDD2)),
    CropItem(id: 'guava', nameEn: 'Guava', nameHi: 'अमरूद', emoji: '🍈', bgColor: Color(0xFFC8E6C9)),
    CropItem(id: 'papaya', nameEn: 'Papaya', nameHi: 'पपीता', emoji: '🥭', bgColor: Color(0xFFFFF3E0)),
    CropItem(id: 'lemon', nameEn: 'Lemon', nameHi: 'नींबू', emoji: '🍋', bgColor: Color(0xFFFFF9C4)),
  ];

  /// Lookup crop by id (case insensitive).
  static CropItem? getById(String id) {
    final lower = id.toLowerCase();
    try {
      return allCrops.firstWhere((c) => c.id == lower);
    } catch (_) {
      return null;
    }
  }
}

/// Opens a full-screen bottom sheet for crop selection.
///
/// [multiSelect]: if true, allows multi-select (returns List<String>). 
///                if false, returns a single String on tap.
/// [maxSelection]: max crops user can select (only for multiSelect).
/// [initialSelected]: pre-selected crop ids.
/// [isHindi]: whether to show Hindi labels.
///
/// Returns: List<String> of selected crop ids (for multi), or null if cancelled.
Future<List<String>?> showCropPickerSheet({
  required BuildContext context,
  required bool isHindi,
  bool multiSelect = false,
  int maxSelection = 8,
  List<String> initialSelected = const [],
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CropPickerBody(
      isHindi: isHindi,
      multiSelect: multiSelect,
      maxSelection: maxSelection,
      initialSelected: initialSelected,
    ),
  );
}

class _CropPickerBody extends StatefulWidget {
  const _CropPickerBody({
    required this.isHindi,
    required this.multiSelect,
    required this.maxSelection,
    required this.initialSelected,
  });

  final bool isHindi;
  final bool multiSelect;
  final int maxSelection;
  final List<String> initialSelected;

  @override
  State<_CropPickerBody> createState() => _CropPickerBodyState();
}

class _CropPickerBodyState extends State<_CropPickerBody> {
  late Set<String> _selected;
  String _searchQuery = '';
  final List<String> _customCrops = []; // user-typed crop names

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelected);
  }

  List<CropItem> get _filteredCrops {
    if (_searchQuery.isEmpty) return CropCatalog.allCrops;
    final q = _searchQuery.toLowerCase();
    return CropCatalog.allCrops.where((c) {
      return c.nameEn.toLowerCase().contains(q) ||
          c.nameHi.contains(q) ||
          c.id.contains(q);
    }).toList();
  }

  void _toggleCrop(CropItem crop) {
    setState(() {
      if (_selected.contains(crop.id)) {
        _selected.remove(crop.id);
      } else {
        if (!widget.multiSelect) {
          // Single select mode — return immediately
          Navigator.pop(context, [crop.id]);
          return;
        }
        if (_selected.length < widget.maxSelection) {
          _selected.add(crop.id);
        }
      }
    });
  }

  void _addCustomCrop() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.eco_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              widget.isHindi ? 'फसल का नाम लिखें' : 'Enter Crop Name',
              style: AppTextStyles.headline3,
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: widget.isHindi ? 'जैसे: पपीता, अमरूद...' : 'e.g. Papaya, Guava...',
            hintStyle: AppTextStyles.caption,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            prefixIcon: const Icon(Icons.grass_rounded, color: AppColors.primary, size: 20),
          ),
          onSubmitted: (v) {
            final trimmed = v.trim();
            if (trimmed.isNotEmpty) {
              setState(() {
                _customCrops.add(trimmed);
                if (!widget.multiSelect) {
                  Navigator.pop(ctx);
                  Navigator.pop(context, [trimmed]);
                  return;
                }
                if (_selected.length < widget.maxSelection) {
                  _selected.add(trimmed);
                }
              });
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              widget.isHindi ? 'रद्द करें' : 'Cancel',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                setState(() {
                  _customCrops.add(trimmed);
                  if (!widget.multiSelect) {
                    Navigator.pop(ctx);
                    Navigator.pop(context, [trimmed]);
                    return;
                  }
                  if (_selected.length < widget.maxSelection) {
                    _selected.add(trimmed);
                  }
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(widget.isHindi ? 'जोड़ें' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 24, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isHindi ? 'फसल चुनें' : 'Select Crops',
                            style: AppTextStyles.headline2,
                          ),
                          if (widget.multiSelect)
                            Text(
                              widget.isHindi
                                  ? 'अधिकतम ${widget.maxSelection} फसलें चुनें'
                                  : 'Select up to ${widget.maxSelection} crops',
                              style: AppTextStyles.body2,
                            ),
                        ],
                      ),
                    ),
                    if (widget.multiSelect)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selected.length}/${widget.maxSelection}',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Selected preview row (only for multi-select if items selected)
              if (widget.multiSelect && _selected.isNotEmpty)
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _selected.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final cropId = _selected.elementAt(i);
                      final crop = CropCatalog.getById(cropId);
                      final emoji = crop?.emoji ?? '🌱';
                      final bgCol = crop?.bgColor ?? AppColors.surface;
                      final name = crop != null
                          ? (widget.isHindi ? crop.nameHi : crop.nameEn)
                          : cropId;
                      return Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: bgCol,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.primary, width: 2),
                                ),
                                child: Center(
                                  child: Text(emoji,
                                      style: const TextStyle(fontSize: 24)),
                                ),
                              ),
                              Positioned(
                                top: -2,
                                right: -2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selected.remove(cropId));
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText:
                        widget.isHindi ? 'फसल खोजें...' : 'Search crops...',
                    hintStyle: AppTextStyles.caption,
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textHint, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Grid
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 4, 20, bottomPadding + 80),
                  itemCount: _filteredCrops.length + 1, // +1 for 'Other' tile
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (_, index) {
                    // Last item is the "Other" / manual entry tile
                    if (index == _filteredCrops.length) {
                      return GestureDetector(
                        onTap: _addCustomCrop,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.divider, width: 1.5),
                              ),
                              child: const Center(
                                child: Icon(Icons.add_rounded,
                                    size: 32, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.isHindi ? 'अन्य' : 'Other',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    final crop = _filteredCrops[index];
                    final isSelected = _selected.contains(crop.id);

                    return GestureDetector(
                      onTap: () => _toggleCrop(crop),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: crop.bgColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.divider,
                                    width: isSelected ? 2.5 : 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(crop.emoji,
                                      style: const TextStyle(fontSize: 36)),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check_rounded,
                                        size: 15, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isHindi ? crop.nameHi : crop.nameEn,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Save button (only for multi-select)
              if (widget.multiSelect)
                Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, _selected.toList()),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        widget.isHindi ? 'सेव करें' : 'Save',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
