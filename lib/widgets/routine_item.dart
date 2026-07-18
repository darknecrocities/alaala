import 'package:flutter/material.dart';
import 'custom_card.dart';

class RoutineItem extends StatefulWidget {
  const RoutineItem({
    super.key,
    required this.time,
    required this.title,
    required this.category,
    required this.color,
    required this.icon,
    required this.isInitialDone,
  });

  final String time;
  final String title;
  final String category;
  final Color color;
  final IconData icon;
  final bool isInitialDone;

  @override
  State<RoutineItem> createState() => _RoutineItemState();
}

class _RoutineItemState extends State<RoutineItem> {
  late bool _done;

  @override
  void initState() {
    super.initState();
    _done = widget.isInitialDone;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _done = !_done;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _done ? widget.color : Colors.transparent,
                  border: Border.all(
                    color: _done ? widget.color : widget.color.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: _done
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            CircleAvatar(
              backgroundColor: widget.color.withValues(alpha: 0.12),
              radius: 20,
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _done ? const Color(0xFF8B8276) : const Color(0xFF383229),
                      decoration: _done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.time} · ${widget.category}',
                    style: const TextStyle(
                      color: Color(0xFF6B6257),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
