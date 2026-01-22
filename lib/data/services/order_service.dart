import 'package:flutter/foundation.dart';
import '../models/material_model.dart';
import '../models/models.dart';
import '../models/project_health_model.dart';

/// Order Management Service
/// Handles material ordering, deadline tracking, and alerts
class OrderService extends ChangeNotifier {
  // Mock data storage
  final List<ConstructionMaterial> _materials = [];
  final List<TaskConstructionMaterial> _taskConstructionMaterials = [];
  final List<PurchaseOrder> _purchaseOrders = [];
  final List<Supplier> _suppliers = [];
  final List<OrderAlert> _alerts = [];

  // Configurable alert thresholds
  AlertThresholdConfig _alertConfig = const AlertThresholdConfig();

  // Getters
  List<ConstructionMaterial> get materials => List.unmodifiable(_materials);
  List<TaskConstructionMaterial> get taskConstructionMaterials => List.unmodifiable(_taskConstructionMaterials);
  List<PurchaseOrder> get purchaseOrders => List.unmodifiable(_purchaseOrders);
  List<Supplier> get suppliers => List.unmodifiable(_suppliers);
  List<OrderAlert> get alerts => List.unmodifiable(_alerts);
  AlertThresholdConfig get alertConfig => _alertConfig;

  // Filtered getters
  List<OrderAlert> get unreadAlerts => _alerts.where((a) => !a.isRead && !a.isDismissed).toList();
  List<OrderAlert> get criticalAlerts => _alerts.where((a) => a.severity == AlertSeverity.critical && !a.isDismissed).toList();
  List<OrderAlert> get highPriorityAlerts => _alerts.where((a) =>
    (a.severity == AlertSeverity.critical || a.severity == AlertSeverity.high) && !a.isDismissed
  ).toList();

  /// Update alert threshold configuration
  void updateAlertConfig(AlertThresholdConfig config) {
    _alertConfig = config;
    notifyListeners();
  }

  /// Calculate order deadline with configurable buffer
  DateTime? calculateOrderDeadlineWithConfig(DateTime taskStartDate, int materialLeadTime) {
    return taskStartDate.subtract(
      Duration(days: materialLeadTime + _alertConfig.bufferDays),
    );
  }

  /// Get alert severity based on configurable thresholds
  AlertSeverity getAlertSeverityFromConfig(int daysUntilDeadline) {
    if (daysUntilDeadline < 0) {
      return AlertSeverity.critical;
    } else if (daysUntilDeadline <= _alertConfig.highThresholdDays) {
      return AlertSeverity.high;
    } else if (daysUntilDeadline <= _alertConfig.mediumThresholdDays) {
      return AlertSeverity.medium;
    }
    return AlertSeverity.low;
  }

  List<PurchaseOrder> get pendingOrders => _purchaseOrders.where((o) =>
    o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled
  ).toList();

  /// Initialize with mock data
  void initialize() {
    _initializeMockSuppliers();
    _initializeMockConstructionMaterials();
    _initializeMockTaskConstructionMaterials();
    notifyListeners();
  }

  /// Get materials needed for a specific task
  List<TaskConstructionMaterial> getConstructionMaterialsForTask(String taskId) {
    return _taskConstructionMaterials.where((tm) => tm.taskId == taskId).toList();
  }

  /// Get all tasks that need material ordering (未発注)
  List<TaskConstructionMaterial> getUnorderedConstructionMaterials() {
    return _taskConstructionMaterials.where((tm) => tm.orderStatus == OrderStatus.notOrdered).toList();
  }

  /// Calculate order deadline for a task's materials
  /// Returns the earliest deadline among all materials for the task
  DateTime? getOrderDeadlineForTask(String taskId, DateTime taskStartDate) {
    final materials = getConstructionMaterialsForTask(taskId);
    if (materials.isEmpty) return null;

    DateTime? earliestDeadline;
    for (final tm in materials) {
      final deadline = tm.calculateOrderDeadline(taskStartDate);
      if (deadline != null) {
        if (earliestDeadline == null || deadline.isBefore(earliestDeadline)) {
          earliestDeadline = deadline;
        }
      }
    }
    return earliestDeadline;
  }

  /// Check if any materials for a task are overdue
  bool hasOverdueConstructionMaterials(String taskId, DateTime taskStartDate) {
    final materials = getConstructionMaterialsForTask(taskId);
    return materials.any((tm) => tm.isOrderOverdue(taskStartDate));
  }

  /// Get days until order deadline for a task
  /// Returns the minimum days (most urgent)
  int? getDaysUntilDeadline(String taskId, DateTime taskStartDate) {
    final materials = getConstructionMaterialsForTask(taskId);
    if (materials.isEmpty) return null;

    int? minDays;
    for (final tm in materials) {
      if (tm.orderStatus != OrderStatus.notOrdered) continue;
      final days = tm.daysUntilOrderDeadline(taskStartDate);
      if (days != null) {
        if (minDays == null || days < minDays) {
          minDays = days;
        }
      }
    }
    return minDays;
  }

  /// Generate alerts for all tasks with configurable thresholds
  void generateAlerts(List<Task> tasks) {
    _alerts.clear();

    for (final task in tasks) {
      final materials = getConstructionMaterialsForTask(task.id);

      for (final tm in materials) {
        if (tm.orderStatus != OrderStatus.notOrdered) continue;

        // Use configurable buffer in deadline calculation
        final deadline = tm.material != null
            ? calculateOrderDeadlineWithConfig(task.startDate, tm.material!.leadTimeDays)
            : tm.calculateOrderDeadline(task.startDate);

        if (deadline == null) continue;
        final daysUntil = deadline.difference(DateTime.now()).inDays;

        // Use configurable thresholds
        final severity = getAlertSeverityFromConfig(daysUntil);

        if (daysUntil < 0) {
          // Overdue - Critical
          _alerts.add(OrderAlert(
            id: 'alert_${tm.id}_overdue',
            type: AlertType.orderOverdue,
            severity: AlertSeverity.critical,
            title: '発注期限超過',
            message: '「${task.name}」の材料「${tm.material?.name ?? tm.materialId}」の発注期限を${-daysUntil}日過ぎています。至急発注してください。',
            taskId: task.id,
            materialId: tm.materialId,
            createdAt: DateTime.now(),
          ));
        } else if (daysUntil <= _alertConfig.highThresholdDays) {
          // Urgent - High (configurable, default 3 days)
          _alerts.add(OrderAlert(
            id: 'alert_${tm.id}_urgent',
            type: AlertType.orderDeadline,
            severity: AlertSeverity.high,
            title: '発注期限が迫っています',
            message: '「${task.name}」の材料「${tm.material?.name ?? tm.materialId}」の発注期限まであと${daysUntil}日です。',
            taskId: task.id,
            materialId: tm.materialId,
            createdAt: DateTime.now(),
          ));
        } else if (daysUntil <= _alertConfig.mediumThresholdDays) {
          // Warning - Medium (configurable, default 7 days)
          _alerts.add(OrderAlert(
            id: 'alert_${tm.id}_warning',
            type: AlertType.orderDeadline,
            severity: AlertSeverity.medium,
            title: '発注準備をお忘れなく',
            message: '「${task.name}」の材料「${tm.material?.name ?? tm.materialId}」の発注期限まであと${daysUntil}日です。',
            taskId: task.id,
            materialId: tm.materialId,
            createdAt: DateTime.now(),
          ));
        }
      }
    }

    // Sort by severity (most critical first)
    _alerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    notifyListeners();
  }

  /// Get upcoming order deadlines sorted by urgency
  List<Map<String, dynamic>> getUpcomingOrderDeadlines(List<Task> tasks, {int limit = 10}) {
    final deadlines = <Map<String, dynamic>>[];

    for (final task in tasks) {
      final materials = getConstructionMaterialsForTask(task.id);

      for (final tm in materials) {
        if (tm.orderStatus != OrderStatus.notOrdered) continue;

        final deadline = tm.material != null
            ? calculateOrderDeadlineWithConfig(task.startDate, tm.material!.leadTimeDays)
            : tm.calculateOrderDeadline(task.startDate);

        if (deadline == null) continue;
        final daysUntil = deadline.difference(DateTime.now()).inDays;

        deadlines.add({
          'taskId': task.id,
          'taskName': task.name,
          'materialId': tm.materialId,
          'materialName': tm.material?.name ?? '不明',
          'deadline': deadline,
          'daysUntil': daysUntil,
          'severity': getAlertSeverityFromConfig(daysUntil),
          'leadTimeDays': tm.material?.leadTimeDays ?? 0,
          'quantity': tm.quantity,
          'unit': tm.material?.unit ?? '',
        });
      }
    }

    // Sort by days until deadline (most urgent first)
    deadlines.sort((a, b) => (a['daysUntil'] as int).compareTo(b['daysUntil'] as int));

    return deadlines.take(limit).toList();
  }

  /// Create a purchase order
  PurchaseOrder createPurchaseOrder({
    required String projectId,
    required String supplierId,
    required List<OrderItem> items,
    String? notes,
  }) {
    final supplier = _suppliers.firstWhere(
      (s) => s.id == supplierId,
      orElse: () => Supplier(id: supplierId, name: '不明'),
    );

    final totalAmount = items.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    final order = PurchaseOrder(
      id: 'po_${DateTime.now().millisecondsSinceEpoch}',
      projectId: projectId,
      supplierId: supplierId,
      supplierName: supplier.name,
      items: items,
      orderDate: DateTime.now(),
      expectedDelivery: DateTime.now().add(Duration(days: supplier.averageLeadTimeDays)),
      status: OrderStatus.ordered,
      totalAmount: totalAmount,
      notes: notes,
      orderNumber: 'PO-${DateTime.now().year}-${_purchaseOrders.length + 1}'.padLeft(6, '0'),
    );

    _purchaseOrders.add(order);

    // Update task material statuses
    for (final item in items) {
      if (item.taskId != null) {
        final index = _taskConstructionMaterials.indexWhere(
          (tm) => tm.taskId == item.taskId && tm.materialId == item.materialId,
        );
        if (index >= 0) {
          _taskConstructionMaterials[index] = _taskConstructionMaterials[index].copyWith(
            orderStatus: OrderStatus.ordered,
            orderId: order.id,
          );
        }
      }
    }

    notifyListeners();
    return order;
  }

  /// Update order status
  void updateOrderStatus(String orderId, OrderStatus status, {DateTime? actualDelivery}) {
    final index = _purchaseOrders.indexWhere((o) => o.id == orderId);
    if (index >= 0) {
      _purchaseOrders[index] = _purchaseOrders[index].copyWith(
        status: status,
        actualDelivery: actualDelivery ?? (status == OrderStatus.delivered ? DateTime.now() : null),
      );

      // Update task material statuses
      for (final item in _purchaseOrders[index].items) {
        final tmIndex = _taskConstructionMaterials.indexWhere(
          (tm) => tm.orderId == orderId && tm.materialId == item.materialId,
        );
        if (tmIndex >= 0) {
          _taskConstructionMaterials[tmIndex] = _taskConstructionMaterials[tmIndex].copyWith(
            orderStatus: status,
          );
        }
      }

      notifyListeners();
    }
  }

  /// Mark alert as read
  void markAlertAsRead(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index >= 0) {
      _alerts[index] = OrderAlert(
        id: _alerts[index].id,
        type: _alerts[index].type,
        severity: _alerts[index].severity,
        title: _alerts[index].title,
        message: _alerts[index].message,
        taskId: _alerts[index].taskId,
        materialId: _alerts[index].materialId,
        orderId: _alerts[index].orderId,
        createdAt: _alerts[index].createdAt,
        isRead: true,
        isDismissed: _alerts[index].isDismissed,
      );
      notifyListeners();
    }
  }

  /// Dismiss alert
  void dismissAlert(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index >= 0) {
      _alerts[index] = OrderAlert(
        id: _alerts[index].id,
        type: _alerts[index].type,
        severity: _alerts[index].severity,
        title: _alerts[index].title,
        message: _alerts[index].message,
        taskId: _alerts[index].taskId,
        materialId: _alerts[index].materialId,
        orderId: _alerts[index].orderId,
        createdAt: _alerts[index].createdAt,
        isRead: _alerts[index].isRead,
        isDismissed: true,
      );
      notifyListeners();
    }
  }

  /// Add material to task
  void addConstructionMaterialToTask({
    required String taskId,
    required String materialId,
    required double quantity,
    String? notes,
  }) {
    final material = _materials.firstWhere(
      (m) => m.id == materialId,
      orElse: () => ConstructionMaterial(id: materialId, productCode: '', name: '不明'),
    );

    final taskConstructionMaterial = TaskConstructionMaterial(
      id: 'tm_${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      materialId: materialId,
      material: material,
      quantity: quantity,
      notes: notes,
      orderStatus: OrderStatus.notOrdered,
    );

    _taskConstructionMaterials.add(taskConstructionMaterial);
    notifyListeners();
  }

  /// Generate order list for export (to send to supplier)
  String generateOrderListCsv(String supplierId) {
    final items = _taskConstructionMaterials
        .where((tm) => tm.orderStatus == OrderStatus.notOrdered && tm.material?.supplier == supplierId)
        .toList();

    final buffer = StringBuffer();
    buffer.writeln('品番,品名,数量,単位,単価,金額,備考');

    for (final item in items) {
      final m = item.material;
      if (m == null) continue;
      buffer.writeln('${m.productCode},${m.name},${item.quantity},${m.unit},${m.unitPrice},${item.quantity * m.unitPrice},${item.notes ?? ''}');
    }

    return buffer.toString();
  }

  // ============== Mock Data Initialization ==============

  void _initializeMockSuppliers() {
    _suppliers.addAll([
      const Supplier(
        id: 'sup_1',
        name: '電材商事',
        contactPerson: '山田太郎',
        phone: '03-1234-5678',
        email: 'yamada@denzai.co.jp',
        categories: ['electrical'],
        averageLeadTimeDays: 5,
      ),
      const Supplier(
        id: 'sup_2',
        name: '配管資材センター',
        contactPerson: '鈴木一郎',
        phone: '03-2345-6789',
        email: 'suzuki@haikan.co.jp',
        categories: ['plumbing'],
        averageLeadTimeDays: 7,
      ),
      const Supplier(
        id: 'sup_3',
        name: '建材マーケット',
        contactPerson: '佐藤花子',
        phone: '03-3456-7890',
        email: 'sato@kenzai.co.jp',
        categories: ['structure', 'finishing'],
        averageLeadTimeDays: 10,
      ),
    ]);
  }

  void _initializeMockConstructionMaterials() {
    _materials.addAll([
      const ConstructionMaterial(
        id: 'mat_1',
        productCode: 'VVF2.0-2C',
        name: 'VVFケーブル 2.0mm 2芯',
        manufacturer: 'パナソニック',
        supplier: 'sup_1',
        unitPrice: 150,
        unit: 'm',
        leadTimeDays: 3,
        category: 'electrical',
      ),
      const ConstructionMaterial(
        id: 'mat_2',
        productCode: 'WN1001',
        name: 'フルカラー埋込スイッチ',
        manufacturer: 'パナソニック',
        supplier: 'sup_1',
        unitPrice: 280,
        unit: '個',
        leadTimeDays: 3,
        category: 'electrical',
      ),
      const ConstructionMaterial(
        id: 'mat_3',
        productCode: 'VP-50A',
        name: '塩ビ管 VP50',
        manufacturer: '積水化学',
        supplier: 'sup_2',
        unitPrice: 500,
        unit: '本',
        leadTimeDays: 5,
        category: 'plumbing',
      ),
      const ConstructionMaterial(
        id: 'mat_4',
        productCode: 'PB-904B',
        name: '普通コンクリート 25-18-25N',
        manufacturer: '生コン協同組合',
        supplier: 'sup_3',
        unitPrice: 15000,
        unit: 'm3',
        leadTimeDays: 2,
        category: 'structure',
      ),
      const ConstructionMaterial(
        id: 'mat_5',
        productCode: 'SD295A-D16',
        name: '異形鉄筋 D16',
        manufacturer: '新日鐵住金',
        supplier: 'sup_3',
        unitPrice: 85000,
        unit: 't',
        leadTimeDays: 14,
        category: 'structure',
      ),
    ]);
  }

  void _initializeMockTaskConstructionMaterials() {
    // These would be linked to actual tasks in a real app
    _taskConstructionMaterials.addAll([
      TaskConstructionMaterial(
        id: 'tm_1',
        taskId: 'task_foundation',
        materialId: 'mat_4',
        material: _materials.firstWhere((m) => m.id == 'mat_4'),
        quantity: 15,
        orderStatus: OrderStatus.notOrdered,
      ),
      TaskConstructionMaterial(
        id: 'tm_2',
        taskId: 'task_foundation',
        materialId: 'mat_5',
        material: _materials.firstWhere((m) => m.id == 'mat_5'),
        quantity: 2.5,
        orderStatus: OrderStatus.ordered,
        orderId: 'po_001',
      ),
      TaskConstructionMaterial(
        id: 'tm_3',
        taskId: 'task_electrical',
        materialId: 'mat_1',
        material: _materials.firstWhere((m) => m.id == 'mat_1'),
        quantity: 500,
        orderStatus: OrderStatus.notOrdered,
      ),
      TaskConstructionMaterial(
        id: 'tm_4',
        taskId: 'task_electrical',
        materialId: 'mat_2',
        material: _materials.firstWhere((m) => m.id == 'mat_2'),
        quantity: 20,
        orderStatus: OrderStatus.notOrdered,
      ),
      TaskConstructionMaterial(
        id: 'tm_5',
        taskId: 'task_plumbing',
        materialId: 'mat_3',
        material: _materials.firstWhere((m) => m.id == 'mat_3'),
        quantity: 30,
        orderStatus: OrderStatus.notOrdered,
      ),
    ]);
  }
}
