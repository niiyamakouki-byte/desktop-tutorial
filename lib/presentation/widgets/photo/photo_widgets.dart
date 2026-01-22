/// Construction Photo Widgets
/// 工事写真ウィジェット

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/construction_photo_model.dart';

/// Photo Grid View
class PhotoGridView extends StatelessWidget {
  final List<ConstructionPhoto> photos;
  final Function(ConstructionPhoto)? onPhotoTap;
  final int crossAxisCount;

  const PhotoGridView({
    super.key,
    required this.photos,
    this.onPhotoTap,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('写真がありません', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return PhotoThumbnailCard(
          photo: photos[index],
          onTap: () => onPhotoTap?.call(photos[index]),
        );
      },
    );
  }
}

/// Photo Thumbnail Card
class PhotoThumbnailCard extends StatelessWidget {
  final ConstructionPhoto photo;
  final VoidCallback? onTap;

  const PhotoThumbnailCard({
    super.key,
    required this.photo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Placeholder image
              Container(
                color: photo.category.color.withOpacity(0.2),
                child: Center(
                  child: Icon(
                    photo.category.icon,
                    size: 32,
                    color: photo.category.color,
                  ),
                ),
              ),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: photo.beforeAfterType.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              photo.beforeAfterType.label,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (photo.isApproved)
                            const Icon(Icons.verified, size: 14, color: Colors.green),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        photo.category.label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        photo.dateDisplay,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.8),
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

/// Before/After Comparison Widget
class BeforeAfterComparisonWidget extends StatelessWidget {
  final BeforeAfterPair pair;
  final VoidCallback? onTap;

  const BeforeAfterComparisonWidget({
    super.key,
    required this.pair,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: pair.beforePhoto.category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      pair.beforePhoto.category.icon,
                      color: pair.beforePhoto.category.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pair.taskName ?? pair.beforePhoto.category.label,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${pair.beforePhoto.location ?? ''} ${pair.beforePhoto.floor ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.compare_arrows, color: AppColors.primary),
                ],
              ),
            ),

            // Before/After images
            SizedBox(
              height: 150,
              child: Row(
                children: [
                  Expanded(child: _buildPhotoSection(pair.beforePhoto, '施工前')),
                  Container(width: 2, color: AppColors.divider),
                  Expanded(child: _buildPhotoSection(pair.afterPhoto, '施工後')),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '完了: ${_formatDate(pair.completedDate)}',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Icon(Icons.person_outline, size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    pair.afterPhoto.photographerName,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(ConstructionPhoto photo, String label) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: photo.category.color.withOpacity(0.15),
          child: Center(
            child: Icon(photo.category.icon, size: 40, color: photo.category.color.withOpacity(0.5)),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: photo.beforeAfterType.color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

/// Category Filter Chips
class CategoryFilterChips extends StatelessWidget {
  final Set<PhotoCategory> selectedCategories;
  final Function(PhotoCategory, bool) onCategoryToggle;
  final VoidCallback? onClearAll;

  const CategoryFilterChips({
    super.key,
    required this.selectedCategories,
    required this.onCategoryToggle,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (selectedCategories.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.clear, size: 16),
                label: const Text('クリア'),
                onPressed: onClearAll,
              ),
            ),
          ...PhotoCategory.values.map((category) {
            final isSelected = selectedCategories.contains(category);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(category.icon, size: 16, color: isSelected ? Colors.white : category.color),
                label: Text(category.label),
                selected: isSelected,
                selectedColor: category.color,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                ),
                onSelected: (selected) => onCategoryToggle(category, selected),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Photo Upload Button
class PhotoUploadButton extends StatelessWidget {
  final VoidCallback? onTap;

  const PhotoUploadButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      icon: const Icon(Icons.add_a_photo),
      label: const Text('写真を追加'),
      backgroundColor: AppColors.primary,
    );
  }
}

/// Photo Stats Card
class PhotoStatsCard extends StatelessWidget {
  final Map<PhotoCategory, int> stats;
  final int totalPhotos;

  const PhotoStatsCard({
    super.key,
    required this.stats,
    required this.totalPhotos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('写真統計', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('合計: $totalPhotos枚', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stats.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: e.key.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: e.key.color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.key.icon, size: 14, color: e.key.color),
                    const SizedBox(width: 6),
                    Text(
                      '${e.key.label}: ${e.value}',
                      style: TextStyle(fontSize: 12, color: e.key.color, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
