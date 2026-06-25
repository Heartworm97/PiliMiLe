import 'package:PiliMiLe/common/widgets/loading_widget/http_error.dart';
import 'package:PiliMiLe/common/widgets/loading_widget/m3e_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:material_new_shapes/material_new_shapes.dart';

final Widget m3eLoading = Center(
  child: M3ELoadingIndicator(
    morphs: [
      Morph(MaterialShapes.softBurst, MaterialShapes.softBurst),
    ],
  ),
);

const Widget linearLoading = SliverToBoxAdapter(
  child: LinearProgressIndicator(),
);

const Widget scrollableError = CustomScrollView(slivers: [HttpError()]);

Widget scrollErrorWidget({
  String? errMsg,
  VoidCallback? onReload,
  ScrollController? controller,
}) => CustomScrollView(
  controller: controller,
  slivers: [
    HttpError(
      errMsg: errMsg,
      onReload: onReload,
    ),
  ],
);
