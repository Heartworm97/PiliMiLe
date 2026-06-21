import 'package:PiliPlus/common/widgets/pair.dart';
import 'package:PiliPlus/common/widgets/reorder_mixin.dart';
import 'package:PiliPlus/models/common/enum_with_label.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class BarSetPage extends StatefulWidget {
  const BarSetPage({super.key});

  @override
  State<BarSetPage> createState() => _BarSetPageState();
}

class _BarSetPageState extends State<BarSetPage> with ReorderMixin {
  late final String key;
  late final String title;
  late final List<Pair<EnumWithLabel, bool>> list;

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic> args = Get.arguments;
    key = args['key'];
    title = args['title'];
    final defaultDisabled = args['defaultDisabledIndices'] as Set<int>? ?? const {};
    final defaultBars = args['defaultBars'] as List<EnumWithLabel>;
    final raw = GStorage.setting.get(key);
    List<int>? orderList;
    Set<int>? disabledSet;
    if (raw is Map) {
      orderList = (raw['order'] as List?)?.cast<int>();
      disabledSet = (raw['disabled'] as List?)?.cast<int>().toSet();
    } else if (raw is List) {
      orderList = raw.cast<int>();
    }
    list = defaultBars
        .map((e) => Pair(
            first: e,
            second: disabledSet != null
                ? !disabledSet.contains(e.index)
                : (orderList?.contains(e.index) ?? !defaultDisabled.contains(e.index))))
        .toList();
    if (orderList != null && orderList.isNotEmpty) {
      final cacheIndex = {for (final (k, v) in orderList.indexed) v: k};
      list.sort((a, b) {
        final idxA = cacheIndex[a.first.index];
        final idxB = cacheIndex[b.first.index];
        if (idxA != null && idxB != null) return idxA.compareTo(idxB);
        if (idxA == null && idxB == null) return 0;
        return idxA != null ? -1 : 1;
      });
    }
  }

  void saveEdit() {
    GStorage.setting.put(
      key,
      {
        'order': list.map((e) => e.first.index).toList(),
        'disabled': list.where((e) => !e.second).map((e) => e.first.index).toList(),
      },
    );
    SmartDialog.showToast('保存成功，下次启动时生效');
  }

  void onReset() {
    Get.back();
    GStorage.setting.delete(key);
    SmartDialog.showToast('重置成功，下次启动时生效');
  }

  void onReorderItem(int oldIndex, int newIndex) {
    list.insert(newIndex, list.removeAt(oldIndex));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('$title编辑'),
        actions: [
          TextButton(onPressed: onReset, child: const Text('重置')),
          TextButton(onPressed: saveEdit, child: const Text('保存')),
          const SizedBox(width: 12),
        ],
      ),
      body: ReorderableListView(
        onReorderItem: onReorderItem,
        proxyDecorator: proxyDecorator,
        footer: Padding(
          padding:
              MediaQuery.viewPaddingOf(context).copyWith(top: 0, left: 0) +
              const EdgeInsets.only(right: 34, top: 10),
          child: const Align(
            alignment: Alignment.centerRight,
            child: Text('*长按拖动排序'),
          ),
        ),
        children: list
            .map(
              (e) => CheckboxListTile(
                key: ValueKey(e.hashCode),
                value: e.second,
                onChanged: (bool? value) {
                  e.second = value!;
                  setState(() {});
                },
                title: Text(e.first.label),
                secondary: const Icon(Icons.drag_indicator_rounded),
              ),
            )
            .toList(),
      ),
    );
  }
}
