import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/game_card.dart';

/// The main catalog screen of 99 Mini Games.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final cubit = context.read<HomeCubit>();
        final filteredGames = state.filteredGames;

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_esports_rounded, size: 24),
                SizedBox(width: 8),
                Text('99 Mini Games'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              CategoryFilterBar(
                selectedCategory: state.selectedCategory,
                onSelectCategory: (cat) => cubit.selectCategory(cat),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 900
                        ? 4
                        : (width > 600 ? 3 : 2);

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filteredGames.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.92,
                      ),
                      itemBuilder: (context, index) {
                        final game = filteredGames[index];
                        return GameCard(
                          game: game,
                          onPlay: () {
                            if (game.route != null) {
                              context.push(game.route!);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
