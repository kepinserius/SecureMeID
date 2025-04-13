import 'package:flutter/material.dart';
import 'package:secureme_id/utils/app_theme.dart';

class PinInput extends StatefulWidget {
  final Function(String) onCompleted;
  final Function(String) onChanged;
  final int pinLength;
  final bool obscureText;
  
  const PinInput({
    Key? key,
    required this.onCompleted,
    required this.onChanged,
    this.pinLength = 6,
    this.obscureText = true,
  }) : super(key: key);

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  late List<String> _pin;
  
  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.pinLength, (_) => TextEditingController());
    _focusNodes = List.generate(widget.pinLength, (_) => FocusNode());
    _pin = List.filled(widget.pinLength, '');
  }
  
  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
  
  void _onChanged(String value, int index) {
    if (value.isEmpty) {
      setState(() {
        _pin[index] = '';
      });
      
      // Move focus to previous field if not the first one
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    } else if (value.length == 1) {
      setState(() {
        _pin[index] = value;
      });
      
      // Move focus to next field if not the last one
      if (index < widget.pinLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // If last field is filled, trigger onCompleted
        final pin = _pin.join();
        if (pin.length == widget.pinLength) {
          widget.onCompleted(pin);
        }
      }
    }
    
    // Call onChanged with current pin
    widget.onChanged(_pin.join());
  }
  
  void _onKeyPressed(RawKeyEvent event, int index) {
    // Handle backspace
    if (event is RawKeyDownEvent && event.logicalKey.keyLabel == 'Backspace') {
      if (_pin[index].isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        setState(() {
          _pin[index - 1] = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.pinLength,
        (index) => Container(
          width: 40,
          height: 50,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            obscureText: widget.obscureText,
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _pin[index].isNotEmpty
                      ? AppTheme.primaryColor
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            onChanged: (value) => _onChanged(value, index),
            enableInteractiveSelection: false,
          ),
        ),
      ),
    );
  }
} 