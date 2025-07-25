import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../repositories/item_repository.dart';

class ImageService {
  static const String _baseUrl = 'https://houseoftailors-api.payloadcms.app';
  static bool _isPreloadingStarted = false;
  
  /// Initialize early preloading during app startup
  static Future<void> initializeEarlyPreloading(BuildContext context) async {
    if (_isPreloadingStarted) return;
    _isPreloadingStarted = true;
    
    try {
      final itemRepository = ItemRepository();
      
      // Start loading categories in background
      _startBackgroundPreloading(context, itemRepository);
    } catch (e) {
      print('Failed to initialize early preloading: $e');
    }
  }

  static void _startBackgroundPreloading(BuildContext context, ItemRepository itemRepository) async {
    try {
      // Load categories
      final categories = await itemRepository.getAllCategories();
      
      // Preload category images immediately
      final categoryImageUrls = categories
          .where((category) => category.coverImage?.fullUrl != null)
          .map((category) => category.coverImage!.fullUrl!)
          .toList();
      
      if (categoryImageUrls.isNotEmpty) {
        await aggressivePreload(context, categoryImageUrls);
      }

      // Preload all items in background
      for (final category in categories) {
        _preloadCategoryItemsBackground(context, itemRepository, category.id);
      }
    } catch (e) {
      print('Background preloading error: $e');
    }
  }

  static void _preloadCategoryItemsBackground(BuildContext context, ItemRepository itemRepository, String categoryId) async {
    try {
      final items = await itemRepository.getItemsByCategory(categoryId);
      final itemImageUrls = items
          .where((item) => item.coverImage?.fullUrl != null)
          .map((item) => item.coverImage!.fullUrl!)
          .toList();
      
      if (itemImageUrls.isNotEmpty) {
        await aggressivePreload(context, itemImageUrls, batchSize: 2);
      }
    } catch (e) {
      // Silently handle background errors
      print('Background item preload error for category $categoryId: $e');
    }
  }

  /// Build a cached network image with CORS support and fast loading
  static Widget buildImage({
    required String? imageUrl,
    required IconData fallbackIcon,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Color? iconColor,
    double iconSize = 24,
    BorderRadius? borderRadius,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildFallbackIcon(
        fallbackIcon,
        iconColor: iconColor,
        iconSize: iconSize,
        width: width,
        height: height,
        borderRadius: borderRadius,
      );
    }

    final fullUrl = _getFullImageUrl(imageUrl);

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: fullUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(
          width: width,
          height: height,
          borderRadius: borderRadius,
        ),
        errorWidget: (context, url, error) => _buildFallbackIcon(
          fallbackIcon,
          iconColor: iconColor,
          iconSize: iconSize,
          width: width,
          height: height,
          borderRadius: borderRadius,
        ),
        httpHeaders: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
        },
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 800,
      ),
    );
  }

  /// Get the full image URL with proper base URL
  static String _getFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    
    if (imageUrl.startsWith('/')) {
      return '$_baseUrl$imageUrl';
    }
    
    return '$_baseUrl/$imageUrl';
  }

  /// Build a placeholder widget while loading
  static Widget _buildPlaceholder({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  /// Build a fallback icon when image fails to load
  static Widget _buildFallbackIcon(
    IconData icon, {
    Color? iconColor,
    double iconSize = 24,
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          icon,
          color: iconColor ?? Colors.grey[600],
          size: iconSize,
        ),
      ),
    );
  }

  /// Preload multiple images for faster loading
  static Future<void> preloadImages(BuildContext context, List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;
    
    try {
      // Preload images in parallel for better performance
      final futures = imageUrls.map((url) {
        final fullUrl = _getFullImageUrl(url);
        return precacheImage(
          CachedNetworkImageProvider(
            fullUrl,
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
              'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
            },
          ),
          context,
        );
      }).toList();
      
      // Wait for all images to preload with timeout
      await Future.wait(futures).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Image preloading timed out');
          return [];
        },
      );
    } catch (e) {
      print('Error preloading images: $e');
    }
  }

  /// Preload images in smaller batches to avoid overwhelming the network
  static Future<void> preloadImagesInBatches(
    BuildContext context, 
    List<String> imageUrls, {
    int batchSize = 5,
    Duration delayBetweenBatches = const Duration(milliseconds: 100),
  }) async {
    if (imageUrls.isEmpty) return;
    
    for (int i = 0; i < imageUrls.length; i += batchSize) {
      final batch = imageUrls.skip(i).take(batchSize).toList();
      await preloadImages(context, batch);
      
      // Add small delay between batches to prevent overwhelming
      if (i + batchSize < imageUrls.length) {
        await Future.delayed(delayBetweenBatches);
      }
    }
  }

  /// Clear image cache
  static Future<void> clearCache() async {
    await CachedNetworkImage.evictFromCache('');
  }

  /// Get cache size info
  static Future<Map<String, dynamic>> getCacheInfo() async {
    // This would require additional implementation with the cache manager
    return {
      'memoryCache': 'Available',
      'diskCache': 'Available',
    };
  }

  /// Aggressively preload images in the background without blocking UI
  static Future<void> aggressivePreload(
    BuildContext context, 
    List<String> imageUrls, {
    int batchSize = 3,
    Duration delayBetweenBatches = const Duration(milliseconds: 50),
  }) async {
    if (imageUrls.isEmpty) return;
    
    // Start preloading in the background without awaiting
    _backgroundPreload(context, imageUrls, batchSize, delayBetweenBatches);
  }

  static Future<void> _backgroundPreload(
    BuildContext context,
    List<String> imageUrls,
    int batchSize,
    Duration delayBetweenBatches,
  ) async {
    try {
      for (int i = 0; i < imageUrls.length; i += batchSize) {
        final batch = imageUrls.skip(i).take(batchSize).toList();
        
        // Process batch without blocking
        _preloadBatch(context, batch);
        
        // Small delay to prevent overwhelming
        if (i + batchSize < imageUrls.length) {
          await Future.delayed(delayBetweenBatches);
        }
      }
    } catch (e) {
      print('Background preload error: $e');
    }
  }

  static void _preloadBatch(BuildContext context, List<String> batch) {
    for (final url in batch) {
      try {
        final fullUrl = _getFullImageUrl(url);
        precacheImage(
          CachedNetworkImageProvider(
            fullUrl,
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
              'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
            },
          ),
          context,
        ).catchError((error) {
          // Silently handle individual image errors
          print('Failed to preload image $url: $error');
        });
      } catch (e) {
        print('Error processing image $url: $e');
      }
    }
  }
} 