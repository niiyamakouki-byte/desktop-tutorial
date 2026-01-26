import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/attendance_service.dart';
import '../../data/models/person.dart';
import '../../data/models/company.dart';

/// キオスク画面（入退場記録用タブレット画面）
///
/// 設計方針:
/// - タブレット横置き最適化
/// - 大きなボタン（手袋でも押せる）
/// - シンプルな操作（2タップ以内で記録）
class KioskScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final VoidCallback? onExit;

  const KioskScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.onExit,
  });

  @override
  State<KioskScreen> createState() => _KioskScreenState();
}

class _KioskScreenState extends State<KioskScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = true;
  List<Person> _persons = [];
  List<Company> _companies = [];
  Person? _selectedPerson;
  String? _selectedCompanyFilter;
  String _searchQuery = '';
  bool _showSuccess = false;
  String _successMessage = '';
  bool _hasWarning = false;
  String _warningMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _attendanceService.initialize();

    // サンプルデータがなければ生成
    final persons = await _attendanceService.getPersonsByProject(widget.projectId);
    if (persons.isEmpty) {
      await _attendanceService.generateSampleData(widget.projectId);
    }

    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _persons = await _attendanceService.getPersonsByProject(widget.projectId);
      _companies = await _attendanceService.getAllCompanies();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Person> get _filteredPersons {
    var filtered = _persons;

    // 会社フィルター
    if (_selectedCompanyFilter != null) {
      filtered = filtered.where((p) => p.companyId == _selectedCompanyFilter).toList();
    }

    // 検索フィルター
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.qrCode.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  Future<void> _recordAttendance(bool isIn) async {
    if (_selectedPerson == null) return;

    setState(() => _isLoading = true);

    try {
      final result = isIn
          ? await _attendanceService.recordIn(
              projectId: widget.projectId,
              personId: _selectedPerson!.id,
              companyId: _selectedPerson!.companyId,
            )
          : await _attendanceService.recordOut(
              projectId: widget.projectId,
              personId: _selectedPerson!.id,
              companyId: _selectedPerson!.companyId,
            );

      if (result.success) {
        _showSuccessDialog(
          '${_selectedPerson!.name}さんの${isIn ? "入場" : "退場"}を記録しました',
          result.hasWarning,
          result.warningMessage,
        );
        _selectedPerson = null;
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String message, bool hasWarning, String? warningMessage) {
    setState(() {
      _showSuccess = true;
      _successMessage = message;
      _hasWarning = hasWarning;
      _warningMessage = warningMessage ?? '';
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSuccess = false;
        });
      }
    });
  }

  Company? _getCompanyForPerson(Person person) {
    try {
      return _companies.firstWhere((c) => c.id == person.companyId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '入退場記録',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.projectName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // 現在時刻表示
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              final now = DateTime.now();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${now.year}/${now.month}/${now.day}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (widget.onExit != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onExit,
              tooltip: '終了',
            ),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              // 左側: 職人選択リスト
              Expanded(
                flex: 2,
                child: _buildPersonList(),
              ),
              // 右側: IN/OUTボタンエリア
              Expanded(
                flex: 1,
                child: _buildActionPanel(),
              ),
            ],
          ),
          // 成功メッセージオーバーレイ
          if (_showSuccess)
            _buildSuccessOverlay(),
          // ローディングオーバーレイ
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonList() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 検索バー
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '名前またはQRコードで検索...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // 会社フィルター
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedCompanyFilter,
                      hint: const Text('全会社'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('全会社'),
                        ),
                        ..._companies.map((c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.displayName),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedCompanyFilter = value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 職人リスト
          Expanded(
            child: _filteredPersons.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '職人が見つかりません',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredPersons.length,
                    itemBuilder: (context, index) {
                      final person = _filteredPersons[index];
                      final company = _getCompanyForPerson(person);
                      final isSelected = _selectedPerson?.id == person.id;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Material(
                          color: isSelected
                              ? const Color(0xFF1A237E).withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                _selectedPerson = isSelected ? null : person;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1A237E)
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  // アバター
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: _getJobTypeColor(person.jobType),
                                    child: Text(
                                      person.name.substring(0, 1),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // 名前・会社
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          person.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                company?.displayName ?? '不明',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getJobTypeColor(person.jobType).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                person.jobType.displayName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _getJobTypeColor(person.jobType),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // チェックマーク
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1A237E),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel() {
    final bool canRecord = _selectedPerson != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          left: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 選択中の職人情報
          if (_selectedPerson != null) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '選択中',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedPerson!.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // INボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 120,
              child: ElevatedButton(
                onPressed: canRecord ? () => _recordAttendance(true) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRecord
                      ? const Color(0xFF4CAF50)
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: canRecord ? 8 : 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.login,
                      size: 48,
                      color: canRecord ? Colors.white : Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'IN',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: canRecord ? Colors.white : Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // OUTボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 120,
              child: ElevatedButton(
                onPressed: canRecord ? () => _recordAttendance(false) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canRecord
                      ? const Color(0xFFF44336)
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: canRecord ? 8 : 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      size: 48,
                      color: canRecord ? Colors.white : Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'OUT',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: canRecord ? Colors.white : Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 選択ヒント
          if (!canRecord)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '左側のリストから\n名前を選択してください',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(48),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _hasWarning ? Colors.orange[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hasWarning ? Colors.orange : Colors.green,
              width: 3,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _hasWarning ? Icons.warning_amber : Icons.check_circle,
                size: 80,
                color: _hasWarning ? Colors.orange : Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                _successMessage,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _hasWarning ? Colors.orange[800] : Colors.green[800],
                ),
                textAlign: TextAlign.center,
              ),
              if (_hasWarning && _warningMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _warningMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getJobTypeColor(JobType jobType) {
    switch (jobType) {
      case JobType.carpenter:
        return const Color(0xFF8D6E63); // 茶色
      case JobType.scaffolder:
        return const Color(0xFF5C6BC0); // 紫
      case JobType.electrician:
        return const Color(0xFFFFB300); // 黄色
      case JobType.plumber:
        return const Color(0xFF00ACC1); // シアン
      case JobType.painter:
        return const Color(0xFFE91E63); // ピンク
      case JobType.plasterer:
        return const Color(0xFF795548); // ブラウン
      case JobType.reinforcer:
        return const Color(0xFF546E7A); // グレー
      case JobType.formworker:
        return const Color(0xFF6D4C41); // ダークブラウン
      case JobType.operator:
        return const Color(0xFFFF7043); // オレンジ
      case JobType.supervisor:
        return const Color(0xFF1A237E); // ダークブルー
      case JobType.clerk:
        return const Color(0xFF7986CB); // ライトブルー
      case JobType.other:
        return const Color(0xFF78909C); // ブルーグレー
    }
  }

  @override
  void dispose() {
    _attendanceService.dispose();
    super.dispose();
  }
}
