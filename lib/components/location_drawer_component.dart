import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/location_service.dart';
import '../services/user_location_service.dart';
import '../models/location_models.dart';

class LocationDrawerComponent extends StatefulWidget {
  final VoidCallback? onLocationSelected;
  
  const LocationDrawerComponent({
    super.key,
    this.onLocationSelected,
  });

  @override
  State<LocationDrawerComponent> createState() => _LocationDrawerComponentState();
}

class _LocationDrawerComponentState extends State<LocationDrawerComponent> {
  static const luxuryGold = Color(0xFFE8D26D);
  static const darkBackground = Color(0xFF1A1A1A);
  
  String? selectedCity;
  String? selectedArea;
  String? detectedCountry;
  String? detectedCountryCode;
  bool isLoadingCities = false;
  bool isLoadingAreas = false;
  String? errorMessage;
  
  // API data
  List<String> cities = [];
  List<String> areas = [];
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _loadCities();
    _subscribeToLocationUpdates();
  }
  
  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToLocationUpdates() {
    _locationSubscription = LocationService.subscribeToLocationUpdates().listen(
      (locationData) {
        if (mounted) {
          setState(() {
            cities = locationData.map((city) => city['name'] as String).toList();
            // If currently selected city is no longer available, reset selection
            if (selectedCity != null && !cities.contains(selectedCity)) {
              selectedCity = null;
              selectedArea = null;
              areas = [];
            }
          });
        }
      },
      onError: (error) {
        print('Error in location subscription: $error');
        // Fallback to loading cities normally
        _loadCities();
      },
    );
  }

  Future<void> _loadCities([String? countryCode]) async {
    if (isLoadingCities) return;
    
    setState(() {
      isLoadingCities = true;
      errorMessage = null;
    });

    try {
      // Use detected country code or default to GB
      final fetchedCities = await LocationService.fetchCitiesForCountry(countryCode);
      
      if (mounted) {
        setState(() {
          cities = fetchedCities;
          isLoadingCities = false;
          if (fetchedCities.isEmpty) {
            errorMessage = 'No cities available';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load cities';
          isLoadingCities = false;
        });
      }
    }
  }

  Future<void> _loadAreasForCity(String cityName) async {
    if (isLoadingAreas) return;
    
    setState(() {
      isLoadingAreas = true;
      areas = [];
      selectedArea = null;
    });

    try {
      final fetchedAreas = await LocationService.fetchAreasForCity(cityName);
      if (mounted) {
        setState(() {
          areas = fetchedAreas;
          isLoadingAreas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load areas for $cityName';
          isLoadingAreas = false;
          areas = []; // Ensure areas is empty on error
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: darkBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        border: Border.all(
          color: luxuryGold.withOpacity(0.2),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, -4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: luxuryGold.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            _buildHeader(),
            _buildContent(),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 6),
      width: 32,
      height: 3,
      decoration: BoxDecoration(
        color: luxuryGold.withOpacity(0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: luxuryGold.withOpacity(0.2),
            width: 0.8,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Choose Your Location',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              detectedCountry != null 
                  ? 'Select location in $detectedCountry'
                  : 'Select your preferred location',
              style: GoogleFonts.lato(
                fontSize: 10,
                color: luxuryGold.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLocationDropdowns(),
        ],
      ),
    );
  }


  Widget _buildLocationDropdowns() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactDropdown(
          label: 'City / Region',
          value: selectedCity,
          items: cities,
          isLoading: isLoadingCities,
          onChanged: (value) {
            setState(() {
              selectedCity = value;
              selectedArea = null; // Reset area when city changes
            });
            if (value != null) {
              _loadAreasForCity(value);
            }
          },
        ),
        const SizedBox(height: 6),
        _buildCompactDropdown(
          label: 'Area / Subregion',
          value: selectedArea,
          items: areas,
          isLoading: isLoadingAreas,
          onChanged: (value) {
            setState(() {
              selectedArea = value;
            });
          },
          enabled: selectedCity != null && !isLoadingAreas,
        ),
      ],
    );
  }

  Widget _buildCompactDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool enabled = true,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(enabled ? 0.05 : 0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(enabled ? 0.2 : 0.1),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: Colors.white.withOpacity(enabled ? 0.8 : 0.4),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: isLoading
                ? Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(luxuryGold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Loading ${label.toLowerCase()}...',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: items.contains(value) ? value : null, // Fix: Only use value if it exists in items
                      hint: Text(
                        items.isEmpty 
                            ? 'No ${label.toLowerCase()} available'
                            : 'Select ${label.toLowerCase()}',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.white.withOpacity(enabled ? 0.5 : 0.3),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      items: items.map((String item) {
                        return DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: enabled && items.isNotEmpty ? onChanged : null,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2A2A2A),
                      icon: Icon(
                        isLoading ? Icons.refresh : Icons.keyboard_arrow_down,
                        color: Colors.white.withOpacity(enabled ? 0.6 : 0.3),
                        size: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    final bool isEnabled = (selectedCity != null && selectedArea != null);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: luxuryGold.withOpacity(0.2),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: isEnabled ? _confirmLocation : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        luxuryGold,
                        luxuryGold.withOpacity(0.9),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: isEnabled ? [
                BoxShadow(
                  color: luxuryGold.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ] : null,
            ),
            child: Text(
              'Confirm Location',
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isEnabled ? darkBackground : Colors.white.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }


  void _confirmLocation() async {
    if (selectedCity != null && selectedArea != null) {
      // Close drawer first
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Clear cache before saving to ensure fresh data
      UserLocationService.clearCache();
      
      // Save location using UserLocationService
      await UserLocationService.syncLocation(selectedCity!, selectedArea!);
      
      // Show success toast after closing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location set to $selectedArea, $selectedCity',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFE8D26D),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Call callback if provided
      widget.onLocationSelected?.call();
    }
  }
}