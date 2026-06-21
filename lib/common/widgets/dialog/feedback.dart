import 'package:PiliPlus/common/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.child,
    this.onPressed,
    this.primary = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: primary
          ? colorScheme.primary.withAlpha(25)
          : colorScheme.onSurface.withAlpha(12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 13,
              fontWeight: primary ? FontWeight.w600 : FontWeight.w500,
              color: primary ? colorScheme.primary : colorScheme.outline,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

void showFeedbackDialog(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final controller = TextEditingController();

  void onSubmit() {
    final text = controller.text.trim();
    if (text.isEmpty) {
      SmartDialog.showToast('请输入反馈内容');
      return;
    }
    Get.back();
    // TODO: 接入反馈 API
    SmartDialog.showToast('感谢您的反馈！');
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      constraints: Style.dialogFixedConstraints,
      title: Row(
        children: [
          Icon(Icons.feedback_outlined, size: 24, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Text('问题反馈'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, color: colorScheme.outline.withAlpha(30)),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: '请输入您的问题或建议...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withAlpha(100),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '感谢您的反馈，我们会尽快处理！',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary.withAlpha(180),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _SmallButton(
              onPressed: Get.back,
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            _SmallButton(
              onPressed: onSubmit,
              primary: true,
              child: const Text('提交'),
            ),
          ],
        ),
      ],
    ),
  );
}
