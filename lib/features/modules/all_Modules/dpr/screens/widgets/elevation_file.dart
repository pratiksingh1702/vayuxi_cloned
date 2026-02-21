// screens/elevation_selection_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../../core/utlis/widgets/custom.dart';
import '../../../../../../core/utlis/widgets/custom_appBar.dart';

import '../../../../../language/service/providers.dart';
import '../../../site_Details/providers/site_current_provider.dart';

import '../../providers/selection_provider.dart';
import '../widgets/size_Selection.dart';

// ✅ IMPORTANT: use DETECTED providers, not variant ones
import '../../providers/rate_variant_provider.dart';

class ElevationSelectionPage extends ConsumerStatefulWidget {
  final Function(String elevation)? onElevationSelected;
  final String? siteId;
  final String? teamId;
  final String? teamName;

  const ElevationSelectionPage({
    super.key,
    this.onElevationSelected,
    this.siteId,
    this.teamId,
    this.teamName,
  });

  @override
  ConsumerState<ElevationSelectionPage> createState() =>
      _ElevationSelectionPageState();
}

class _ElevationSelectionPageState
    extends ConsumerState<ElevationSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedElevation;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getFilteredElevations(List<String> elevations) {
    if (_searchQuery.isEmpty) return elevations;

    return elevations
        .where(
          (e) => e.toLowerCase().contains(_searchQuery.toLowerCase()),
    )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(dailyEntryTranslationHelperProvider);

    final siteId = ref.watch(selectedSiteIdProvider);
    if (siteId == null) {
      return const Scaffold(
        body: Center(child: Text("Site not selected")),
      );
    }

    // ✅ OFFLINE-FIRST rate analysis
    final asyncRateUpload = ref.watch(rateFileAnalysisProvider(siteId));

    // ✅ DETECTED elevations (NOT variants)
    final elevations = ref.watch(elevationListDetectedProvider(siteId));
    final filteredElevations = _getFilteredElevations(elevations);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(title: "Choose Elevation"),
          ];
        },
        body: BottomButtonWrapper(
          customButtons: [
            CustomButton(
              button: RoundedButton(
                text: lang.saveSubmitButton,
                color: Colors.blue,
                textColor: Colors.white,
                onPressed: _selectedElevation == null
                    ? () {}
                    : () {
                  // ✅ callback
                  if (widget.onElevationSelected != null) {
                    widget.onElevationSelected!(_selectedElevation!);
                  }

                  // // ✅ store selection globally
                  // ref
                  //     .read(selectedElevationProvider.notifier)
                  //     .state = _selectedElevation!;

                  // ✅ go next
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SizeSelectionPage(),
                    ),
                  );
                },
              ),
            ),
          ],
          child: asyncRateUpload.when(
            loading: () =>
            const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Error: $e"),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(
                        rateFileAnalysisProvider(siteId),
                      );
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
            data: (_) {
              return Column(
                children: [
                  // 🔍 SEARCH
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search elevations...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                    ),
                  ),

                  // 📋 LIST
                  Expanded(
                    child: filteredElevations.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No elevations available'
                                : 'No elevations found for "$_searchQuery"',
                            style: const TextStyle(
                                fontSize: 16),
                          ),
                        ],
                      ),
                    )
                        : Padding(
                      padding:
                      const EdgeInsets.all(16),
                      child: GridView.builder(
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                        itemCount:
                        filteredElevations.length,
                        itemBuilder:
                            (context, index) {
                          final elevation =
                          filteredElevations[index];
                          final isSelected =
                              _selectedElevation ==
                                  elevation;

                          return InkWell(
                            onTap: () {
                              setState(() =>
                              _selectedElevation =
                                  elevation);
                            },
                            borderRadius:
                            BorderRadius.circular(
                                12),
                            child: Container(
                              padding:
                              const EdgeInsets.all(
                                  14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue
                                    .withOpacity(
                                    0.12)
                                    : Colors.white,
                                borderRadius:
                                BorderRadius
                                    .circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.grey
                                      .shade300,
                                  width: isSelected
                                      ? 2
                                      : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                                children: [
                                  Icon(
                                    Icons
                                        .trending_up,
                                    size: 34,
                                    color: isSelected
                                        ? Colors.blue
                                        : Colors
                                        .grey,
                                  ),
                                  const SizedBox(
                                      height: 10),
                                  Text(
                                    elevation,
                                    textAlign:
                                    TextAlign
                                        .center,
                                    maxLines: 2,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,
                                    style: TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .w600,
                                      color: isSelected
                                          ? Colors
                                          .blue
                                          : Colors
                                          .black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
