/// Change Feed Panel
/// 右サイドバー用の変更フィードパネル
///
/// ChatGPT/Gemini議論に基づく設計:
/// - 未確認バッジ表示
/// - 変更カード（最大3件）
/// - 「確認」ボタン
/// - リアルタイム更新対応

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/change_event_model.dart';
import '../../../data/services/sync_service.dart';

/// 変更フィードパネル
class ChangeFeedPanel extends StatefulWidget {
  /// プロジェクトIDでフィルタ（nullの場合は全件）
  final String? projectId;

  /// 表示する最大件数
  final int maxItems;

  /// 確認ボタンを押した時のコールバック
  final VoidCallback? onAcknowledge;

  /// 変更をタップした時のコールバック
  final Function(ChangeEvent)? onChangeTap;

  const ChangeFeedPanel({
    super.key,
    this.projectId,
    this.maxItems = 3,
    this.onAcknowledge,
    this.onChangeTap,
  });

  @override
  State<ChangeFeedPanel> createState() => _ChangeFeedPanelState();
}

class _ChangeFeedPanelState extends State<ChangeFeedPanel> {
  List<ChangeEvent> _events = [];
  int _unackedCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();

    // リアルタイム更新をリッスン
    SyncServiceProvider.instance.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _events = widget.projectId != null
              ? state.events.filterByProject(widget.projectId!)
              : state.events;
          _unackedCount = state.unackedCount;
        });
      }
    });
  }

  void _loadEvents() {
    final state = SyncServiceProvider.instance.state;
    _events = widget.projectId != null
        ? state.events.filterByProject(widget.projectId!)
        : state.events;
    _unackedCount = state.unackedCount;
  }

  Future<void> _handleAcknowledge() async {
    setState(() => _isLoading = true);

    await SyncServiceProvider.instance.acknowledgeAll();
    widget.onAcknowledge?.call();

    setState(() {
      _isLoading = false;
      _unackedCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ヘッダー
          _buildHeader(),

          // 変更リスト
          if (_events.isEmpty)
            _buildEmptyState()
          else
            ..._events.take(widget.maxItems).map(_buildChangeCard),

          // フッター（確認ボタン）
          if (_unackedCount > 0) _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.sync,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          const Text(
            'Change Feed',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // 未確認バッジ
          if (_unackedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_unackedCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 32,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: 8),
            Text(
              '変更はありません',
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeCard(ChangeEvent event) {
    return InkWell(
      onTap: () => widget.onChangeTap?.call(event),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // アイコン
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _getTypeColor(event.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTypeIcon(event.type),
                size: 18,
                color: _getTypeColor(event.type),
              ),
            ),
            const SizedBox(width: 12),

            // 内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.displaySummary,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.timeAgo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // 矢印
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleAcknowledge,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  '確認済みにする',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(ChangeEventType type) {
    switch (type) {
      case ChangeEventType.created:
        return Icons.add_circle_outline;
      case ChangeEventType.updated:
        return Icons.edit;
      case ChangeEventType.deleted:
        return Icons.delete_outline;
      case ChangeEventType.batchUpdate:
        return Icons.sync;
      case ChangeEventType.syncReset:
        return Icons.refresh;
    }
  }

  Color _getTypeColor(ChangeEventType type) {
    switch (type) {
      case ChangeEventType.created:
        return const Color(0xFF4CAF50);
      case ChangeEventType.updated:
        return const Color(0xFF2196F3);
      case ChangeEventType.deleted:
        return const Color(0xFFF44336);
      case ChangeEventType.batchUpdate:
        return const Color(0xFF9C27B0);
      case ChangeEventType.syncReset:
        return const Color(0xFFFF9800);
    }
  }
}

/// コンパクト版（サイドバー用）
class ChangeFeedCompact extends StatelessWidget {
  final int unackedCount;
  final VoidCallback? onTap;

  const ChangeFeedCompact({
    super.key,
    required this.unackedCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: unackedCount > 0
              ? AppColors.error.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync,
              size: 16,
              color:
                  unackedCount > 0 ? AppColors.error : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Change Feed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: unackedCount > 0
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
            if (unackedCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unackedCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// プレゼンスバッジ（メンバーアイコン横のオンラインバッジ）
class PresenceBadge extends StatelessWidget {
  final bool isOnline;
  final double size;

  const PresenceBadge({
    super.key,
    required this.isOnline,
    this.size = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          if (isOnline)
            BoxShadow(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
        ],
      ),
    );
  }
}

/// クイックアクションボタン（雨ボタン/トラブルボタン）
class QuickActionButtons extends StatelessWidget {
  final VoidCallback? onRainTap;
  final VoidCallback? onTroubleTap;

  const QuickActionButtons({
    super.key,
    this.onRainTap,
    this.onTroubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.umbrella,
            label: '雨天',
            color: const Color(0xFF2196F3),
            onTap: onRainTap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.warning_amber,
            label: 'トラブル',
            color: const Color(0xFFF44336),
            onTap: onTroubleTap,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
