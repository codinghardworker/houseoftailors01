import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/app_bar_component.dart';
import '../components/bottom_navigation_component.dart';
import '../components/tab_indicator_component.dart';
import '../components/section_header_component.dart';
import '../components/back_button_component.dart';
import '../components/category_card_component.dart';
import '../components/service_option_button_component.dart';
import '../components/repair_option_button_component.dart';
import '../services/responsive_grid.dart';
import '../components/question_box_component.dart';
import '../components/price_component.dart';
import '../components/next_button_component.dart';
import '../components/option_card_component.dart';
import '../components/action_button_component.dart';
import '../components/perfect_fit_card_component.dart';
import '../components/service_flow.dart';
import '../components/alteration_service_flow.dart';
import '../components/screens/add_another_screen_component.dart';
import '../services/tailor_service.dart';
import '../repositories/item_repository.dart';
import '../models/item_category.dart';
import '../models/item.dart';
import '../models/service.dart';
import '../services/image_service.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/cart_provider.dart' as cart;
import '../services/dimensions.dart';
import '../components/custom_toast.dart';

class TailorScreen extends StatefulWidget {
  const TailorScreen({super.key});

  @override
  State<TailorScreen> createState() => _TailorScreenState();
}

class _TailorScreenState extends State<TailorScreen> with TickerProviderStateMixin {
  // Screen state management
  int _currentScreenIndex = 0;
  int _activeTabIndex = 0;
  
  // Animation controllers
  late AnimationController _scaleAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  // Data state
  String? _pressedCard;
  String? _selectedCategory;
  String? _selectedItem;
  String? _description;
  String? _selectedService;
  String? _selectedRepair;
  String? _repairPrice;
  String? _repairLocation;
  String? _notes;
  
  // Service flow state
  String? _selectedOption;
  String? _selectedZipOption;
  String? _zipPrice;
  String? _selectedFitMethod;
  
  // Mend rips/holes flow state
  String? _mendRipsQuantity;
  String? _mendRipsQuantityPrice;
  String? _mendRipsSize;
  String? _mendRipsSizePrice;
  String? _mendRipsMethod;
  String? _mendRipsMethodPrice;
  String? _mendRipsColor;
  
  // Replace ribbing flow state
  String? _replaceRibbingOption;
  String? _replaceRibbingPrice;
  String? _replaceRibbingRequirements;
  
  // Alteration flow state
  String? _selectedAlteration;
  String? _alterationPrice;
  
  // Core controllers and focus nodes
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();
  final TextEditingController _matchingItemController = TextEditingController();
  final TextEditingController _measurementsController = TextEditingController();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();

  // Repository
  final ItemRepository _itemRepository = ItemRepository();

  // API Data
  List<ItemCategory> _categories = [];
  List<Item> _items = [];
  bool _isLoadingCategories = true;
  bool _isLoadingItems = false;
  String? _categoryError;
  String? _itemError;

  // Selected data from API
  ItemCategory? _selectedCategoryModel;
  Item? _selectedItemModel;

  // Add new state variables for services
  List<Service> _services = [];
  bool _isLoadingServices = false;
  String? _serviceError;

  // New state variable for fitting selection
  String? _selectedFittingType;
  
  // Navigation source tracking
  bool _fromAddMoreServices = false;
  
  // Alteration flow state variables
  String? _matchingItemDescription;
  String? _measurements;
  String? _selectedFittingMethod;
  String? _fittingNotes;
  String? _alterationInstructions;

  @override
  void initState() {
    super.initState();
    
    // Set current screen when entering TailorScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavigationProvider>(context, listen: false).setCurrentScreen('Tailor');
      
      // Handle navigation arguments from basket screen
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments is Map<String, dynamic>) {
        // Handle index-based navigation
        if (arguments['index'] != null) {
          setState(() {
            _currentScreenIndex = arguments['index'] as int;
            _activeTabIndex = arguments['index'] as int;
            // Check if coming from add more services, reset otherwise
            _fromAddMoreServices = arguments['fromAddMoreServices'] == true;
          });
        }
        
        // Handle legacy navigation for add_more_services
        if (arguments['action'] == 'add_more_services') {
          _handleBasketNavigation(arguments);
        }
        
        // Handle new navigation with category, item, and description
        if (arguments['categoryId'] != null && arguments['itemId'] != null) {
          // Check if coming from basket add more services
          setState(() {
            _fromAddMoreServices = arguments['fromAddMoreServices'] == true;
          });
          _handleBasketNavigationWithData(arguments);
        }
      }
    });
    
    _initializeAnimations();
    _loadCategories();
    // Early preloading is now handled in splash screen
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final categories = await _itemRepository.getAllCategories();
      
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _categoryError = 'Failed to load categories: ${e.toString()}';
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _preloadAllCriticalImages() async {
    // This is now handled by early preloading in splash screen
    // Keep method for backwards compatibility but make it minimal
    return;
  }

  Future<void> _preloadCategoryItems(ItemCategory category) async {
    // This is now handled by early preloading in splash screen
    // Keep method for backwards compatibility but make it minimal
    return;
  }

  Future<void> _preloadCriticalImages() async {
    // This method is now called from _preloadAllCriticalImages
    // Keep it for backwards compatibility but make it empty
    return;
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: TailorService.fadeAnimationDuration,
      vsync: this,
    );
    _scaleAnimationController = AnimationController(
      duration: TailorService.cardAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimationController.forward();
  }

  Future<void> _loadItemsForCategory(String categoryId) async {
    if (_isLoadingItems) return;

    setState(() {
      _isLoadingItems = true;
      _itemError = null;
    });

    try {
      final items = await _itemRepository.getItemsByCategory(categoryId);
      
      if (mounted) {
      setState(() {
        _items = items;
        _isLoadingItems = false;
      });
      }
    } catch (e) {
      if (mounted) {
      setState(() {
        _itemError = 'Failed to load items: ${e.toString()}';
        _isLoadingItems = false;
      });
      }
    }
  }

  // Add new method to load services
  Future<void> _loadServicesForItem(String itemId) async {
    setState(() {
      _isLoadingServices = true;
      _serviceError = null;
    });

    try {
      final services = await _itemRepository.getServicesForItem(itemId);
      
      if (mounted) {
        setState(() {
          _services = services;
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serviceError = 'Failed to load services: ${e.toString()}';
          _isLoadingServices = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scaleAnimationController.dispose();
    _fadeAnimationController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _colorController.dispose();
    _requirementsController.dispose();
    _matchingItemController.dispose();
    _measurementsController.dispose();
    _descriptionFocusNode.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  // Navigation methods
  void _navigateToScreen(int index) {
    setState(() {
      _currentScreenIndex = index;
      _activeTabIndex = index;
    });
  }

  void _handleBack() {
    switch (_currentScreenIndex) {
      case 1: // Item selection -> Category selection
        setState(() {
          _currentScreenIndex = 0;
          _activeTabIndex = 0; // Tab 1: Item Selection
          // Keep _selectedCategory and _selectedCategoryModel
          // Keep _items to preserve subcategories
        });
        break;
        
      case 2: // Product description -> Item selection
        setState(() {
          _currentScreenIndex = 1;
          _activeTabIndex = 0; // Tab 1: Item Selection
          _selectedItem = null;
          _description = null;
          _descriptionController.clear();
          
          // Ensure items are still loaded
          if (_selectedCategoryModel != null && _items.isEmpty) {
            _loadItemsForCategory(_selectedCategoryModel!.id);
          }
        });
        break;
        
      case 3: // Service selection -> Product description
        setState(() {
          _currentScreenIndex = 2;
          _activeTabIndex = 0; // Tab 1: Item Selection
          _selectedService = null;
          // Reset add more services flag when navigating back normally
          _fromAddMoreServices = false;
          
          // Ensure items are still loaded
          if (_selectedCategoryModel != null && _items.isEmpty) {
            _loadItemsForCategory(_selectedCategoryModel!.id);
          }
        });
        break;
        
      case 4: // Repair selection -> Service selection
        setState(() {
          _currentScreenIndex = 3;
          _activeTabIndex = 1; // Tab 2: Service & Details
          _selectedRepair = null;
          _repairPrice = null;
          
          // Clear any repair-specific state
          _selectedOption = null;
          _selectedZipOption = null;
          _zipPrice = null;
          _mendRipsQuantity = null;
          _mendRipsQuantityPrice = null;
          _mendRipsSize = null;
          _mendRipsSizePrice = null;
          _mendRipsMethod = null;
          _mendRipsMethodPrice = null;
          _mendRipsColor = null;
          _replaceRibbingOption = null;
          _replaceRibbingPrice = null;
          _replaceRibbingRequirements = null;
        });
        break;
        
      case 5: // Location input -> Repair selection
        setState(() {
          _currentScreenIndex = 4;
          _activeTabIndex = 1; // Tab 2: Service & Details
          _repairLocation = null;
          _locationController.clear();
          
          // Ensure repair services are loaded
          if (_selectedItemModel != null) {
            _loadServicesForItem(_selectedItemModel!.id);
          }
        });
        break;
        
      case 8: // Notes -> Previous screen based on service type and flow
        // Notes handled by ServiceFlow for all repairs now
        if (_selectedService == 'Repaired') {
          // All repairs go through ServiceFlow screens before notes
          // ServiceFlow handles the back navigation
          // Don't change screen here, let ServiceFlow manage it
          return;
        } else if (_selectedService == 'Altered') {
          // Alterations go through ServiceFlow screens before notes
          // Let ServiceFlow handle the back navigation
          return;
        }
        break;
        
      // All other screens (6-19 except 8) are now handled by ServiceFlow and AlterationServiceFlow
      // Don't add explicit cases for them here
      default:
        // For any screen handled by ServiceFlow, don't navigate back here
        // ServiceFlow will handle its own back navigation
        break;
    }
  }

  void _handleAppBarBack(BuildContext context) {
    // Only handle navigation back to home/previous screen
    final navigationProvider = Provider.of<NavigationProvider>(context, listen: false);
    
    // Save any unsaved data if needed
    _saveCurrentState();
    
    // Navigate back to home
    navigationProvider.handleNavigation(context, 'Home');
  }

  void _saveCurrentState() {
    // Save any text input from current screen
    switch (_currentScreenIndex) {
      case 2: // Product description
        _description = _descriptionController.text;
        break;
      case 5: // Location
        _repairLocation = _locationController.text;
        break;
      case 8: // Notes
        _notes = _notesController.text;
        break;
      case 13: // Color
        _mendRipsColor = _colorController.text;
        break;
      case 15: // Ribbing requirements
        _replaceRibbingRequirements = _requirementsController.text;
        break;
      case 17: // Matching item description
        _matchingItemDescription = _matchingItemController.text;
        break;
      case 18: // Measurements
        _measurements = _measurementsController.text;
        break;
      case 19: // Alteration instructions
        _alterationInstructions = _requirementsController.text;
        break;
    }
  }

  // Category selection handlers
  void _onCategoryCardTapDown(String categoryName) {
    setState(() => _pressedCard = categoryName);
    _scaleAnimationController.forward();
  }

  void _onCategoryCardTapUp(String categoryName) {
    // Find the category model
    final categoryModel = _categories.firstWhere(
      (cat) => cat.name == categoryName,
      orElse: () => _categories.first,
    );
    
    setState(() {
      _selectedCategory = categoryName;
      _selectedCategoryModel = categoryModel;
      _pressedCard = null;
      _currentScreenIndex = 1; // Move to item selection
    });
    
    // Load items for this category
    _loadItemsForCategory(categoryModel.id);
  }

  // Item selection handlers
  void _onItemCardTapUp(String itemName) {
    // Find the item model
    final itemModel = _items.firstWhere(
      (item) => item.name == itemName,
      orElse: () => _items.first,
    );
    
    setState(() {
      _selectedItem = itemName;
      _selectedItemModel = itemModel;
      _pressedCard = null;
      _currentScreenIndex = 2; // Move to product description
    });
  }

  // Modify the service selection method to load services for both repair and alteration
  void _onServiceSelected(String serviceType) {
    setState(() {
      _selectedService = serviceType;
      _pressedCard = null;
      
      // Load services for the selected item
      if (_selectedItemModel != null) {
        _loadServicesForItem(_selectedItemModel!.id);
      }
      
      if (serviceType == 'Altered') {
        _currentScreenIndex = 16; // Move to alteration selection
      } else if (serviceType == 'Repaired') {
        _currentScreenIndex = 4; // Move to repair selection
      }
      _activeTabIndex = 1; // Tab 2: Service & Details
    });
  }

  void _onRepairSelected(String repair, String price) {
    setState(() {
      _selectedRepair = repair;
      _repairPrice = price;
      
      // Always go to location screen after repair selection
      _currentScreenIndex = 5; // Move to location screen for all repairs
      _activeTabIndex = 1; // Tab 2: Service & Details
    });
  }

  void _onRepairLocationNext() {
    setState(() {
      // Save location data before proceeding
      _repairLocation = _locationController.text;
      
      // Route to different screens based on repair type after location
      if (_selectedRepair?.toLowerCase().contains('mend') == true || 
          _selectedRepair?.toLowerCase().contains('hole') == true || 
          _selectedRepair?.toLowerCase().contains('rip') == true) {
        _currentScreenIndex = 10; // Move to quantity screen for Mend rips/holes
      } else if (_selectedRepair?.toLowerCase().contains('ribbing') == true) {
        _currentScreenIndex = 14; // Move to ribbing options screen
      } else {
        // All other repairs (including Fix stitching) use ServiceFlow for unified price calculation
        _currentScreenIndex = 6; // Move to repair options/ServiceFlow
      }
      _activeTabIndex = 1; // Tab 2: Service & Details
    });
  }

  void _onAddToBasket() {
    // Add the service to cart before changing the screen
    _addToCart();
    
    setState(() {
      _notes = _notesController.text;
      _currentScreenIndex = 9; // Move to add another
      _activeTabIndex = 2; // Tab 3: Summary
    });
  }

  void _addToCart() {
    final cartProvider = Provider.of<cart.CartProvider>(context, listen: false);
    
    // Find the selected service
    Service? selectedService;
    try {
      selectedService = _services.firstWhere(
        (service) => service.name == _selectedRepair,
      );
    } catch (e) {
      print('Service not found: $_selectedRepair');
      CustomToast.showError(context, 'Service not found');
      return;
    }
    
    // Create service details
    final serviceDetails = cart.ServiceDetails(
      service: cart.Service(
        id: selectedService.id,
        name: selectedService.name,
        serviceType: selectedService.serviceType,
        fittingChoices: selectedService.fittingChoices,
        price: selectedService.price.toDouble(), // Already in pence
        tailorPoints: selectedService.tailorPoints,
        questions: [],
        subservices: [],
        active: selectedService.active,
        description: selectedService.description,
        deadEnd: selectedService.deadEnd,
        coverImageUrl: selectedService.coverImage?.fullUrl,
      ),
      basePrice: selectedService.price.toDouble() / 100, // Convert pence to pounds
      fittingChoice: null,
      fittingDetails: _repairLocation,
      repairLocation: _repairLocation,
      tailorNotes: _notes ?? '',
      questionAnswerModifiers: [],
      subserviceDetails: null,
      serviceType: selectedService.serviceType,
    );
    
    // Create cart item
    final itemName = _selectedItemModel?.name ?? _description ?? 'Unknown Item';
    final cartItem = cart.CartItem(
      itemCategory: cart.ItemCategory(
        id: _selectedCategoryModel?.id ?? 'unknown',
        name: _selectedCategoryModel?.name ?? 'Unknown Category',
        coverImageUrl: _selectedCategoryModel?.coverImage?.fullUrl,
      ),
      itemDescription: itemName,
      item: cart.Service(
        id: _selectedItemModel?.id ?? 'unknown',
        name: itemName,
        serviceType: selectedService.serviceType,
        fittingChoices: [],
        price: 0.0,
        tailorPoints: 0,
        questions: [],
        subservices: [],
        active: true,
        description: itemName,
        deadEnd: false,
        coverImageUrl: _selectedItemModel?.coverImage?.fullUrl,
      ),
      serviceDetails: [serviceDetails],
    );
    
    // Add to cart
    cartProvider.addItem(cartItem);
    
    // Show success toast
    final totalPrice = cartProvider.formatPrice(serviceDetails.totalPrice);
    final toastMessage = 'Selected Item: $itemName\nFinal Total: $totalPrice\nService Name: ${selectedService.name}';
    
    CustomToast.showSuccess(context, toastMessage);
  }

  void _showSuccessToast(String toastMessage) {
    CustomToast.showSuccess(context, toastMessage);
  }

  // Screen builders
  Widget _buildTabIndicator() {
    // Determine active tab based on current screen index
    int activeTabIndex = 0;
    
    if (_currentScreenIndex >= 0 && _currentScreenIndex <= 2) {
      activeTabIndex = 0; // "Category" tab for screens 0-2
    } else if (_currentScreenIndex >= 3 && _currentScreenIndex <= 5) {
      activeTabIndex = 1; // "Service" tab for screens 3-5
    }
    
    return TabIndicatorComponent(
      tabs: const [
        TabItem(title: 'Category', icon: Icons.checkroom),
        TabItem(title: 'Service', icon: Icons.build),
        TabItem(title: 'Add Another', icon: Icons.list),
      ],
      activeTabIndex: activeTabIndex,
      luxuryGold: TailorService.luxuryGold,
    );
  }

  // Screen 0: Category Selection
  Widget _buildCategoryScreen() {
    final headerContent = TailorService.getTailorScreenHeader();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: Dimensions.itemSpacing),
        SectionHeaderComponent(
          title: headerContent.title,
          goldenText: headerContent.goldenText,
          subtitle: headerContent.subtitle,
          titleFontSize: Dimensions.headerTitleFontSize,
          subtitleFontSize: Dimensions.headerSubtitleFontSize,
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: Dimensions.sectionSpacing),
        Expanded(
          child: _buildCategoryGrid(),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    if (_isLoadingCategories) {
      return const Center(
        child: CircularProgressIndicator(
          color: TailorService.luxuryGold,
        ),
      );
    }

    if (_categoryError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _categoryError!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCategories,
              style: ElevatedButton.styleFrom(
                backgroundColor: TailorService.luxuryGold,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Text(
          'No categories available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: ResponsiveGridDelegate.getDelegate(context, type: GridType.category),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildAnimatedCategoryCard(category, index);
      },
    );
  }

  Widget _buildAnimatedCategoryCard(ItemCategory category, int index) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _fadeAnimationController,
            curve: Interval(
              index * 0.1, 
              1.0, 
              curve: Curves.easeOutQuart,
            ),
          )),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _fadeAnimationController,
              curve: Interval(
                index * 0.1, 
                1.0, 
                curve: Curves.easeOut,
              ),
            )),
            child: CategoryCardComponent(
              title: category.name,
              imageUrl: category.coverImage?.fullUrl ?? '',
              fallbackIcon: Icons.checkroom,
              isPressed: _pressedCard == category.name,
              onTap: () => _onCategoryCardTapUp(category.name),
              onTapDown: () => _onCategoryCardTapDown(category.name),
              onTapUp: () => _onCategoryCardTapUp(category.name),
              onTapCancel: () => setState(() => _pressedCard = null),
              scaleAnimation: _scaleAnimation,
              goldenColor: TailorService.luxuryGold,
              fontSize: Dimensions.cardTitleFontSize,
            ),
          ),
        );
      },
    );
  }

  // Screen 1: Item Selection
  Widget _buildItemSelectionScreen() {
    final headerContent = TailorService.getItemSelectionHeader();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BackButtonComponent(
          goldenColor: TailorService.luxuryGold,
          onTap: _handleBack,
        ),
        const SizedBox(height: Dimensions.itemSpacing),
        SectionHeaderComponent(
          title: headerContent.title,
          goldenText: headerContent.goldenText,
          subtitle: headerContent.subtitle,
          titleFontSize: Dimensions.headerTitleFontSize,
          subtitleFontSize: Dimensions.headerSubtitleFontSize,
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: Dimensions.sectionSpacing),
        Expanded(
          child: _buildProductGrid(),
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    if (_isLoadingItems) {
      return const Center(
        child: CircularProgressIndicator(
          color: TailorService.luxuryGold,
        ),
      );
    }

    if (_items.isEmpty && _selectedCategoryModel != null) {
      // Try to load items if they're empty but we have a category selected
      _loadItemsForCategory(_selectedCategoryModel!.id);
      return const Center(
        child: CircularProgressIndicator(
          color: TailorService.luxuryGold,
        ),
      );
    }
    
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: ResponsiveGridDelegate.getDelegate(context, type: GridType.category),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return CategoryCardComponent(
          title: item.name,
          imageUrl: item.coverImage?.fullUrl ?? '',
          fallbackIcon: Icons.checkroom_outlined,
          isPressed: _pressedCard == item.name,
          onTap: () => _onItemCardTapUp(item.name),
          onTapDown: () => setState(() => _pressedCard = item.name),
          onTapUp: () => _onItemCardTapUp(item.name),
          onTapCancel: () => setState(() => _pressedCard = null),
          scaleAnimation: null,
          goldenColor: TailorService.luxuryGold,
          fontSize: 12,
        );
      },
    );
  }

  // Screen 2: Product Description
  Widget _buildProductDescriptionScreen() {
    final headerContent = TailorService.getProductDescriptionHeader();
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BackButtonComponent(
            goldenColor: TailorService.luxuryGold,
            onTap: _handleBack,
          ),
          const SizedBox(height: Dimensions.itemSpacing),
          SectionHeaderComponent(
            title: headerContent.title,
            goldenText: headerContent.goldenText,
            subtitle: headerContent.subtitle,
            titleFontSize: Dimensions.headerTitleFontSize,
            subtitleFontSize: Dimensions.headerSubtitleFontSize,
            goldenColor: TailorService.luxuryGold,
          ),
          const SizedBox(height: Dimensions.sectionSpacing),
          QuestionBoxComponent(
            controller: _descriptionController,
            placeholder: 'Colour, pattern, material',
            focusNode: _descriptionFocusNode,
            goldenColor: TailorService.luxuryGold,
            onChanged: (_) => setState(() {}),
          ),
          NextButtonComponent(
            onPressed: _descriptionController.text.trim().isNotEmpty
                ? _onDescriptionNext
                : null,
            enabled: _descriptionController.text.trim().isNotEmpty,
            goldenColor: TailorService.luxuryGold,
          ),
        ],
      ),
    );
  }

  // Restore original service selection screen
  Widget _buildServiceSelectionScreen() {
    final headerContent = TailorService.getServiceSelectionHeader(_selectedItem ?? '');
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Don't show back button if coming from add more services
          if (!_fromAddMoreServices) ...[
            BackButtonComponent(
              goldenColor: TailorService.luxuryGold,
              onTap: _handleBack,
            ),
          ] else ...[
            const SizedBox(height: Dimensions.itemSpacing),
          ],
          const SizedBox(height: Dimensions.itemSpacing),
          SectionHeaderComponent(
            title: headerContent.title,
            goldenText: headerContent.goldenText,
            subtitle: headerContent.subtitle,
            titleFontSize: Dimensions.headerTitleFontSize,
            subtitleFontSize: Dimensions.headerSubtitleFontSize,
            goldenColor: TailorService.luxuryGold,
          ),
          const SizedBox(height: Dimensions.sectionSpacing),
          Row(
            children: [
              Expanded(
                child: ServiceOptionButtonComponent(
                  label: 'Repaired',
                  icon: Icons.build_circle_outlined,
                  isPressed: _pressedCard == 'Repaired',
                  onTap: () => _onServiceSelected('Repaired'),
                  goldenColor: TailorService.luxuryGold,
                ),
              ),
              const SizedBox(width: Dimensions.itemSpacing),
              Expanded(
                child: ServiceOptionButtonComponent(
                  label: 'Altered',
                  icon: Icons.tune,
                  isPressed: _pressedCard == 'Altered',
                  onTap: () => _onServiceSelected('Altered'),
                  goldenColor: TailorService.luxuryGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Modify repair selection screen to show dynamic repair services
  Widget _buildRepairSelectionScreen() {
    final headerContent = TailorService.getRepairSelectionHeader(_selectedItem ?? '');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BackButtonComponent(
          goldenColor: TailorService.luxuryGold,
          onTap: _handleBack,
        ),
        const SizedBox(height: Dimensions.itemSpacing),
        SectionHeaderComponent(
          title: headerContent.title,
          goldenText: headerContent.goldenText,
          subtitle: headerContent.subtitle,
          titleFontSize: Dimensions.headerTitleFontSize,
          subtitleFontSize: Dimensions.headerSubtitleFontSize,
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: Dimensions.sectionSpacing),
        Expanded(
          child: _isLoadingServices
            ? const Center(
                child: CircularProgressIndicator(
                  color: TailorService.luxuryGold,
                ),
              )
            : _serviceError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[400],
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load repair services',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _serviceError!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedItemModel != null) {
                            _loadServicesForItem(_selectedItemModel!.id);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TailorService.luxuryGold,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _services.where((s) => s.serviceType == 'repair').isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.build_circle_outlined,
                          color: Colors.grey[400],
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No repair services available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We currently don\'t offer repair services for this item.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: ResponsiveGridDelegate.getDelegate(context, type: GridType.category),
                    itemCount: _services.where((s) => s.serviceType == 'repair').length,
      itemBuilder: (context, index) {
                      final repairServices = _services.where((s) => s.serviceType == 'repair').toList();
                      final service = repairServices[index];
                      final String imageUrl = service.coverImage?.url != null 
                        ? 'https://payload.sojo.uk${service.coverImage!.url}'
                        : '';
                      
        return CategoryCardComponent(
                        title: service.name,
                        imageUrl: imageUrl,
                        fallbackIcon: Icons.build_circle_outlined,
                        isPressed: _pressedCard == service.name,
                        onTap: () => _onRepairSelected(service.name, 'From £${(service.price / 100.0).toStringAsFixed(2)}'),
                        onTapDown: () => setState(() => _pressedCard = service.name),
                        onTapUp: () => _onRepairSelected(service.name, 'From £${(service.price / 100.0).toStringAsFixed(2)}'),
          onTapCancel: () => setState(() => _pressedCard = null),
          scaleAnimation: null,
          goldenColor: TailorService.luxuryGold,
          fontSize: 13,
                        subtitle: 'From £${(service.price / 100.0).toStringAsFixed(2)}',
          subtitleFontSize: 11,
          maxLines: 2,
          textPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          aspectRatio: 1,
          imageBoxFit: BoxFit.cover,
        );
      },
                  ),
        ),
      ],
    );
  }

  // Screen 5: Repair Location
  Widget _buildRepairLocationScreen() {
    final headerContent = HeaderContent(
      title: 'Where do you need your repair?',
      goldenText: '',
      subtitle: 'Please describe the location of your repair.',
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BackButtonComponent(
          goldenColor: TailorService.luxuryGold,
          onTap: _handleBack,
        ),
        PriceComponent(
          label: 'Your subtotal',
          price: _repairPrice?.replaceFirst('From ', '') ?? '',
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: 8.0),
        SectionHeaderComponent(
          title: headerContent.title,
          goldenText: headerContent.goldenText,
          subtitle: headerContent.subtitle,
          titleFontSize: 20,
          subtitleFontSize: 12,
          goldenColor: TailorService.luxuryGold,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuestionBoxComponent(
                  controller: _locationController,
                  placeholder: 'The location of your repair...',
                  goldenColor: TailorService.luxuryGold,
                  focusNode: _locationFocusNode,
                  onChanged: (_) => setState(() {}),
                ),
                NextButtonComponent(
                  onPressed: _locationController.text.trim().isNotEmpty
                      ? _onRepairLocationNext
                      : null,
                  enabled: _locationController.text.trim().isNotEmpty,
                  goldenColor: TailorService.luxuryGold,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Screen 8: Notes
  Widget _buildNotesScreen() {
    final headerContent = TailorService.getNotesScreenHeader();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PriceComponent(
          label: 'Your subtotal',
          price: _repairPrice?.replaceFirst('From ', '') ?? '',
          goldenColor: TailorService.luxuryGold,
        ),
        const SizedBox(height: Dimensions.itemSpacing),
        SectionHeaderComponent(
          title: headerContent.title,
          goldenText: headerContent.goldenText,
          subtitle: headerContent.subtitle,
          titleFontSize: Dimensions.titleFontSize,
          subtitleFontSize: Dimensions.subtitleFontSize,
          goldenColor: TailorService.luxuryGold,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                QuestionBoxComponent(
                  controller: _notesController,
                  placeholder: TailorService.getNotesInputPlaceholder(),
                  goldenColor: TailorService.luxuryGold,
                  maxLines: Dimensions.inputMaxLines.toInt(),
                  onChanged: (_) => setState(() {}),
                ),
                ActionButtonComponent(
                  title: 'Add to basket',
                  icon: Icons.shopping_basket,
                  onPressed: _onAddToBasket,
                  goldenColor: TailorService.luxuryGold,
                ),
                const SizedBox(height: Dimensions.itemSpacing),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Add back the description next method
  void _onDescriptionNext() {
    setState(() {
      _description = _descriptionController.text;
      _currentScreenIndex = 3; // Move to service selection
      _activeTabIndex = 1;
    });
  }


  void _handleBasketNavigationWithData(Map<String, dynamic> arguments) {
    final categoryId = arguments['categoryId'] as String?;
    final categoryName = arguments['categoryName'] as String?;
    final itemId = arguments['itemId'] as String?;
    final itemName = arguments['itemName'] as String?;
    final description = arguments['description'] as String?;
    
    if (categoryId != null && categoryName != null && itemId != null && itemName != null) {
      setState(() {
        // Set category data
        _selectedCategory = categoryName;
        _selectedCategoryModel = ItemCategory(
          id: categoryId,
          name: categoryName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          coverImage: null,
        );
        
        // Set item data
        _selectedItem = itemName;
        _selectedItemModel = Item(
          id: itemId,
          name: itemName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          coverImage: null,
          itemCategories: [_selectedCategoryModel!],
          questions: [],
          services: [],
          deadEnd: false,
          active: true,
        );
        
        // Set description
        if (description != null) {
          _description = description;
          _descriptionController.text = description;
        }
        
        // Navigate to service selection screen
        _currentScreenIndex = 3;
        _activeTabIndex = 1;
      });
      
      // Load services for the item to ensure repair services are available
      _loadServicesForItem(itemId);
    }
  }

  void _handleBasketNavigation(Map<String, dynamic> arguments) {
    final categoryId = arguments['categoryId'] as String?;
    final categoryName = arguments['categoryName'] as String?;
    final serviceName = arguments['serviceName'] as String?;
    final description = arguments['description'] as String?;
    
    if (categoryId != null && categoryName != null) {
      setState(() {
        // Set category data
        _selectedCategory = categoryName;
        _selectedCategoryModel = ItemCategory(
          id: categoryId,
          name: categoryName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          coverImage: null,
        );
        
        // Set item data
        _selectedItem = serviceName;
        _description = description;
        
        // Clear service state to allow new service selection
        _selectedService = null;
        _selectedRepair = null;
      });
      
      // Load items for this category, then find and set the item model
      _loadItemsForCategory(categoryId).then((_) {
        // After items are loaded, find the matching item model
        if (serviceName != null && _items.isNotEmpty) {
          final matchingItem = _items.firstWhere(
            (item) => item.name == serviceName,
            orElse: () => _items.first, // Fallback to first item if exact match not found
          );
          
          setState(() {
            _selectedItemModel = matchingItem;
            // Navigate to service selection screen after item model is set
            _currentScreenIndex = 3;
            _activeTabIndex = 1;
          });
        } else {
          setState(() {
            // Navigate even if no specific item found
            _currentScreenIndex = 3;
            _activeTabIndex = 1;
          });
        }
      });
    }
  }

  // Add didUpdateWidget to handle category changes
  @override
  void didUpdateWidget(TailorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If we're on the items screen and items are empty, reload them
    if (_currentScreenIndex == 1 && _items.isEmpty && _selectedCategoryModel != null) {
      _loadItemsForCategory(_selectedCategoryModel!.id);
    }
  }

  // Main build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBarComponent(
                  showBackButton: _currentScreenIndex > 0,
                  onBackPressed: () => _handleAppBarBack(context),
                ),
                if (_currentScreenIndex >= 0 && _currentScreenIndex <= 5) ...[
                  _buildTabIndicator(),
                ],
                if (_currentScreenIndex == 0) ...[
                  Expanded(child: _buildCategoryScreen()),
                ] else if (_currentScreenIndex == 1) ...[
                  Expanded(child: _buildItemSelectionScreen()),
                ] else if (_currentScreenIndex == 2) ...[
                  Expanded(child: _buildProductDescriptionScreen()),
                ] else if (_currentScreenIndex == 3) ...[
                  Expanded(child: _buildServiceSelectionScreen()),
                ] else if (_currentScreenIndex == 4) ...[
                  Expanded(child: _buildRepairSelectionScreen()),
                ] else if (_currentScreenIndex == 5) ...[
                  Expanded(child: _buildRepairLocationScreen()),
                ] else if (_selectedService == 'Altered') ...[
                  // Handle alteration flow
                  _handleAlterationFlow(),
                ] else ...[
                  // All other screens (repair flow) are handled by ServiceFlow
                  Expanded(
                    child: ServiceFlow(
                      currentScreenIndex: _currentScreenIndex,
                      selectedRepair: _selectedRepair,
                      repairPrice: _repairPrice,
                      selectedService: _selectedService,
                      services: _services,
                      isLoadingServices: _isLoadingServices,
                      serviceError: _serviceError,
                      onServiceComplete: (serviceName, price) {
                        // Service completed - let ServiceFlow handle add another screen
                      },
                      onBack: () {
                        // ServiceFlow is requesting to go back to TailorScreen-managed screens
                        if (_selectedService == 'Repaired') {
                          setState(() {
                            // All repairs now use ServiceFlow, so let ServiceFlow handle back navigation
                            // Only go back to location screen if we're not in ServiceFlow managed screens
                            _currentScreenIndex = 5; // Back to location screen
                            _activeTabIndex = 1;
                          });
                        }
                      },
                      onRepairOptionSelected: (option, price) {
                        setState(() {
                          _selectedOption = option;
                          // Always move to zip options, regardless of price
                          _currentScreenIndex = 7;
                          _activeTabIndex = 1;
                        });
                      },
                      onZipOptionSelected: (option, price) {
                        setState(() {
                          _selectedZipOption = option;
                          _zipPrice = price;
                          _currentScreenIndex = 8; // Move to notes
                          _activeTabIndex = 1;
                        });
                      },
                      onMendRipsQuantitySelected: (quantity, price) {
                        setState(() {
                          _mendRipsQuantity = quantity;
                          _mendRipsQuantityPrice = price;
                          _currentScreenIndex = 11; // Move to size screen
                          _activeTabIndex = 1; // Tab 2: Service & Details
                        });
                      },
                      onMendRipsSizeSelected: (size, price) {
                        setState(() {
                          _mendRipsSize = size;
                          _mendRipsSizePrice = price;
                          _currentScreenIndex = 12; // Move to method screen
                          _activeTabIndex = 1; // Tab 2: Service & Details
                        });
                      },
                      onMendRipsMethodSelected: (method, price) {
                        setState(() {
                          _mendRipsMethod = method;
                          _mendRipsMethodPrice = price;
                          _currentScreenIndex = 13; // Move to color screen
                          _activeTabIndex = 1; // Tab 2: Service & Details
                        });
                      },
                      onMendRipsColorNext: () {
                        setState(() {
                          _mendRipsColor = _colorController.text;
                          _currentScreenIndex = 8; // Move to notes screen
                          _activeTabIndex = 1; // Tab 2: Service & Details
                        });
                      },
                      onReplaceRibbingSelected: (option, price) {
                        setState(() {
                          _replaceRibbingOption = option;
                          _replaceRibbingPrice = price;
                          _currentScreenIndex = 15; // Move to requirements screen
                          _activeTabIndex = 1; // Tab 2: Service & Details
                        });
                      },
                      onReplaceRibbingRequirementsNext: () {
                        setState(() {
                          _replaceRibbingRequirements = _requirementsController.text;
                          _currentScreenIndex = 8; // Move to notes screen
                          _activeTabIndex = 1; // Tab 2: Service & Details
                        });
                      },
                      colorController: _colorController,
                      requirementsController: _requirementsController,
                      selectedCategory: _selectedCategoryModel,
                      selectedItem: _selectedItemModel,
                      itemDescription: _description,
                      locationInfo: _repairLocation,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationComponent(),
    );
  }

  Map<String, int> get _screenIndices => {
    'service_type': 0,
    'service_selection': 1,
    'subservice_selection': 2,
    'location': 7,
    'summary': 8,
  };

  Widget _handleAlterationFlow() {
    return Expanded(
      child: AlterationServiceFlow(
        currentScreenIndex: _currentScreenIndex,
        selectedService: _selectedService,
        services: _services,
        isLoadingServices: _isLoadingServices,
        serviceError: _serviceError,
        onServiceComplete: (serviceName, price) {
          // Service completed - let AlterationServiceFlow handle add another screen
        },
        onBack: () {
          // AlterationServiceFlow handles its own navigation internally
          // Only call this when the flow is completely done and we need to go back to TailorScreen screens
          setState(() {
            _currentScreenIndex = 3; // Back to service selection
            _activeTabIndex = 1;
          });
        },
        onAlterationSelected: (alteration, price) {
          setState(() {
            _selectedAlteration = alteration;
            _alterationPrice = price;
            _currentScreenIndex = 16; // Move to perfect fit screen
            _activeTabIndex = 1;
          });
        },

        matchingItemController: _matchingItemController,
        measurementsController: _measurementsController,
        requirementsController: _requirementsController,
        selectedCategory: _selectedCategoryModel,
        selectedItem: _selectedItemModel,
        itemDescription: _description,
        locationInfo: _repairLocation,
      ),
    );
  }
}