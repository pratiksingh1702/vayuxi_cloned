// widgets/searchable_dropdown.dart
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

  const SearchableDropdown({
    super.key,
    required this.data,
    required this.onSelect,
    this.placeholder = "Search...",
    this.value,
    this.containerDecoration,
    this.inputDecoration,
    this.textStyle,
    this.maxHeight = 150,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  List<String> _filteredData = [];
  List<String> _localData = [];
  bool _showDropdown = false;
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
        _showDropdownWidget();
        setState(() {
          _showDropdown = true;
        });
      } else {
        _hideDropdownWidget();
        setState(() {
          _showDropdown = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(SearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller.text = widget.value ?? '';
    }
    if (widget.data != oldWidget.data) {
      _localData = List.from(widget.data);
      _filteredData = _localData;
    }
  }

  void _showDropdownWidget() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 5,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: widget.maxHeight ?? 150,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _buildDropdownContent(),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdownWidget() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _filterData(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredData = _localData;
      } else {
        _filteredData = _localData
            .where((item) =>
            item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });

    // Update overlay if it's showing
    if (_showDropdown && _overlayEntry != null) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _handleSelect(String value) {
    _controller.text = value;
    widget.onSelect(value);
    _focusNode.unfocus();
    _hideDropdownWidget();
    setState(() {
      _showDropdown = false;
    });
  }

  void _handleAddNew() {
    final newItem = _controller.text.trim();
    if (newItem.isNotEmpty && !_localData.contains(newItem)) {
      setState(() {
        _localData.add(newItem);
      });
    }
    _handleSelect(newItem);
  }

  Widget _buildDropdownContent() {
    if (_filteredData.isEmpty && _controller.text.trim().isNotEmpty) {
      return ListTile(
        title: Text(
          'Add "${_controller.text}"',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).primaryColor,
          ),
        ),
        onTap: _handleAddNew,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: _filteredData.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            _filteredData[index],
            style: widget.textStyle ??
                const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF124559),
                ),
          ),
          onTap: () => _handleSelect(_filteredData[index]),
        );
      },
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _hideDropdownWidget();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.containerDecoration ??
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF197278),
              width: 1,
            ),
          ),
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _filterData,
        style: widget.textStyle ??
            const TextStyle(
              fontSize: 16,
            ),
        decoration: widget.inputDecoration ??
            InputDecoration(
              hintText: widget.placeholder,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
      ),
    );
  }
}