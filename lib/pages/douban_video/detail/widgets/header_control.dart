import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoubanVideoHeaderControl extends StatelessWidget {
  const DoubanVideoHeaderControl({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 8,
        right: 8,
        bottom: 8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
