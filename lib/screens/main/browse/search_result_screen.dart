import 'package:flutter/material.dart';
import 'package:nekoflow/data/models/search_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:nekoflow/widgets/anime_card.dart';

class SearchResultScreen extends StatefulWidget {
  final SearchModel searchModel;
  final AnimeService animeService;
  final String searchType;

  const SearchResultScreen({
    super.key,
    required this.searchModel,
    required this.animeService,
    this.searchType = 'query',
  });

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  bool _isGridLayout = true;
  bool _isLoading = false;
  List<AnimeResult> _animeResults = [];
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    // Initialize with the initial search results
    _animeResults = widget.searchModel.animes;
    _currentPage = widget.searchModel.currentPage;
    _totalPages = widget.searchModel.totalPages;
  }

  Future<void> _loadPage(int page) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load results for the specified page
      SearchModel updatedSearchModel;
      if (widget.searchType == 'query') {
        updatedSearchModel = await widget.animeService
            .fetchByQuery(query: widget.searchModel.searchQuery, page: page);
      } else {
        // For genre search, transform the genre name back to original format
        final genreDetail = await widget.animeService
            .fetchGenreAnime(widget.searchModel.searchQuery, page: page);

        // Convert genre detail to search model
        updatedSearchModel = SearchModel(
          currentPage: genreDetail.data.currentPage,
          hasNextPage: genreDetail.data.hasNextPage,
          totalPages: genreDetail.data.totalPages,
          searchQuery: widget.searchModel.searchQuery,
          searchFilters: {},
          animes: genreDetail.data.animes
              .map((genreAnime) => AnimeResult(
                    id: genreAnime.id,
                    name: genreAnime.name,
                    poster: genreAnime.poster,
                    duration: genreAnime.duration,
                    type: genreAnime.type,
                    rating: genreAnime.rating,
                    episodes: genreAnime.episodes,
                  ))
              .toList(),
          mostPopularAnimes: [],
        );
      }

      setState(() {
        // Replace results with new page results
        _animeResults = updatedSearchModel.animes;
        _currentPage = updatedSearchModel.currentPage;
        _totalPages = updatedSearchModel.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show an error snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load page: $e')),
      );
    }
  }

  // Toggle layout method
  void _toggleLayout() {
    setState(() {
      _isGridLayout = !_isGridLayout;
    });
  }

  // Widget _buildFloatingPagination() {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
  //     child: Container(
  //       decoration: BoxDecoration(
  //           color: Theme.of(context).colorScheme.surface,
  //           borderRadius: BorderRadius.circular(100),
  //           boxShadow: [
  //             BoxShadow(
  //                 color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
  //                 blurRadius: 10,
  //                 spreadRadius: 0,
  //                 offset: Offset(0, -2))
  //           ]),
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //       child: Row(
  //         mainAxisSize: MainAxisSize.max,
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           // Previous Page Button
  //           IconButton(
  //             icon: Icon(Icons.arrow_back_ios, size: 20),
  //             color: _currentPage > 1
  //                 ? Theme.of(context).colorScheme.primary
  //                 : Colors.grey,
  //             onPressed:
  //                 _currentPage > 1 ? () => _loadPage(_currentPage - 1) : null,
  //           ),

  //           // Page Indicator with Animation
  //           AnimatedSwitcher(
  //             duration: Duration(milliseconds: 300),
  //             child: Text(
  //               '$_currentPage / $_totalPages',
  //               key: ValueKey(_currentPage),
  //               style: Theme.of(context).textTheme.titleMedium?.copyWith(
  //                   fontWeight: FontWeight.bold,
  //                   color: Theme.of(context).colorScheme.primary),
  //             ),
  //           ),

  //           // Next Page Button
  //           IconButton(
  //             icon: Icon(Icons.arrow_forward_ios, size: 20),
  //             color: _currentPage < _totalPages
  //                 ? Theme.of(context).colorScheme.primary
  //                 : Colors.grey,
  //             onPressed: _currentPage < _totalPages
  //                 ? () => _loadPage(_currentPage + 1)
  //                 : null,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildAdvancedPagination() {
    return Container(
      height: 100,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Previous Button
          ElevatedButton.icon(
            icon: Icon(Icons.chevron_left),
            label: Text('Previous'),
            onPressed:
                _currentPage > 1 ? () => _loadPage(_currentPage - 1) : null,
          ),

          // Page Jump Dropdown
          Expanded(
            child: Center(
              child: DropdownButton<int>(
                value: _currentPage,
                items: List.generate(
                    _totalPages,
                    (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('Page ${index + 1}'),
                        )),
                onChanged: (page) {
                  if (page != null) _loadPage(page);
                },
              ),
            ),
          ),

          // Next Button
          ElevatedButton.icon(
            icon: Text('Next'),
            label: Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () => _loadPage(_currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  // Widget _buildInputPagination() {
  //   final TextEditingController pageController =
  //       TextEditingController(text: _currentPage.toString());

  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 16),
  //     child: Row(
  //       children: [
  //         IconButton(
  //           icon: Icon(Icons.first_page),
  //           onPressed: _currentPage > 1 ? () => _loadPage(1) : null,
  //         ),
  //         IconButton(
  //           icon: Icon(Icons.chevron_left),
  //           onPressed:
  //               _currentPage > 1 ? () => _loadPage(_currentPage - 1) : null,
  //         ),
  //         Expanded(
  //           child: TextField(
  //             controller: pageController,
  //             keyboardType: TextInputType.number,
  //             textAlign: TextAlign.center,
  //             decoration: InputDecoration(
  //               labelText: 'Go to Page',
  //               border: OutlineInputBorder(),
  //             ),
  //             onSubmitted: (value) {
  //               int? page = int.tryParse(value);
  //               if (page != null && page > 0 && page <= _totalPages) {
  //                 _loadPage(page);
  //               } else {
  //                 // Show error
  //                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //                   content: Text('Invalid page number'),
  //                   backgroundColor: Colors.red,
  //                 ));
  //               }
  //             },
  //           ),
  //         ),
  //         IconButton(
  //           icon: Icon(Icons.chevron_right),
  //           onPressed: _currentPage < _totalPages
  //               ? () => _loadPage(_currentPage + 1)
  //               : null,
  //         ),
  //         IconButton(
  //           icon: Icon(Icons.last_page),
  //           onPressed: _currentPage < _totalPages
  //               ? () => _loadPage(_totalPages)
  //               : null,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.navigate_before,
            size: 30,
          ),
        ),
        title: Text(
          "Search Results for \"${widget.searchModel.searchQuery}\"",
          style: themeData.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          // Layout toggle button
          IconButton(
            icon: Icon(_isGridLayout ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleLayout,
            tooltip:
                _isGridLayout ? 'Switch to List View' : 'Switch to Grid View',
          ),
        ],
        titleSpacing: 0,
        forceMaterialTransparency: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total results and pagination info
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Total Results: ${_animeResults.length} | Page $_currentPage of $_totalPages',
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
            ),
          ),

          // Conditional rendering based on layout
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isGridLayout
                      ? _buildGridView(themeData)
                      : _buildListView(themeData),
            ),
          ),

          // Add some bottom padding
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: // Pagination Widget
          _totalPages < 0 || _totalPages > 1
              ? _buildAdvancedPagination()
              : null,
    );
  }

  // Grid View Builder
  Widget _buildGridView(ThemeData themeData) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _animeResults.length,
      itemBuilder: (context, index) {
        final anime = _animeResults[index];
        return AnimeCard(anime: anime, tag: 'search_grid_$index');
      },
    );
  }

  // List View Builder
  Widget _buildListView(ThemeData themeData) {
    return ListView.separated(
      itemCount: _animeResults.length,
      separatorBuilder: (context, index) => const SizedBox(
        height: 10,
      ),
      itemBuilder: (context, index) {
        final anime = _animeResults[index];
        return AnimeCard(
          anime: anime,
          tag: 'search_list_$index',
          isListLayout: true,
        );
      },
    );
  }
}
