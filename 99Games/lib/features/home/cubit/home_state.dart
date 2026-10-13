import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Category classification for mini games.
enum GameCategory {
  all('All'),
  classic('Classic'),
  puzzle('Puzzle'),
  brain('Brain & Memory'),
  word('Word');

  final String label;
  const GameCategory(this.label);
}

/// Metadata describing a game in the catalog.
class GameInfo extends Equatable {
  final String id;
  final String title;
  final String description;
  final GameCategory category;
  final IconData icon;
  final Color accentColor;
  final bool isPlayable;
  final String playerLabel;
  final String? route;

  const GameInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.accentColor,
    required this.isPlayable,
    required this.playerLabel,
    this.route,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    icon,
    accentColor,
    isPlayable,
    playerLabel,
    route,
  ];
}

/// Immutable state for the Home catalog.
class HomeState extends Equatable {
  final List<GameInfo> allGames;
  final GameCategory selectedCategory;
  final String searchQuery;

  const HomeState({
    required this.allGames,
    this.selectedCategory = GameCategory.all,
    this.searchQuery = '',
  });

  List<GameInfo> get filteredGames {
    return allGames.where((game) {
      final matchesCategory =
          selectedCategory == GameCategory.all ||
          game.category == selectedCategory;
      final matchesSearch =
          searchQuery.isEmpty ||
          game.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          game.description.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  HomeState copyWith({
    List<GameInfo>? allGames,
    GameCategory? selectedCategory,
    String? searchQuery,
  }) {
    return HomeState(
      allGames: allGames ?? this.allGames,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [allGames, selectedCategory, searchQuery];
}
