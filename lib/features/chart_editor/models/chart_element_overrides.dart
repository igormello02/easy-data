import 'chart_selection.dart';
import 'chart_type.dart';

enum ChartFontWeight { normal, semibold, bold }

enum ChartTextAlignment { left, center, right }

class ChartElementStyleOverride {
  const ChartElementStyleOverride({
    this.color,
    this.size,
    this.fontWeight,
    this.alignment,
    this.visible,
  });

  final int? color;
  final double? size;
  final ChartFontWeight? fontWeight;
  final ChartTextAlignment? alignment;
  final bool? visible;

  bool get isEmpty =>
      color == null &&
      size == null &&
      fontWeight == null &&
      alignment == null &&
      visible == null;

  ChartElementStyleOverride copyWith({
    int? color,
    double? size,
    ChartFontWeight? fontWeight,
    ChartTextAlignment? alignment,
    bool? visible,
    bool clearColor = false,
    bool clearSize = false,
    bool clearFontWeight = false,
    bool clearAlignment = false,
    bool clearVisible = false,
  }) {
    return ChartElementStyleOverride(
      color: clearColor ? null : color ?? this.color,
      size: clearSize ? null : size ?? this.size,
      fontWeight: clearFontWeight ? null : fontWeight ?? this.fontWeight,
      alignment: clearAlignment ? null : alignment ?? this.alignment,
      visible: clearVisible ? null : visible ?? this.visible,
    );
  }

  ChartElementStyleOverride merge(ChartElementStyleOverride? other) {
    if (other == null) return this;
    return ChartElementStyleOverride(
      color: other.color ?? color,
      size: other.size ?? size,
      fontWeight: other.fontWeight ?? fontWeight,
      alignment: other.alignment ?? alignment,
      visible: other.visible ?? visible,
    );
  }
}

class ChartElementStyleKey {
  const ChartElementStyleKey({
    required this.chartType,
    required this.elementType,
    this.index,
  });

  final ChartType chartType;
  final ChartElementType elementType;
  final int? index;

  @override
  bool operator ==(Object other) =>
      other is ChartElementStyleKey &&
      other.chartType == chartType &&
      other.elementType == elementType &&
      other.index == index;

  @override
  int get hashCode => Object.hash(chartType, elementType, index);
}

class ChartElementOverrides {
  const ChartElementOverrides([this.values = const {}]);

  final Map<ChartElementStyleKey, ChartElementStyleOverride> values;

  ChartElementStyleOverride resolve({
    required ChartType chartType,
    required ChartElementType elementType,
    int? index,
  }) {
    final global =
        values[ChartElementStyleKey(
          chartType: chartType,
          elementType: elementType,
        )] ??
        const ChartElementStyleOverride();
    if (index == null) return global;
    return global.merge(
      values[ChartElementStyleKey(
        chartType: chartType,
        elementType: elementType,
        index: index,
      )],
    );
  }

  ChartElementOverrides update({
    required ChartType chartType,
    required ChartElementType elementType,
    required int? index,
    required bool applyToAll,
    int? color,
    double? size,
    ChartFontWeight? fontWeight,
    ChartTextAlignment? alignment,
    bool? visible,
  }) {
    final updated = Map<ChartElementStyleKey, ChartElementStyleOverride>.of(
      values,
    );
    final target = ChartElementStyleKey(
      chartType: chartType,
      elementType: elementType,
      index: applyToAll ? null : index,
    );
    updated[target] = (updated[target] ?? const ChartElementStyleOverride())
        .copyWith(
          color: color,
          size: size,
          fontWeight: fontWeight,
          alignment: alignment,
          visible: visible,
        );

    if (applyToAll) {
      for (final key in updated.keys.toList()) {
        if (key.chartType != chartType ||
            key.elementType != elementType ||
            key.index == null) {
          continue;
        }
        final cleared = updated[key]!.copyWith(
          clearColor: color != null,
          clearSize: size != null,
          clearFontWeight: fontWeight != null,
          clearAlignment: alignment != null,
          clearVisible: visible != null,
        );
        if (cleared.isEmpty) {
          updated.remove(key);
        } else {
          updated[key] = cleared;
        }
      }
    }

    return ChartElementOverrides(Map.unmodifiable(updated));
  }
}
