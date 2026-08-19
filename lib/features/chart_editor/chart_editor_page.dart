import 'package:flutter/material.dart';

import '../export/chart_export_service.dart';
import 'models/chart_data.dart';
import 'models/chart_selection.dart';
import 'models/chart_sort_order.dart';
import 'models/chart_style.dart';
import 'models/chart_type.dart';
import 'models/chart_type_styles.dart';
import 'widgets/bar_chart_preview.dart';
import 'widgets/line_chart_preview.dart';
import 'widgets/pie_chart_preview.dart';

class ChartEditorPage extends StatefulWidget {
  const ChartEditorPage({super.key, required this.data, this.exportService});

  final ChartData data;
  final ChartExportService? exportService;

  @override
  State<ChartEditorPage> createState() => _ChartEditorPageState();
}

class _ChartEditorPageState extends State<ChartEditorPage> {
  ChartStyle _style = const ChartStyle();
  ChartTypeStyles _typeStyles = const ChartTypeStyles();
  ChartType _selectedType = ChartType.bar;
  ChartSortOrder _sortOrder = ChartSortOrder.original;
  ChartSelection? _selection;
  bool _isFreeMode = false;
  bool _hasShownFreeModeHint = false;
  bool _showAdvancedOptions = false;
  final GlobalKey _exportBoundaryKey = GlobalKey();
  late final ChartExportService _exportService;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _exportService = widget.exportService ?? ChartExportService();
  }

  Future<void> _exportChart() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      await _exportService.export(
        boundaryKey: _exportBoundaryKey,
        fileName: ChartExportService.createFileName(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gráfico exportado com sucesso.')),
      );
    } on ChartExportCancelled {
      // Cancelar o seletor nativo não é uma falha e não exige mensagem.
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível exportar o gráfico.')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _updateStyle(ChartStyle style) {
    setState(() => _style = style);
  }

  void _updateTypeStyles(ChartTypeStyles styles) {
    setState(() => _typeStyles = styles);
  }

  Widget _buildPreview() {
    final sortedData = _sortOrder.applyTo(widget.data);
    final selection = _isExporting ? null : _selection;
    final freeMode = _isFreeMode && !_isExporting;
    return switch (_selectedType) {
      ChartType.bar => BarChartPreview(
        data: sortedData,
        style: _style,
        barStyle: _typeStyles,
        freeMode: freeMode,
        selection: selection,
        onSelectionChanged: _selectElement,
        onClearSelection: _clearSelection,
      ),
      ChartType.line => LineChartPreview(
        data: sortedData,
        style: _style,
        lineStyle: _typeStyles,
        freeMode: freeMode,
        selection: selection,
        onSelectionChanged: _selectElement,
        onClearSelection: _clearSelection,
      ),
      ChartType.pie => PieChartPreview(
        data: sortedData,
        style: _style,
        pieStyle: _typeStyles,
        freeMode: freeMode,
        selection: selection,
        onSelectionChanged: _selectElement,
        onClearSelection: _clearSelection,
      ),
    };
  }

  void _selectElement(ChartSelection selection) {
    if (!_isFreeMode) return;
    setState(() => _selection = selection);
  }

  void _clearSelection() {
    if (_selection != null) setState(() => _selection = null);
  }

  void _setFreeMode(bool enabled) {
    setState(() {
      _isFreeMode = enabled;
      if (!enabled) _selection = null;
    });
    if (enabled && !_hasShownFreeModeHint) {
      _hasShownFreeModeHint = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toque em um elemento do gráfico para editá-lo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        leadingWidth: 96,
        leading: TextButton.icon(
          key: const ValueKey('back-to-data'),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left_rounded, size: 24),
          label: const Text('Dados'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF555555),
            padding: const EdgeInsets.only(left: 16, right: 8),
          ),
        ),
        title: const Text(
          'Gráfico',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(
              key: const ValueKey('export-chart'),
              onPressed: _isExporting ? null : _exportChart,
              style: FilledButton.styleFrom(
                minimumSize: const Size(84, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isExporting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Exportar'),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RepaintBoundary(
                key: _exportBoundaryKey,
                child: ColoredBox(
                  key: const ValueKey('chart-export-canvas'),
                  color: Colors.white,
                  child: SizedBox(height: 300, child: _buildPreview()),
                ),
              ),
              if (_selection != null) ...[
                const SizedBox(height: 12),
                _SelectionPanel(
                  selection: _selection!,
                  onClose: _clearSelection,
                ),
              ],
              const SizedBox(height: 24),
              _ChartTypeSelector(
                selectedType: _selectedType,
                onSelected: (type) => setState(() {
                  _selectedType = type;
                  _selection = null;
                }),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                key: const ValueKey('free-mode-switch'),
                title: const Text(
                  'Modo livre',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Toque nos elementos para selecioná-los'),
                value: _isFreeMode,
                onChanged: _setFreeMode,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              const SizedBox(height: 24),
              Text(
                'TÍTULO',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF999999),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const ValueKey('chart-title-field'),
                initialValue: _style.title,
                onChanged: (value) =>
                    _updateStyle(_style.copyWith(title: value)),
                hintLocales: const [Locale('pt', 'BR')],
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFFAFAFA),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF777777)),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
              ),
              if (_selectedType != ChartType.pie) ...[
                const SizedBox(height: 24),
                Text(
                  'COR PRINCIPAL',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF999999),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _ColorPalette(
                  selectedColor: _style.primaryColor,
                  onSelected: (color) =>
                      _updateStyle(_style.copyWith(primaryColor: color)),
                ),
              ],
              const SizedBox(height: 18),
              TextButton.icon(
                key: const ValueKey('more-options'),
                onPressed: () => setState(
                  () => _showAdvancedOptions = !_showAdvancedOptions,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF555555),
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(48),
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(
                  _showAdvancedOptions
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                label: const Text('Mais opções'),
              ),
              if (_showAdvancedOptions)
                _AdvancedOptions(
                  style: _style,
                  typeStyles: _typeStyles,
                  chartType: _selectedType,
                  sortOrder: _sortOrder,
                  onStyleChanged: _updateStyle,
                  onTypeStylesChanged: _updateTypeStyles,
                  onSortOrderChanged: (order) =>
                      setState(() => _sortOrder = order),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({required this.selection, required this.onClose});

  final ChartSelection selection;
  final VoidCallback onClose;

  String get _elementLabel => switch (selection.elementType) {
    ChartElementType.title => 'Título do gráfico',
    ChartElementType.dataElement => switch (selection.chartType) {
      ChartType.bar => 'Barra selecionada',
      ChartType.line => 'Ponto selecionado',
      ChartType.pie => 'Fatia selecionada',
    },
    ChartElementType.xAxisLabel => 'Label selecionado',
    ChartElementType.legendItem => 'Item da legenda selecionado',
  };

  String _formatValue(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('selection-panel'),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: const Color(0xFFD8D8D8)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _elementLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (selection.category != null)
                  Text('Categoria: ${selection.category}'),
                if (selection.value != null)
                  Text('Valor: ${_formatValue(selection.value!)}'),
              ],
            ),
          ),
          TextButton(
            key: const ValueKey('close-selection'),
            onPressed: onClose,
            child: const Text('Fechar seleção'),
          ),
        ],
      ),
    );
  }
}

class _ColorPalette extends StatelessWidget {
  const _ColorPalette({required this.selectedColor, required this.onSelected});

  static const colors = [
    0xFF171717,
    0xFF2563EB,
    0xFF0F766E,
    0xFF7C3AED,
    0xFFDC5A3A,
  ];

  final int selectedColor;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var index = 0; index < colors.length; index++)
          Semantics(
            label: 'Cor ${index + 1}',
            selected: selectedColor == colors[index],
            button: true,
            child: InkWell(
              key: ValueKey('chart-color-$index'),
              onTap: () => onSelected(colors[index]),
              customBorder: const CircleBorder(),
              child: Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColor == colors[index]
                        ? const Color(0xFF171717)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(colors[index]),
                    shape: BoxShape.circle,
                  ),
                  child: selectedColor == colors[index]
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdvancedOptions extends StatelessWidget {
  const _AdvancedOptions({
    required this.style,
    required this.typeStyles,
    required this.chartType,
    required this.sortOrder,
    required this.onStyleChanged,
    required this.onTypeStylesChanged,
    required this.onSortOrderChanged,
  });

  final ChartStyle style;
  final ChartTypeStyles typeStyles;
  final ChartType chartType;
  final ChartSortOrder sortOrder;
  final ValueChanged<ChartStyle> onStyleChanged;
  final ValueChanged<ChartTypeStyles> onTypeStylesChanged;
  final ValueChanged<ChartSortOrder> onSortOrderChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('advanced-options'),
      color: const Color(0xFFFAFAFA),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Column(
          children: [
            _OptionSwitch(
              key: const ValueKey('show-title'),
              label: 'Mostrar título',
              value: style.showTitle,
              onChanged: (value) =>
                  onStyleChanged(style.copyWith(showTitle: value)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tamanho do título'),
                      Text(
                        style.titleSize.round().toString(),
                        key: const ValueKey('title-size-value'),
                        style: const TextStyle(color: Color(0xFF777777)),
                      ),
                    ],
                  ),
                  Slider(
                    key: const ValueKey('title-size-slider'),
                    min: 14,
                    max: 28,
                    divisions: 14,
                    value: style.titleSize,
                    onChanged: (value) =>
                        onStyleChanged(style.copyWith(titleSize: value)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
              child: DropdownButtonFormField<ChartSortOrder>(
                key: const ValueKey('category-sort-order'),
                initialValue: sortOrder,
                decoration: const InputDecoration(
                  labelText: 'Ordenar categorias',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: [
                  for (final order in ChartSortOrder.values)
                    DropdownMenuItem(value: order, child: Text(order.label)),
                ],
                onChanged: (order) {
                  if (order != null) onSortOrderChanged(order);
                },
              ),
            ),
            if (chartType == ChartType.bar)
              _SpecificSlider(
                label: 'Largura das barras',
                sliderKey: const ValueKey('bar-width-slider'),
                min: 8,
                max: 36,
                divisions: 28,
                value: typeStyles.barWidth,
                onChanged: (value) =>
                    onTypeStylesChanged(typeStyles.copyWith(barWidth: value)),
              ),
            if (chartType == ChartType.line)
              _SpecificSlider(
                label: 'Espessura da linha',
                sliderKey: const ValueKey('line-width-slider'),
                min: 1,
                max: 8,
                divisions: 7,
                value: typeStyles.lineWidth,
                onChanged: (value) =>
                    onTypeStylesChanged(typeStyles.copyWith(lineWidth: value)),
              ),
            if (chartType == ChartType.pie)
              _SpecificSlider(
                label: 'Tamanho do furo central',
                sliderKey: const ValueKey('pie-hole-slider'),
                min: 0,
                max: 70,
                divisions: 14,
                value: typeStyles.pieHolePercent,
                onChanged: (value) => onTypeStylesChanged(
                  typeStyles.copyWith(pieHolePercent: value),
                ),
              ),
            _OptionSwitch(
              key: const ValueKey('show-values'),
              label: 'Mostrar valores',
              value: style.showValues,
              onChanged: (value) =>
                  onStyleChanged(style.copyWith(showValues: value)),
            ),
            if (chartType != ChartType.pie) ...[
              _OptionSwitch(
                key: const ValueKey('show-grid'),
                label: 'Mostrar grade',
                value: style.showGrid,
                onChanged: (value) =>
                    onStyleChanged(style.copyWith(showGrid: value)),
              ),
              _OptionSwitch(
                key: const ValueKey('show-x-axis'),
                label: 'Mostrar eixo X',
                value: style.showXAxis,
                onChanged: (value) =>
                    onStyleChanged(style.copyWith(showXAxis: value)),
              ),
              _OptionSwitch(
                key: const ValueKey('show-y-axis'),
                label: 'Mostrar eixo Y',
                value: style.showYAxis,
                onChanged: (value) =>
                    onStyleChanged(style.copyWith(showYAxis: value)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SpecificSlider extends StatelessWidget {
  const _SpecificSlider({
    required this.label,
    required this.sliderKey,
    required this.min,
    required this.max,
    required this.divisions,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Key sliderKey;
  final double min;
  final double max;
  final int divisions;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label),
          Slider(
            key: sliderKey,
            min: min,
            max: max,
            divisions: divisions,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _OptionSwitch extends StatelessWidget {
  const _OptionSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ChartTypeSelector extends StatelessWidget {
  const _ChartTypeSelector({
    required this.selectedType,
    required this.onSelected,
  });

  final ChartType selectedType;
  final ValueChanged<ChartType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'TIPO DE GRÁFICO',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF999999),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ChartTypeButton(
                key: const ValueKey('chart-type-bars'),
                icon: Icons.bar_chart_rounded,
                label: 'Barras',
                selected: selectedType == ChartType.bar,
                onPressed: () => onSelected(ChartType.bar),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChartTypeButton(
                key: const ValueKey('chart-type-lines'),
                icon: Icons.show_chart_rounded,
                label: 'Linhas',
                selected: selectedType == ChartType.line,
                onPressed: () => onSelected(ChartType.line),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ChartTypeButton(
                key: const ValueKey('chart-type-pie'),
                icon: Icons.pie_chart_outline_rounded,
                label: 'Pizza',
                selected: selectedType == ChartType.pie,
                onPressed: () => onSelected(ChartType.pie),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartTypeButton extends StatelessWidget {
  const _ChartTypeButton({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? Colors.white : const Color(0xFF999999),
          backgroundColor: selected ? const Color(0xFF171717) : Colors.white,
          disabledForegroundColor: const Color(0xFF999999),
          side: BorderSide(
            color: selected ? const Color(0xFF171717) : const Color(0xFFDDDDDD),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
