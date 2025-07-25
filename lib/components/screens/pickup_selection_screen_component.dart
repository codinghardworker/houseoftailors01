import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/tailor_service.dart';
import '../../models/service.dart';
import '../../models/subservice.dart';
import '../section_header_component.dart';
import '../action_button_component.dart';
import '../subtotal_component.dart';
import '../../services/dimensions.dart';
import '../../providers/shop_config_provider.dart';
import '../../services/shop_config_service.dart';

class PickupSelectionScreenComponent extends StatefulWidget {
  final Service service;
  final Function(DateTime, String) onPickupScheduled;
  final Subservice? subservice;
  final Map<String, dynamic>? userSelections;

  const PickupSelectionScreenComponent({
    Key? key,
    required this.service,
    required this.onPickupScheduled,
    this.subservice,
    this.userSelections,
  }) : super(key: key);

  @override
  State<PickupSelectionScreenComponent> createState() => _PickupSelectionScreenComponentState();
}

class _PickupSelectionScreenComponentState extends State<PickupSelectionScreenComponent> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  OverlayEntry? _currentToastOverlay;

  Widget _buildPriceHeader(ShopConfigProvider shopConfig) {
    // Calculate total including pickup cost from shop configuration
    Map<String, dynamic> updatedSelections = Map.from(widget.userSelections ?? {});
    updatedSelections['pickup_cost'] = shopConfig.pickupChargeInPence;
    
    return SubtotalComponent(
      service: widget.service,
      subservice: widget.subservice,
      userSelections: updatedSelections,
    );
  }

  Future<List<DateTime>> _getAvailableDates() async {
    return ShopConfigService.getAvailablePickupDates();
  }

  Future<List<String>> _getAvailableTimeSlots() async {
    final timeSlots = ShopConfigService.getAvailablePickupSlots(selectedDate: _selectedDate);
    
    // Show message if no slots available - this is now expected behavior with no fallbacks
    if (timeSlots.isEmpty && _selectedDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCustomToast(
          'No pickup slots configured for this day in the system.',
          isError: true,
        );
      });
    }
    
    return timeSlots;
  }

  int _getStartHour(String timeSlot) {
    // Extract start hour from time slot string
    final String startTime = timeSlot.split(' – ')[0];
    final List<String> parts = startTime.split(':');
    int hour = int.parse(parts[0]);
    
    // Convert to 24-hour format
    if (startTime.contains('PM') && hour != 12) {
      hour += 12;
    } else if (startTime.contains('AM') && hour == 12) {
      hour = 0;
    }
    
    return hour;
  }

  String _formatDate(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tomorrow = today.add(const Duration(days: 1));
    
    if (date.isAtSameMomentAs(today)) {
      return 'Today, ${DateFormat('MMM d').format(date)}';
    } else if (date.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow, ${DateFormat('MMM d').format(date)}';
    } else {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

  Widget _buildModernDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required String hint,
    bool isDisabled = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDisabled ? Colors.grey[600] : TailorService.luxuryGold,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: isDisabled ? () {
              if (label.contains('Time')) {
                _showCustomToast(
                  'Please select a pickup day first',
                  isError: true,
                );
              }
            } : () {
              if (items.isEmpty) {
                _showCustomToast(
                  'No slots available for the selected day',
                  isError: true,
                );
                return;
              }
              _showSelectionBottomSheet(
                context: context,
                title: label,
                items: items,
                selectedValue: value,
                onSelected: onChanged,
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDisabled ? const Color(0xFF1A1A1A) : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDisabled 
                    ? Colors.grey[700]!.withOpacity(0.3)
                    : value != null 
                      ? TailorService.luxuryGold.withOpacity(0.6)
                      : TailorService.luxuryGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      value ?? hint,
                      style: TextStyle(
                        color: isDisabled 
                          ? Colors.grey[600]
                          : value != null ? Colors.white : Colors.grey[400],
                        fontSize: 13,
                        fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: isDisabled ? Colors.grey[600] : TailorService.luxuryGold,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSelectionBottomSheet({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String? selectedValue,
    required void Function(String?) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Color(0xFF333333),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item == selectedValue;
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                    title: Text(
                      item,
                      style: TextStyle(
                        color: isSelected ? TailorService.luxuryGold : Colors.white,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: TailorService.luxuryGold,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      onSelected(item);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDropdown() {
    return FutureBuilder<List<DateTime>>(
      future: _getAvailableDates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDropdownLoading('Select Pickup Day', 'Loading available days...');
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildDropdownError('Select Pickup Day', 'No pickup days available');
        }
        
        final dates = snapshot.data!;
        final items = dates.map((date) => _formatDate(date)).toList();
        final selectedValue = _selectedDate != null ? _formatDate(_selectedDate!) : null;
        
        return _buildModernDropdown(
          label: 'Select Pickup Day',
          value: selectedValue,
          items: items,
          hint: 'Choose a day...',
          onChanged: (value) async {
            if (value != null) {
              final index = items.indexOf(value);
              setState(() {
                _selectedDate = dates[index];
                _selectedTimeSlot = null; // Reset time selection
              });
              
              // Check available slots for selected date
              final availableSlots = await _getAvailableTimeSlots();
              if (availableSlots.isNotEmpty) {
                _hideCurrentToast();
              }
              setState(() {}); // Trigger rebuild for time dropdown
            }
          },
        );
      },
    );
  }

  Widget _buildTimeDropdown() {
    final isDisabled = _selectedDate == null;
    
    if (isDisabled) {
      return _buildModernDropdown(
        label: 'Select Time Slot',
        value: null,
        items: [],
        hint: 'Select a day first...',
        isDisabled: true,
        onChanged: (_) {},
      );
    }
    
    return FutureBuilder<List<String>>(
      future: _getAvailableTimeSlots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDropdownLoading('Select Time Slot', 'Loading time slots...');
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildDropdownError('Select Time Slot', 'No time slots available');
        }
        
        final timeSlots = snapshot.data!;
        
        return _buildModernDropdown(
          label: 'Select Time Slot',
          value: _selectedTimeSlot,
          items: timeSlots,
          hint: 'Choose a time...',
          isDisabled: false,
          onChanged: (value) async {
            setState(() {
              _selectedTimeSlot = value;
              // Hide any current toast when selecting a valid time slot
              if (value != null) {
                _hideCurrentToast();
              }
            });
          },
        );
      },
    );
  }

  bool _isFormValid() {
    return _selectedDate != null && _selectedTimeSlot != null;
  }

  Widget _buildDropdownLoading(String label, String message) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: TailorService.luxuryGold,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: TailorService.luxuryGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TailorService.luxuryGold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownError(String label, String message) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[400],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.red[400],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _hideCurrentToast() {
    if (_currentToastOverlay != null) {
      _currentToastOverlay!.remove();
      _currentToastOverlay = null;
    }
  }

  void _showCustomToast(String message, {bool isError = false}) {
    // Remove any existing toast first
    _hideCurrentToast();
    
    final overlay = Overlay.of(context);

    _currentToastOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isError ? Colors.red[800] : TailorService.luxuryGold,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentToastOverlay!);

    // Auto remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_currentToastOverlay != null) {
        _currentToastOverlay!.remove();
        _currentToastOverlay = null;
      }
    });
  }

  @override
  void dispose() {
    _hideCurrentToast();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopConfigProvider>(
      builder: (context, shopConfig, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPriceHeader(shopConfig),
            const SizedBox(height: Dimensions.smallSpacing),
            SectionHeaderComponent(
              title: "Schedule pickup",
              goldenText: "",
              subtitle: "Choose a convenient day and time for us to collect your items.",
              titleFontSize: 18.0,
              subtitleFontSize: 12.0,
              goldenColor: TailorService.luxuryGold,
            ),
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: TailorService.luxuryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: TailorService.luxuryGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    color: TailorService.luxuryGold,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pickup service: £${shopConfig.pickupCharge.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: TailorService.luxuryGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final shopConfig = Provider.of<ShopConfigProvider>(context, listen: false);
                      await shopConfig.refreshConfig();
                      setState(() {}); // Refresh the UI
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: TailorService.luxuryGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: TailorService.luxuryGold,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildDateDropdown(),
                          const SizedBox(width: 12),
                          _buildTimeDropdown(),
                        ],
                      ),
                      const SizedBox(height: 24.0),
                      
                      // Continue Button
                      ActionButtonComponent(
                        title: 'Continue',
                        icon: Icons.arrow_forward,
                        onPressed: () {
                          if (_isFormValid()) {
                            widget.onPickupScheduled(_selectedDate!, _selectedTimeSlot!);
                          }
                        },
                        enabled: _isFormValid(),
                        goldenColor: TailorService.luxuryGold,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}