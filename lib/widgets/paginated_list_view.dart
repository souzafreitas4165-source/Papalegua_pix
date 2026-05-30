import 'package:flutter/material.dart';
import 'package:papaleguas_pix/models/paginated_response.dart';

class PaginatedListView<T> extends StatefulWidget {
  final Future<PaginatedResponse<T>> Function(int page) fetchItems;
  final Widget Function(T item, int index) itemBuilder;
  final Widget Function()? emptyBuilder;
  final Widget Function()? loadingBuilder;
  final Widget Function(String error)? errorBuilder;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final int itemsPerPage;
  final IconData? emptyStateIcon;
  final String? emptyStateTitle;
  final String? emptyStateMessage;
  final VoidCallback? emptyStateAction;
  final String? emptyStateActionLabel;

  const PaginatedListView({
    super.key,
    required this.fetchItems,
    required this.itemBuilder,
    this.emptyBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.padding,
    this.scrollController,
    this.shrinkWrap = false,
    this.physics,
    this.itemsPerPage = 10,
    this.emptyStateIcon,
    this.emptyStateTitle,
    this.emptyStateMessage,
    this.emptyStateAction,
    this.emptyStateActionLabel,
  });

  @override
  PaginatedListViewState<T> createState() => PaginatedListViewState<T>();
}

class PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || !_hasMore) return;

    final maxScroll = widget.scrollController!.position.maxScrollExtent;
    final currentScroll = widget.scrollController!.offset;
    final delta = MediaQuery.of(context).size.height * 0.2;

    if (currentScroll >= (maxScroll - delta)) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await widget.fetchItems(_currentPage);

      setState(() {
        _isLoading = false;
        _currentPage++;
        _hasMore = response.hasNext;
        _items.addAll(response.items);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> refresh() async {
    if (_isLoading) return;

    setState(() {
      _items.clear();
      _currentPage = 1;
      _hasMore = true;
      _error = null;
    });

    await _loadMore();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Ops! Algo deu errado.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty && !_isLoading) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.emptyStateIcon ?? Icons.inbox_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                widget.emptyStateTitle ?? 'Nenhum item encontrado',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.emptyStateMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.emptyStateMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              if (widget.emptyStateAction != null)
                ElevatedButton.icon(
                  onPressed: widget.emptyStateAction,
                  icon: const Icon(Icons.add),
                  label: Text(widget.emptyStateActionLabel ?? 'Adicionar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        controller: widget.scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics ??
            (_hasMore || _isLoading
                ? const AlwaysScrollableScrollPhysics()
                : const BouncingScrollPhysics()),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            if (!_isLoading) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Carregando mais itens...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return widget.itemBuilder(_items[index], index);
        },
      ),
    );
  }
}
