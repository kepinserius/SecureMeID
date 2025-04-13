import 'package:flutter/material.dart';
import 'package:secureme_id/utils/app_theme.dart';
import 'dart:async';

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

class _PinInputState extends State<PinInput>
    with SingleTickerProviderStateMixin {
  late List<String> _pin;
  final _focusNode = FocusNode();
  final _textEditingController = TextEditingController();

  // Animation controller for error shake animation
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  // Timers for visibility
  List<Timer?> _visibilityTimers = [];
  List<bool> _obscurePins = [];

  // Error state
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _pin = List.filled(widget.pinLength, '');
    _obscurePins = List.filled(widget.pinLength, true);
    _visibilityTimers = List.filled(widget.pinLength, null);

    // Initialize animation controller for error shake
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.05, 0.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticIn,
    ));

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    _animationController.dispose();

    // Cancel all timers
    for (var timer in _visibilityTimers) {
      timer?.cancel();
    }

    super.dispose();
  }

  // Trigger error animation
  void _triggerErrorAnimation() {
    setState(() {
      _hasError = true;
    });
    _animationController.forward();

    // Reset error state after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _hasError = false;
        });
      }
    });
  }

  // Handle input changes
  void _handleKeyInput(String value) {
    if (value.length > _pin.join().length) {
      // New character was added
      final digit = value.substring(value.length - 1);

      // Validate input is a digit
      if (!RegExp(r'[0-9]').hasMatch(digit)) {
        _triggerErrorAnimation();
        return;
      }

      // Find the first empty position
      final emptyIndex = _pin.indexWhere((element) => element.isEmpty);
      if (emptyIndex != -1) {
        setState(() {
          _pin[emptyIndex] = digit;

          // Set timer to obscure the pin after a brief visibility
          if (widget.obscureText) {
            _obscurePins[emptyIndex] = false;
            _visibilityTimers[emptyIndex]?.cancel();
            _visibilityTimers[emptyIndex] =
                Timer(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _obscurePins[emptyIndex] = true;
                });
              }
            });
          }
        });

        // Notify of change
        widget.onChanged(_pin.join());

        // Check if PIN is complete
        if (!_pin.contains('')) {
          widget.onCompleted(_pin.join());
        }
      }
    } else if (value.length < _pin.join().length) {
      // Character was removed
      final lastFilledIndex =
          _pin.lastIndexWhere((element) => element.isNotEmpty);
      if (lastFilledIndex != -1) {
        setState(() {
          _pin[lastFilledIndex] = '';
          _obscurePins[lastFilledIndex] = true;
          _visibilityTimers[lastFilledIndex]?.cancel();
        });

        // Notify of change
        widget.onChanged(_pin.join());
      }
    }
  }

  // Clear all values
  void _clear() {
    setState(() {
      _pin = List.filled(widget.pinLength, '');
      _textEditingController.clear();
      for (var i = 0; i < _visibilityTimers.length; i++) {
        _visibilityTimers[i]?.cancel();
        _obscurePins[i] = true;
      }
    });
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isPinComplete = !_pin.contains('');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hidden text field to capture input
        Opacity(
          opacity: 0,
          child: TextField(
            controller: _textEditingController,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            onChanged: _handleKeyInput,
            maxLength: widget.pinLength * 2, // Extra buffer for input
          ),
        ),

        // Visual PIN display
        GestureDetector(
          onTap: () {
            _focusNode.requestFocus();
          },
          child: SlideTransition(
            position: _animation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                color: _hasError
                    ? AppTheme.errorColor.withValues(alpha: 0.1)
                    : brightness == Brightness.light
                        ? Colors.white
                        : const Color(0xFF111827).withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.pinLength,
                  (index) => Container(
                    width: 45,
                    height: 55,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      border: Border.all(
                        color: _hasError
                            ? AppTheme.errorColor
                            : _pin[index].isNotEmpty
                                ? AppTheme.primaryColor
                                : brightness == Brightness.light
                                    ? const Color(0xFFE5E7EB)
                                    : const Color(0xFF374151),
                        width: _pin[index].isNotEmpty ? 2 : 1.5,
                      ),
                      color: _pin[index].isNotEmpty
                          ? AppTheme.primaryColor.withValues(alpha: 0.08)
                          : brightness == Brightness.light
                              ? Colors.grey.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: _pin[index].isNotEmpty
                          ? widget.obscureText && _obscurePins[index]
                              ? Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: brightness == Brightness.light
                                        ? AppTheme.textPrimaryColor
                                        : Colors.white,
                                  ),
                                )
                              : Text(
                                  _pin[index],
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: brightness == Brightness.light
                                        ? AppTheme.textPrimaryColor
                                        : Colors.white,
                                  ),
                                )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Extra controls
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isPinComplete) ...[
                Text(
                  'Enter your PIN code',
                  style: TextStyle(
                    color: brightness == Brightness.light
                        ? AppTheme.textSecondaryColor
                        : Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ] else ...[
                TextButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
