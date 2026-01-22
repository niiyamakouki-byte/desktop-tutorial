/// Material and Order Management Models
/// For tracking materials, orders, and delivery deadlines

/// Material item representing a product/part needed for construction
class Material {
  final String id;
  final String productCode;      // 品番
  final String name;             // 材料名
  final String specification;    // 仕様
  final String manufacturer;     // メーカー
  final String supplier;         // 問屋/仕入先
  final double unitPrice;        // 単価
  final String unit;             // 単位 (個, m, 枚, etc.)
  final int leadTimeDays;        // 納期日数（発注から届くまで）
  final String category;         // カテゴリ (電気, 配管, 建材, etc.)
  final String? imageUrl;
  final String? catalogUrl;
  final Map<String, dynamic>? specifications;

  const Material({
    required this.id,
    required this.productCode,
    required this.name,
    this.specification = '',
    this.manufacturer = '',
    this.supplier = '',
    this.unitPrice = 0,
    this.unit = '個',
    this.leadTimeDays = 7,
    this.category = 'general',
    this.imageUrl,
    this.catalogUrl,
    this.specifications,
  });

  Material copyWith({
    String? id,
    String? productCode,
    String? name,
    String? specification,
    String? manufacturer,
    String? supplier,
    double? unitPrice,
    String? unit,
    int? leadTimeDays,
    String? category,
    String? imageUrl,
    String? catalogUrl,
    Map<String, dynamic>? specifications,
  }) {
    return Material(
      id: id ?? this.id,
      productCode: productCode ?? this.productCode,
      name: name ?? this.name,
      specification: specification ?? this.specification,
      manufacturer: manufacturer ?? this.manufacturer,
      supplier: supplier ?? this.supplier,
      unitPrice: unitPrice ?? this.unitPrice,
      unit: unit ?? this.unit,
      leadTimeDays: leadTimeDays ?? this.leadTimeDays,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      catalogUrl: catalogUrl ?? this.catalogUrl,
      specifications: specifications ?? this.specifications,
    );
  }
}

/// Material requirement for a specific task
class TaskMaterial {
  final String id;
  final String taskId;
  final String materialId;
  final Material? material;
  final double quantity;         // 必要数量
  final String? notes;
  final OrderStatus orderStatus;
  final String? orderId;         // 関連する発注ID

  const TaskMaterial({
    required this.id,
    required this.taskId,
    required this.materialId,
    this.material,
    required this.quantity,
    this.notes,
    this.orderStatus = OrderStatus.notOrdered,
    this.orderId,
  });

  TaskMaterial copyWith({
    String? id,
    String? taskId,
    String? materialId,
    Material? material,
    double? quantity,
    String? notes,
    OrderStatus? orderStatus,
    String? orderId,
  }) {
    return TaskMaterial(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      materialId: materialId ?? this.materialId,
      material: material ?? this.material,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      orderStatus: orderStatus ?? this.orderStatus,
      orderId: orderId ?? this.orderId,
    );
  }

  /// Calculate order deadline based on task start date and lead time
  DateTime? calculateOrderDeadline(DateTime taskStartDate) {
    if (material == null) return null;
    // Need to order (leadTimeDays + buffer days) before task starts
    final bufferDays = 2; // 余裕を持って2日前
    return taskStartDate.subtract(
      Duration(days: material!.leadTimeDays + bufferDays),
    );
  }

  /// Check if order is overdue
  bool isOrderOverdue(DateTime taskStartDate) {
    if (orderStatus != OrderStatus.notOrdered) return false;
    final deadline = calculateOrderDeadline(taskStartDate);
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline);
  }

  /// Days until order deadline (negative if overdue)
  int? daysUntilOrderDeadline(DateTime taskStartDate) {
    final deadline = calculateOrderDeadline(taskStartDate);
    if (deadline == null) return null;
    return deadline.difference(DateTime.now()).inDays;
  }
}

/// Order status enum
enum OrderStatus {
  notOrdered,     // 未発注
  ordered,        // 発注済み
  confirmed,      // 発注確定（問屋から確認）
  shipped,        // 出荷済み
  delivered,      // 納品済み
  cancelled,      // キャンセル
}

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.notOrdered:
        return '未発注';
      case OrderStatus.ordered:
        return '発注済み';
      case OrderStatus.confirmed:
        return '発注確定';
      case OrderStatus.shipped:
        return '出荷済み';
      case OrderStatus.delivered:
        return '納品済み';
      case OrderStatus.cancelled:
        return 'キャンセル';
    }
  }

  bool get isComplete => this == OrderStatus.delivered;
  bool get needsAction => this == OrderStatus.notOrdered;
}

/// Purchase order (発注書)
class PurchaseOrder {
  final String id;
  final String projectId;
  final String supplierId;        // 問屋ID
  final String supplierName;      // 問屋名
  final List<OrderItem> items;    // 発注明細
  final DateTime orderDate;       // 発注日
  final DateTime? expectedDelivery; // 納品予定日
  final DateTime? actualDelivery;   // 実際の納品日
  final OrderStatus status;
  final double totalAmount;       // 合計金額
  final String? notes;
  final String? orderNumber;      // 発注番号

  const PurchaseOrder({
    required this.id,
    required this.projectId,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.orderDate,
    this.expectedDelivery,
    this.actualDelivery,
    this.status = OrderStatus.ordered,
    this.totalAmount = 0,
    this.notes,
    this.orderNumber,
  });

  PurchaseOrder copyWith({
    String? id,
    String? projectId,
    String? supplierId,
    String? supplierName,
    List<OrderItem>? items,
    DateTime? orderDate,
    DateTime? expectedDelivery,
    DateTime? actualDelivery,
    OrderStatus? status,
    double? totalAmount,
    String? notes,
    String? orderNumber,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      items: items ?? this.items,
      orderDate: orderDate ?? this.orderDate,
      expectedDelivery: expectedDelivery ?? this.expectedDelivery,
      actualDelivery: actualDelivery ?? this.actualDelivery,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      orderNumber: orderNumber ?? this.orderNumber,
    );
  }

  /// Check if delivery is at risk (overdue or close)
  bool get isDeliveryAtRisk {
    if (status == OrderStatus.delivered || status == OrderStatus.cancelled) {
      return false;
    }
    if (expectedDelivery == null) return false;
    final daysUntil = expectedDelivery!.difference(DateTime.now()).inDays;
    return daysUntil < 3; // 3日以内ならリスク
  }
}

/// Individual item in a purchase order
class OrderItem {
  final String id;
  final String materialId;
  final Material? material;
  final double quantity;
  final double unitPrice;
  final String? taskId;           // 紐付いているタスク
  final String? notes;

  const OrderItem({
    required this.id,
    required this.materialId,
    this.material,
    required this.quantity,
    this.unitPrice = 0,
    this.taskId,
    this.notes,
  });

  double get totalPrice => quantity * unitPrice;
}

/// Supplier/Vendor information (問屋情報)
class Supplier {
  final String id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? fax;
  final String? address;
  final List<String> categories;   // 取扱カテゴリ
  final int averageLeadTimeDays;   // 平均納期
  final String? notes;

  const Supplier({
    required this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.fax,
    this.address,
    this.categories = const [],
    this.averageLeadTimeDays = 7,
    this.notes,
  });
}

/// Alert for order/material issues
class OrderAlert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? taskId;
  final String? materialId;
  final String? orderId;
  final DateTime createdAt;
  final bool isRead;
  final bool isDismissed;

  const OrderAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.taskId,
    this.materialId,
    this.orderId,
    required this.createdAt,
    this.isRead = false,
    this.isDismissed = false,
  });
}

enum AlertType {
  orderDeadline,      // 発注期限が近い
  orderOverdue,       // 発注期限を過ぎている
  deliveryDelay,      // 納品遅延のリスク
  materialShortage,   // 材料不足
  priceChange,        // 価格変更
  stockOut,           // 在庫切れ
}

enum AlertSeverity {
  low,      // 参考情報
  medium,   // 注意
  high,     // 警告
  critical, // 緊急
}

extension AlertSeverityExtension on AlertSeverity {
  String get label {
    switch (this) {
      case AlertSeverity.low:
        return '参考';
      case AlertSeverity.medium:
        return '注意';
      case AlertSeverity.high:
        return '警告';
      case AlertSeverity.critical:
        return '緊急';
    }
  }
}
