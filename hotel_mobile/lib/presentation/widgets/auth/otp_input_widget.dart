import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPInputWidget extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final bool autoFocus;
  final bool obscureText;
  final TextStyle? textStyle;
  final InputDecoration? decoration;
  final Color? cursorColor;
  final bool enabled;

  const OTPInputWidget({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.controller,
    this.autoFocus = true,
    this.obscureText = false,
    this.textStyle,
    this.decoration,
    this.cursorColor,
    this.enabled = true,
  }) : assert(length > 0);

  @override
  State<OTPInputWidget> createState() => _OTPInputWidgetState();
}

class _OTPInputWidgetState extends State<OTPInputWidget> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _textControllers;
  late TextEditingController _hiddenController;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _textControllers = List.generate(widget.length, (index) => TextEditingController());
    _hiddenController = widget.controller ?? TextEditingController();

    _hiddenController.addListener(_onHiddenControllerChanged);
  }

  @override
  void dispose() {
    _hiddenController.removeListener(_onHiddenControllerChanged);
    if (widget.controller == null) {
      _hiddenController.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _textControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onHiddenControllerChanged() {
    final text = _hiddenController.text;
    for (int i = 0; i < widget.length; i++) {
      _textControllers[i].text = i < text.length ? text[i] : '';
    }
    if (text.length == widget.length) {
      widget.onCompleted(text);
    }
    widget.onChanged?.call(text);
  }

  void _onKeyboardTap(String text) {
    final currentText = _hiddenController.text;
    if (text == 'DEL') {
      if (currentText.isNotEmpty) {
        _hiddenController.text = currentText.substring(0, currentText.length - 1);
      }
    } else if (currentText.length < widget.length) {
      _hiddenController.text = currentText + text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hidden TextField to capture all input
        SizedBox(
          width: 0,
          height: 0,
          child: TextField(
            controller: _hiddenController,
            autofocus: widget.autoFocus,
            keyboardType: TextInputType.number,
            maxLength: widget.length,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: widget.enabled,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
            style: const TextStyle(color: Colors.transparent),
            cursorColor: Colors.transparent,
            focusNode: _focusNodes[0], // Focus on the first node
            onChanged: (value) {
              if (value.length > widget.length) {
                _hiddenController.text = value.substring(0, widget.length);
              }
              _onHiddenControllerChanged();
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            if (widget.enabled) {
              FocusScope.of(context).requestFocus(_focusNodes[0]);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.length, (index) {
              return _buildOTPField(index);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPField(int index) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(
          color: _focusNodes[index].hasFocus
              ? Theme.of(context).primaryColor
              : Colors.grey.shade400,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _textControllers[index].text,
        style: widget.textStyle ??
            Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
      ),
    );
  }
}