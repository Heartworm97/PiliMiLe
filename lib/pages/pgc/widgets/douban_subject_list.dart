import 'package:PiliMiLe/common/style.dart';
import 'package:PiliMiLe/common/widgets/loading_widget/http_error.dart';
import 'package:PiliMiLe/common/widgets/loading_widget/m3e_loading_indicator.dart';
import 'package:PiliMiLe/common/widgets/loading_widget/morphs.dart';
import 'package:PiliMiLe/http/douban.dart';
import 'package:PiliMiLe/http/loading_state.dart';
import 'package:PiliMiLe/models_new/douban/subject.dart';
import 'package:PiliMiLe/pages/pgc/widgets/douban_card.dart';
import 'package:PiliMiLe/services/logger.dart';
import 'package:PiliMiLe/utils/grid.dart';
import 'package:flutter/material.dart';

class DoubanSubjectListPage extends StatefulWidget {
  const DoubanSubjectListPage({
    super.key,
    required this.title,
    required this.kind,
    required this.params,
  });

  final String title;
  final String kind;
  final Map<String, dynamic> params;

  @override
  State<DoubanSubjectListPage> createState() => _DoubanSubjectListPageState();
}

class _DoubanSubjectListPageState extends State<DoubanSubjectListPage> {
  late LoadingState<List<DoubanSubject>> _state = LoadingState.loading();
  final List<DoubanSubject> _items = [];
  int _page = 0;
  bool _isEnd = false;
  bool _loading = false;
  final _scrollController = ScrollController();

  /// 初始加载至少播放一整轮（7 个形态变换），避免转圈一闪而过
  int _morphCount = 0;
  late final _randomMorphs = Morphs.randomMorphs();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_loading || _isEnd) return;
    _loading = true;
    try {
      final res = await DoubanHttp.dio.get(
        '/rexxar/api/v2/subject/recent_hot/${widget.kind}',
        queryParameters: {
          'start': _page * 20,
          'limit': 20,
          ...widget.params,
        },
      );
      if (res.statusCode == 200) {
        final data = DoubanHotResponse.fromJson(
          res.data is Map<String, dynamic>
              ? res.data as Map<String, dynamic>
              : {},
        );
        _items.addAll(data.items);
        _state = Success(_items);
        if (data.items.length < 20 || _items.length >= data.total) {
          _isEnd = true;
        }
        _page++;
      } else {
        if (_items.isEmpty) {
          _state = const Error('请求失败');
        }
      }
    } catch (e) {
      logger.e('豆瓣加载失败: $e');
      if (_items.isEmpty) {
        _state = Error(e.toString());
      }
    }
    _loading = false;
    if (context.mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    final gridDelegate = SliverGridDelegateWithExtentAndRatio(
      mainAxisSpacing: Style.cardSpace,
      crossAxisSpacing: Style.cardSpace,
      maxCrossAxisExtent: Grid.smallCardWidth * 0.6,
      childAspectRatio: 0.75,
      mainAxisExtent: MediaQuery.textScalerOf(context).scale(50),
    );

    if (_morphCount < 7 || _state is Loading) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: M3ELoadingIndicator(
            morphs: _randomMorphs,
            morphDuration: 2000,
            onMorphCompleted: () {
              _morphCount++;
              if (mounted) setState(() {});
            },
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(widget.title)),
      body: switch (_state) {
        Success() when _items.isEmpty => HttpError(onReload: _loadData),
        Success() => CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  left: Style.safeSpace,
                  right: Style.safeSpace,
                  top: 12,
                  bottom: padding.bottom + 100,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: gridDelegate,
                  itemBuilder: (context, index) {
                    if (index == _items.length - 1) {
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _loadData());
                    }
                    return DoubanCard(item: _items[index]);
                  },
                  itemCount: _items.length,
                ),
              ),
            ],
          ),
        Error(:final errMsg) => HttpError(
            errMsg: errMsg,
            onReload: _loadData,
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
