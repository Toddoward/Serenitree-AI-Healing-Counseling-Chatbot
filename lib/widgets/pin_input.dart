import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinInputWidget extends StatefulWidget {
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final bool obscureText;
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final int pinLength;
  
  const PinInputWidget({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.obscureText = false,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.pinLength = 4,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _pin = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.pinLength, 
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.pinLength, 
      (index) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length == 1) {
      // 다음 필드로 포커스 이동
      if (index < widget.pinLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty) {
      // 이전 필드로 포커스 이동
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    // PIN 조합
    _pin = _controllers.map((controller) => controller.text).join();
    
    if (widget.onChanged != null) {
      widget.onChanged!(_pin);
    }

    // PIN이 완성되면 콜백 호출
    if (_pin.length == widget.pinLength) {
      widget.onCompleted(_pin);
    }
  }

  void clearPin() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _pin = '';
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.pinLength,
        (index) => Container(
          width: 60,
          height: 60,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ],
            obscureText: widget.obscureText,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: widget.fillColor ?? Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.borderColor ?? Colors.grey.shade300,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.focusedBorderColor ?? Colors.teal.shade600,
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: widget.borderColor ?? Colors.grey.shade300,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) => _onChanged(value, index),
          ),
        ),
      ),
    );
  }
}

class NumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onConfirmPressed;
  final bool showConfirmButton;
  final String confirmButtonText;

  const NumericKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
    this.onConfirmPressed,
    this.showConfirmButton = false,
    this.confirmButtonText = '확인',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 숫자 버튼들 (1-9)
          for (int row = 0; row < 3; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int col = 1; col <= 3; col++)
                    _buildNumberButton(
                      context,
                      (row * 3 + col).toString(),
                    ),
                ],
              ),
            ),
          
          // 0, 삭제 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (showConfirmButton && onConfirmPressed != null)
                _buildConfirmButton(context)
              else
                const SizedBox(width: 70),
              _buildNumberButton(context, '0'),
              _buildDeleteButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(BuildContext context, String number) {
    return Container(
      width: 70,
      height: 70,
      child: ElevatedButton(
        onPressed: () => onNumberPressed(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade600
                            : Colors.white,
          foregroundColor: Colors.grey.shade800,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          side: BorderSide(color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade800
                            : Colors.grey.shade200
                          ),
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      child: ElevatedButton(
        onPressed: onDeletePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade600
                            : Colors.red.shade50,
          foregroundColor: Colors.red.shade600,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          side: BorderSide(color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade800
                            : Colors.red.shade200),
        ),
        child: const Icon(
          Icons.backspace_outlined,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      child: ElevatedButton(
        onPressed: onConfirmPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade600,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
        ),
        child: const Icon(
          Icons.check,
          size: 24,
        ),
      ),
    );
  }
}