import 'package:flutter/material.dart';
import '../../services/tailor_service.dart';
import '../../models/service.dart';
import '../../models/subservice.dart';
import '../section_header_component.dart';
import '../repair_option_button_component.dart';
import '../subtotal_component.dart';
import '../../services/dimensions.dart';
import 'package:intl/intl.dart';

class PickupDateScreenComponent extends StatelessWidget {
  final Service service;
  final Function(DateTime) onDateSelected;
  final Subservice? subservice;
  final Map<String, dynamic>? userSelections;

  const PickupDateScreenComponent({
    Key? key,
    required this.service,
    required this.onDateSelected,
    this.subservice,
    this.userSelections,
  }) : super(key: key);

  Widget _buildPriceHeader() {
    return SubtotalComponent(
      service: service,
      subservice: subservice,
      userSelections: userSelections,
    );
  }

  List<DateTime> _getNext7Days() {
    final List<DateTime> dates = [];
    final DateTime now = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      dates.add(DateTime(now.year, now.month, now.day + i));
    }
    
    return dates;
  }

  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('EEEE, MMM d');
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tomorrow = today.add(const Duration(days: 1));
    
    if (date.isAtSameMomentAs(today)) {
      return 'Today, ${DateFormat('MMM d').format(date)}';
    } else if (date.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow, ${DateFormat('MMM d').format(date)}';
    } else {
      return formatter.format(date);
    }
  }

  bool _isDateAvailable(DateTime date) {
    // Disable past dates and only allow next 7 days
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    return date.isAtSameMomentAs(today) || date.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> availableDates = _getNext7Days();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceHeader(),
        const SizedBox(height: Dimensions.smallSpacing),
        SectionHeaderComponent(
          title: "Select pickup day",
          goldenText: "",
          subtitle: "Choose a convenient day for us to collect your items.",
          titleFontSize: Dimensions.titleFontSize,
          subtitleFontSize: Dimensions.subtitleFontSize,
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.screenPadding),
              child: Column(
                children: [
                  for (DateTime date in availableDates) ...[
                    if (_isDateAvailable(date))
                      RepairOptionButtonComponent(
                        label: _formatDate(date),
                        price: '',
                        onTap: () => onDateSelected(date),
                        goldenColor: TailorService.luxuryGold,
                      ),
                    if (date != availableDates.last && _isDateAvailable(date))
                      const SizedBox(height: Dimensions.itemSpacing),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}