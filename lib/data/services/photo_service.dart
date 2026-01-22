/// Photo Service for Construction Photo Management
/// 工事写真管理サービス

import 'package:flutter/foundation.dart';
import '../models/construction_photo_model.dart';

class PhotoService extends ChangeNotifier {
  final List<ConstructionPhoto> _photos = [];
  final List<BeforeAfterPair> _beforeAfterPairs = [];

  List<ConstructionPhoto> get photos => List.unmodifiable(_photos);
  List<BeforeAfterPair> get beforeAfterPairs => List.unmodifiable(_beforeAfterPairs);

  PhotoService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();

    final mockPhotos = [
      ConstructionPhoto(
        id: 'ph1',
        projectId: 'p1',
        taskId: 't1',
        imagePath: 'assets/photos/foundation_before.jpg',
        timestamp: now.subtract(const Duration(days: 30)),
        photographerId: 'w1',
        photographerName: '田中 太郎',
        category: PhotoCategory.foundation,
        beforeAfterType: BeforeAfterType.before,
        location: 'A棟 基礎部分',
        floor: '地下1階',
        notes: '基礎工事開始前の状態',
      ),
      ConstructionPhoto(
        id: 'ph2',
        projectId: 'p1',
        taskId: 't1',
        imagePath: 'assets/photos/foundation_after.jpg',
        timestamp: now.subtract(const Duration(days: 20)),
        photographerId: 'w1',
        photographerName: '田中 太郎',
        category: PhotoCategory.foundation,
        beforeAfterType: BeforeAfterType.after,
        location: 'A棟 基礎部分',
        floor: '地下1階',
        notes: '基礎コンクリート打設完了',
        isApproved: true,
      ),
      ConstructionPhoto(
        id: 'ph3',
        projectId: 'p1',
        taskId: 't2',
        imagePath: 'assets/photos/framing_before.jpg',
        timestamp: now.subtract(const Duration(days: 15)),
        photographerId: 'w4',
        photographerName: '高橋 四郎',
        category: PhotoCategory.framing,
        beforeAfterType: BeforeAfterType.before,
        location: 'A棟 1階',
        floor: '1階',
        notes: '躯体工事開始前',
      ),
      ConstructionPhoto(
        id: 'ph4',
        projectId: 'p1',
        taskId: 't2',
        imagePath: 'assets/photos/framing_during.jpg',
        timestamp: now.subtract(const Duration(days: 10)),
        photographerId: 'w4',
        photographerName: '高橋 四郎',
        category: PhotoCategory.framing,
        beforeAfterType: BeforeAfterType.during,
        location: 'A棟 1階',
        floor: '1階',
        notes: '鉄筋組立中',
      ),
      ConstructionPhoto(
        id: 'ph5',
        projectId: 'p1',
        taskId: 't3',
        imagePath: 'assets/photos/electrical_before.jpg',
        timestamp: now.subtract(const Duration(days: 8)),
        photographerId: 'w2',
        photographerName: '佐藤 次郎',
        category: PhotoCategory.electrical,
        beforeAfterType: BeforeAfterType.before,
        location: 'A棟 分電盤室',
        floor: '1階',
        notes: '電気配線工事開始前',
      ),
      ConstructionPhoto(
        id: 'ph6',
        projectId: 'p1',
        taskId: 't3',
        imagePath: 'assets/photos/electrical_after.jpg',
        timestamp: now.subtract(const Duration(days: 5)),
        photographerId: 'w2',
        photographerName: '佐藤 次郎',
        category: PhotoCategory.electrical,
        beforeAfterType: BeforeAfterType.after,
        location: 'A棟 分電盤室',
        floor: '1階',
        notes: '分電盤設置完了',
        isApproved: true,
      ),
      ConstructionPhoto(
        id: 'ph7',
        projectId: 'p1',
        taskId: 't4',
        imagePath: 'assets/photos/plumbing_before.jpg',
        timestamp: now.subtract(const Duration(days: 7)),
        photographerId: 'w3',
        photographerName: '鈴木 三郎',
        category: PhotoCategory.plumbing,
        beforeAfterType: BeforeAfterType.before,
        location: 'A棟 給排水シャフト',
        floor: '1階〜3階',
        notes: '給排水配管工事開始前',
      ),
      ConstructionPhoto(
        id: 'ph8',
        projectId: 'p1',
        taskId: 't4',
        imagePath: 'assets/photos/plumbing_after.jpg',
        timestamp: now.subtract(const Duration(days: 3)),
        photographerId: 'w3',
        photographerName: '鈴木 三郎',
        category: PhotoCategory.plumbing,
        beforeAfterType: BeforeAfterType.after,
        location: 'A棟 給排水シャフト',
        floor: '1階〜3階',
        notes: '給排水配管完了',
      ),
      ConstructionPhoto(
        id: 'ph9',
        projectId: 'p1',
        imagePath: 'assets/photos/safety_meeting.jpg',
        timestamp: now.subtract(const Duration(days: 1)),
        photographerId: 'w1',
        photographerName: '田中 太郎',
        category: PhotoCategory.safety,
        beforeAfterType: BeforeAfterType.during,
        location: '現場事務所前',
        notes: '朝礼・安全ミーティング',
      ),
      ConstructionPhoto(
        id: 'ph10',
        projectId: 'p1',
        imagePath: 'assets/photos/inspection.jpg',
        timestamp: now,
        photographerId: 'w1',
        photographerName: '田中 太郎',
        category: PhotoCategory.inspection,
        beforeAfterType: BeforeAfterType.during,
        location: 'A棟 2階',
        floor: '2階',
        notes: '中間検査実施',
        isApproved: true,
      ),
    ];

    _photos.addAll(mockPhotos);

    // Create before/after pairs
    _beforeAfterPairs.addAll([
      BeforeAfterPair(
        id: 'pair1',
        beforePhoto: _photos[0],
        afterPhoto: _photos[1],
        taskId: 't1',
        taskName: '基礎工事',
        completedDate: now.subtract(const Duration(days: 20)),
      ),
      BeforeAfterPair(
        id: 'pair2',
        beforePhoto: _photos[4],
        afterPhoto: _photos[5],
        taskId: 't3',
        taskName: '電気配線工事',
        completedDate: now.subtract(const Duration(days: 5)),
      ),
      BeforeAfterPair(
        id: 'pair3',
        beforePhoto: _photos[6],
        afterPhoto: _photos[7],
        taskId: 't4',
        taskName: '給排水配管工事',
        completedDate: now.subtract(const Duration(days: 3)),
      ),
    ]);
  }

  /// Add new photo
  void addPhoto(ConstructionPhoto photo) {
    _photos.add(photo);
    notifyListeners();
  }

  /// Get photos by category
  List<ConstructionPhoto> getPhotosByCategory(PhotoCategory category) {
    return _photos.where((p) => p.category == category).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get photos by task
  List<ConstructionPhoto> getPhotosByTask(String taskId) {
    return _photos.where((p) => p.taskId == taskId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get photos by date
  List<ConstructionPhoto> getPhotosByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return _photos.where((p) =>
      p.timestamp.isAfter(dayStart) && p.timestamp.isBefore(dayEnd)
    ).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get photos by photographer
  List<ConstructionPhoto> getPhotosByWorker(String workerId) {
    return _photos.where((p) => p.photographerId == workerId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Create before/after pair
  BeforeAfterPair? createBeforeAfterPair(String beforeId, String afterId, {String? taskId, String? taskName}) {
    final before = _photos.firstWhere((p) => p.id == beforeId, orElse: () => throw Exception('Before photo not found'));
    final after = _photos.firstWhere((p) => p.id == afterId, orElse: () => throw Exception('After photo not found'));

    final pair = BeforeAfterPair(
      id: 'pair${DateTime.now().millisecondsSinceEpoch}',
      beforePhoto: before,
      afterPhoto: after,
      taskId: taskId,
      taskName: taskName,
      completedDate: after.timestamp,
    );

    _beforeAfterPairs.add(pair);
    notifyListeners();
    return pair;
  }

  /// Generate photo ledger
  PhotoLedger generatePhotoLedger(String projectId, String projectName, DateTime startDate, DateTime endDate) {
    final filteredPhotos = _photos.where((p) =>
      p.projectId == projectId &&
      p.timestamp.isAfter(startDate) &&
      p.timestamp.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();

    // Group by date and category
    final entriesMap = <String, PhotoLedgerEntry>{};

    for (final photo in filteredPhotos) {
      final key = '${photo.dateDisplay}_${photo.category.name}';

      if (entriesMap.containsKey(key)) {
        final existing = entriesMap[key]!;
        entriesMap[key] = PhotoLedgerEntry(
          date: existing.date,
          category: existing.category,
          photos: [...existing.photos, photo],
        );
      } else {
        entriesMap[key] = PhotoLedgerEntry(
          date: DateTime(photo.timestamp.year, photo.timestamp.month, photo.timestamp.day),
          category: photo.category,
          photos: [photo],
        );
      }
    }

    final entries = entriesMap.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return PhotoLedger(
      projectId: projectId,
      projectName: projectName,
      generatedDate: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      entries: entries,
      totalPhotos: filteredPhotos.length,
    );
  }

  /// Get category statistics
  Map<PhotoCategory, int> getCategoryStats(String projectId) {
    final stats = <PhotoCategory, int>{};
    for (final photo in _photos.where((p) => p.projectId == projectId)) {
      stats[photo.category] = (stats[photo.category] ?? 0) + 1;
    }
    return stats;
  }

  /// Get recent photos
  List<ConstructionPhoto> getRecentPhotos(String projectId, {int limit = 10}) {
    return _photos
      .where((p) => p.projectId == projectId)
      .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
}
