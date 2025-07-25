import 'package:flutter/material.dart';
import '../../services/tailor_service.dart';
import '../../models/service.dart';
import '../../models/subservice.dart';
import '../section_header_component.dart';
import '../repair_option_button_component.dart';
import '../subtotal_component.dart';
import '../../services/dimensions.dart';

class PickupTimeScreenComponent extends StatelessWidget {
  final Service service;
  final DateTime selectedDate;
  final Function(String) onTimeSelected;
  final Subservice? subservice;
  final Map<String, dynamic>? userSelections;

  const PickupTimeScreenComponent({
    Key? key,
    required this.service,
    required this.selectedDate,
    required this.onTimeSelected,
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

  List<String> _getAvailableTimeSlots() {
    final List<String> timeSlots = [
      '10:00 AM – 11:00 AM',
      '11:00 AM – 12:00 PM',
      '12:00 PM – 1:00 PM',
      '1:00 PM – 2:00 PM',
      '2:00 PM – 3:00 PM',
      '3:00 PM – 4:00 PM',
      '4:00 PM – 5:00 PM',
      '5:00 PM – 6:00 PM',
    ];

    // Filter slots based on current time if it's today
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    
    if (selectedDate.isAtSameMomentAs(today)) {
      // Filter out past time slots for today
      return timeSlots.where((slot) {
        final int startHour = _getStartHour(slot);
        return startHour > now.hour || (startHour == now.hour && now.minute < 30);
      }).toList();
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

  String _formatSelectedDate() {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime tomorrow = today.add(const Duration(days: 1));
    
    if (selectedDate.isAtSameMomentAs(today)) {
      return 'today';
    } else if (selectedDate.isAtSameMomentAs(tomorrow)) {
      return 'tomorrow';
    } else {
      return 'on ${selectedDate.day}/${selectedDate.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> availableSlots = _getAvailableTimeSlots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceHeader(),
        const SizedBox(height: Dimensions.smallSpacing),
        SectionHeaderComponent(
          title: "Select time slot",
          goldenText: "",
          subtitle: "Choose a convenient time for pickup ${_formatSelectedDate()}.",
          titleFontSize: Dimensions.titleFontSize,
          subtitleFontSize: Dimensions.subtitleFontSize,
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: availableSlots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.grey[400],
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No time slots available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please select a different date.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Dimensions.screenPadding),
                    child: Column(
                      children: [
                        for (String timeSlot in availableSlots) ...[
                          RepairOptionButtonComponent(
                            label: timeSlot,
                            price: '',
                            onTap: () => onTimeSelected(timeSlot),
                            goldenColor: TailorService.luxuryGold,
                          ),
                          if (timeSlot != availableSlots.last)
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