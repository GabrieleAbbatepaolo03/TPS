import 'package:flutter/material.dart';

class CustomSwitch extends StatefulWidget {
  final String leftLabel;
  final String rightLabel;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;
  final bool isLoginSelected;
  final ValueChanged<bool> onChanged;

  const CustomSwitch({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    required this.isLoginSelected,
    required this.onChanged,
  });

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch> {
  late bool isLeftSelected;

  @override
  void initState() {
    super.initState();
    isLeftSelected = widget.isLoginSelected;
  }

  @override
  void didUpdateWidget(covariant CustomSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoginSelected != oldWidget.isLoginSelected) {
      isLeftSelected = widget.isLoginSelected;
    }
  }

  void _toggle(bool selectLeft) {
    if (selectLeft != isLeftSelected) {
      setState(() => isLeftSelected = selectLeft);
      widget.onChanged(selectLeft);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: widget.secondaryColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final innerWidth = (constraints.maxWidth - 10) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                alignment: isLeftSelected
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Container(
                  width: innerWidth,
                  decoration: BoxDecoration(
                    color: widget.primaryColor,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _toggle(true),
                      child: Center(
                        child: Text(
                          widget.leftLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isLeftSelected
                                ? widget.textColor
                                : widget.textColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _toggle(false),
                      child: Center(
                        child: Text(
                          widget.rightLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !isLeftSelected
                                ? widget.textColor
                                : widget.textColor.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
