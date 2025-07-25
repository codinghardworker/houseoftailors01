import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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

class PostDeliveryScreenComponent extends StatelessWidget {
  final Service service;
  final Function() onNext;
  final Subservice? subservice;
  final Map<String, dynamic>? userSelections;

  const PostDeliveryScreenComponent({
    Key? key,
    required this.service,
    required this.onNext,
    this.subservice,
    this.userSelections,
  }) : super(key: key);

  String _getShopAddress(ShopConfigProvider shopConfig) {
    return shopConfig.formattedShopAddress;
  }

  String _getShopName(ShopConfigProvider shopConfig) {
    return shopConfig.shopName.isNotEmpty ? shopConfig.shopName : 'House of Tailors';
  }

  String _getGoogleMapsUrl(ShopConfigProvider shopConfig) {
    // For now, return a basic Google Maps search URL
    final address = _getShopAddress(shopConfig).replaceAll('\n', ', ');
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
  }

  void _copyAddress(BuildContext context, ShopConfigProvider shopConfig) {
    Clipboard.setData(ClipboardData(text: _getShopAddress(shopConfig)));
    _showCustomToast(context, 'Address copied to clipboard successfully!');
  }

  void _openMaps(BuildContext context, ShopConfigProvider shopConfig) async {
    final url = _getGoogleMapsUrl(shopConfig);
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _showCustomToast(context, 'Opening maps...');
    } else {
      _showCustomToast(context, 'Could not open maps. Please try again.', isError: true);
    }
  }

  Widget _buildPriceHeader() {
    return SubtotalComponent(
      service: service,
      subservice: subservice,
      userSelections: userSelections,
    );
  }

  Widget _buildShopAddress(BuildContext context, ShopConfigProvider shopConfig) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: TailorService.luxuryGold.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: TailorService.luxuryGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Send your items to:',
                  style: TextStyle(
                    color: TailorService.luxuryGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final shopConfig = Provider.of<ShopConfigProvider>(context, listen: false);
                  await shopConfig.refreshConfig();
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
          const SizedBox(height: 12),
          Text(
            _getShopAddress(shopConfig),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.copy,
                  label: 'Copy Address',
                  onTap: () => _copyAddress(context, shopConfig),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.map,
                  label: 'Open Maps',
                  onTap: () => _openMaps(context, shopConfig),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: TailorService.luxuryGold.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: TailorService.luxuryGold,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: TailorService.luxuryGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomToast(BuildContext context, String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
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

    overlay.insert(overlayEntry);

    // Auto remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry?.remove();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<ShopConfigProvider>(
      builder: (context, shopConfig, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPriceHeader(),
            const SizedBox(height: Dimensions.smallSpacing),
            SectionHeaderComponent(
              title: "Post delivery details",
              goldenText: "",
              subtitle: "Send your items to our shop using the address below.",
              titleFontSize: 18.0,
              subtitleFontSize: 12.0,
              goldenColor: TailorService.luxuryGold,
            ),
            const SizedBox(height: 12.0),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShopAddress(context, shopConfig),
                      const SizedBox(height: 24.0),
                      
                      // Continue Button
                      ActionButtonComponent(
                        title: 'Continue',
                        icon: Icons.arrow_forward,
                        onPressed: () => onNext(),
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