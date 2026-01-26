/// Photo Management Widgets
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/construction_photo_model.dart';

class PhotoGridView extends StatelessWidget {
  final List<ConstructionPhoto> photos;
  final Function(ConstructionPhoto)? onPhotoTap;

  const PhotoGridView({super.key, required this.photos, this.onPhotoTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return GestureDetector(
          onTap: () => onPhotoTap?.call(photo),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: photo.category.color.withOpacity(0.5)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Container(
                    color: photo.category.color.withOpacity(0.2),
                    child: Icon(photo.category.icon, color: photo.category.color, size: 32),
                  ),
                ),
                Positioned(
                  bottom: 4, left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: photo.beforeAfterType.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(photo.beforeAfterType.label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PhotoUploadCard extends StatelessWidget {
  final VoidCallback onUpload;

  const PhotoUploadCard({super.key, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpload,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2, strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: const Column(
          children: [
            Icon(Icons.add_a_photo, color: AppColors.primary, size: 48),
            SizedBox(height: 12),
            Text('写真を追加', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class CategoryFilterChips extends StatelessWidget {
  final PhotoCategory? selected;
  final Function(PhotoCategory?) onSelected;

  const CategoryFilterChips({super.key, this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('すべて'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...PhotoCategory.values.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat.label),
              selected: selected == cat,
              selectedColor: cat.color.withOpacity(0.3),
              onSelected: (_) => onSelected(cat),
            ),
          )),
        ],
      ),
    );
  }
}
