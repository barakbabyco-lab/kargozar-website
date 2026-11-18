import '../../core/network/kargozar_api_client.dart';

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.parentId,
    this.hasChildren = false,
    this.children = const [],
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? parentId;
  final bool hasChildren;
  final List<ServiceCategory> children;
  final bool isActive;
  final int sortOrder;

  ServiceCategory copyWith({List<ServiceCategory>? children}) {
    return ServiceCategory(
      id: id,
      name: name,
      slug: slug,
      description: description,
      parentId: parentId,
      hasChildren: hasChildren,
      children: children ?? this.children,
      isActive: isActive,
      sortOrder: sortOrder,
    );
  }

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      parentId: json['parent_id']?.toString(),
      hasChildren: json['has_children'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: _asInt(json['sort_order']),
    );
  }
}

class CatalogService {
  const CatalogService({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.requirements = const [],
    this.estimatedDays,
    this.basePrice,
    this.isActive = true,
    this.sortOrder = 0,
    this.categoryName,
    this.categorySlug,
  });

  final String id;
  final String title;
  final String slug;
  final String? description;
  final List<String> requirements;
  final int? estimatedDays;
  final int? basePrice;
  final bool isActive;
  final int sortOrder;
  final String? categoryName;
  final String? categorySlug;

  factory CatalogService.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final categoryMap = category is Map<String, dynamic> ? category : null;
    final requirements = json['requirements'];
    return CatalogService(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      requirements: requirements is List
          ? requirements.map((item) => item.toString()).toList(growable: false)
          : const [],
      estimatedDays: _nullableInt(json['estimated_days']),
      basePrice: _nullableInt(json['base_price']),
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: _asInt(json['sort_order']),
      categoryName: categoryMap?['name']?.toString(),
      categorySlug: categoryMap?['slug']?.toString(),
    );
  }
}

class ServiceCatalogRepository {
  const ServiceCatalogRepository(this._api);

  final KargozarApiClient _api;

  Future<List<ServiceCategory>> getCategories() async {
    final response = await _api.getCategories();
    return _listFrom(response)
        .map(ServiceCategory.fromJson)
        .toList(growable: false);
  }

  Future<List<ServiceCategory>> getCategoryTree() async {
    final categories = await getCategories();
    final childrenByParent = <String?, List<ServiceCategory>>{};

    for (final category in categories) {
      childrenByParent.putIfAbsent(category.parentId, () => []).add(category);
    }

    List<ServiceCategory> buildChildren(
      String? parentId,
      Set<String> ancestors,
    ) {
      final children = childrenByParent[parentId] ?? const <ServiceCategory>[];
      return children.map((category) {
        if (ancestors.contains(category.id)) {
          return category;
        }
        return category.copyWith(
          children: buildChildren(
            category.id,
            {...ancestors, category.id},
          ),
        );
      }).toList(growable: false);
    }

    return buildChildren(null, <String>{});
  }

  Future<List<CatalogService>> getServices({
    String? category,
    String? query,
    int page = 1,
  }) async {
    final response = await _api.getServices(
      category: category,
      query: query,
      page: page,
    );
    return _listFrom(response)
        .map(CatalogService.fromJson)
        .toList(growable: false);
  }

  Future<CatalogService> getService(String slug) async {
    final response = await _api.getService(slug);
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('پاسخ جزئیات خدمت معتبر نیست.');
    }
    return CatalogService.fromJson(data);
  }
}

List<Map<String, dynamic>> _listFrom(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is! List) {
    throw const FormatException('فهرست دریافتی از سرور معتبر نیست.');
  }
  return data.whereType<Map<String, dynamic>>().toList(growable: false);
}

int _asInt(dynamic value) => _nullableInt(value) ?? 0;

int? _nullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
