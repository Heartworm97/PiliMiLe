import 'dart:math';

import 'package:material_new_shapes/material_new_shapes.dart';

abstract final class Morphs {
  static List<Morph> buildMorph(
    List<RoundedPolygon> shapes, {
    bool loop = true,
  }) {
    assert(shapes.length >= 2);
    return [
      for (var i = 0; i < shapes.length - 1; i++)
        Morph(shapes[i], shapes[i + 1]),
      if (loop) Morph(shapes[shapes.length - 1], shapes[0]),
    ];
  }

  static final _sourceShapes = [
    MaterialShapes.softBurst,
    MaterialShapes.cookie9Sided,
    MaterialShapes.pentagon,
    MaterialShapes.pill,
    MaterialShapes.sunny,
    MaterialShapes.cookie4Sided,
    MaterialShapes.oval,
    MaterialShapes.gem,
    MaterialShapes.flower,
    MaterialShapes.cookie12Sided,
  ];

  static final loadingMorphs = buildMorph([
    MaterialShapes.softBurst,
    MaterialShapes.cookie9Sided,
    MaterialShapes.pentagon,
    MaterialShapes.pill,
    MaterialShapes.sunny,
    MaterialShapes.cookie4Sided,
    MaterialShapes.oval,
  ]);

  /// 每次调用返回随机打乱顺序的 morph 列表，数量固定 4 个
  static List<Morph> randomMorphs() {
    final shuffled = List<RoundedPolygon>.of(_sourceShapes)..shuffle(Random());
    return buildMorph(shuffled.take(4).toList());
  }
}
