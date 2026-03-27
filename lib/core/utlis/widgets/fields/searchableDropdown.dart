import 'package:flutter/material.dart';

class SearchableDropdown extends StatefulWidget {
  final List<String> data;
  final ValueChanged<String> onSelect;
  final String placeholder;
  final String? value;
  final BoxDecoration? containerDecoration;
  final InputDecoration? inputDecoration;
  final TextStyle? textStyle;
  final double? maxHeight;
  final bool allowAddNew; // 🔥 NEW

  const SearchableDropdown({
    super.key,
    required this.data,
    required this.onSelect,
    this.placeholder = "Search...",
    this.value,
    this.containerDecoration,
    this.inputDecoration,
    this.textStyle,
    this.maxHeight = 180,
    this.allowAddNew =true
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  final LayerLink _layerLink = LayerLink();

  List<String> _filteredData = [];
  List<String> _localData = [];

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();

    _localData = List.from(widget.data);
    _filteredData = _localData;

    if (widget.value != null && widget.value!.isNotEmpty) {
      _controller.text = widget.value!;
    }

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showDropdown();
      } else {
        _hideDropdown();
      }
    });
  }

  @override
  void didUpdateWidget(SearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.data != oldWidget.data) {
      _localData = List.from(widget.data);
      _filteredData = _localData;
    }

    if (widget.value != oldWidget.value) {
      _controller.text = widget.value ?? '';
    }
  }

  void _showDropdown() {
    if (_overlayEntry != null) return;

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _focusNode.unfocus(),
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: _layerLink,
                  offset: Offset(0, size.height),
                  showWhenUnlinked: false,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: size.width,
                      constraints: BoxConstraints(
                        maxHeight: widget.maxHeight ?? 180,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _buildDropdown(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }
  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _filter(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredData = _localData;
      } else {
        _filteredData = _localData
            .where(
              (item) => item.toLowerCase().contains(query.toLowerCase()),
        )
            .toList();
      }
    });

    _overlayEntry?.markNeedsBuild();
  }

  void _select(String value) {
    _controller.text = value;
    widget.onSelect(value);

    _focusNode.unfocus();
    _hideDropdown();
  }

  void _addNew() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    if (!_localData.contains(text)) {
      _localData.add(text);
    }

    _select(text);
  }
  Widget _buildDropdown() {
    final text = _controller.text.trim();

    final hasExactMatch =
    _localData.any((item) => item.toLowerCase() == text.toLowerCase());

    final showAddOption =
        widget.allowAddNew && text.isNotEmpty && !hasExactMatch;

    final totalItems = _filteredData.length + (showAddOption ? 1 : 0);

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (showAddOption && index == 0) {
          return ListTile(
            dense: true,
            title: Text(
              'Add "$text"',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).primaryColor,
              ),
            ),
            onTap: _addNew,
          );
        }

        final itemIndex = showAddOption ? index - 1 : index;
        final value = _filteredData[itemIndex];

        return ListTile(
          dense: true,
          title: Text(
            value,
            style: widget.textStyle ??
                const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF124559),
                ),
          ),
          onTap: () => _select(value),
        );
      },
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _hideDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: widget.containerDecoration ??
            BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF197278),
              ),
            ),
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _filter,
          style: widget.textStyle ?? const TextStyle(fontSize: 15),
          decoration: widget.inputDecoration ??
              InputDecoration(
                hintText: widget.placeholder,
                hintStyle: const TextStyle(color: Colors.grey),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: InputBorder.none,
              ),
        ),
      ),
    );
  }
}