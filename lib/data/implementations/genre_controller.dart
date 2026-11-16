import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_commons/utils/constants/app_page_id_constants.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/genre_firestore.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:neom_core/domain/model/genre.dart';
import 'package:neom_core/domain/use_cases/app_drawer_service.dart';
import 'package:neom_core/domain/use_cases/genre_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/data_assets.dart';
import 'package:sint/sint.dart';

class GenreController extends SintController implements GenreService {
  GenreController({UserService? userService, GenreFirestore? genreFirestore})
      : _injectedUserService = userService,
        _injectedGenreFirestore = genreFirestore;

  final UserService? _injectedUserService;
  final GenreFirestore? _injectedGenreFirestore;
  GenreFirestore? _genreFirestoreInstance;

  UserService? get _userService =>
      _injectedUserService ??
      (Sint.isRegistered<UserService>() ? Sint.find<UserService>() : null);

  UserService get userServiceImpl => Sint.find<UserService>();

  GenreFirestore get _genreFirestore =>
      _injectedGenreFirestore ?? (_genreFirestoreInstance ??= GenreFirestore());

  final RxMap<String, Genre> genres = <String, Genre>{}.obs;
  final RxMap<String, Genre> favGenres = <String, Genre>{}.obs;
  final RxMap<String, Genre> sortedGenres = <String, Genre>{}.obs;
  final RxBool isLoading = true.obs;

  RxList<Genre> selectedGenres = <Genre>[].obs;

  AppProfile profile = AppProfile();

  static const int maxGenresAssetChars = 2 * 1024 * 1024;
  static const int maxGenresCount = 1000;
  static final RegExp _reservedKey = RegExp(r'^__.*__$');
  static final RegExp _unsafeKeyChars = RegExp(
    r'[\x00-\x1F\x7F-\x9F\u0085\u061C\u200B-\u200F\u2028-\u202E\u2060\u2066-\u2069\uFEFF/\\]',
  );

  static bool isReservedGenreKey(String raw) {
    if (_unsafeKeyChars.hasMatch(raw)) return true;
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();
    return lower.isEmpty ||
        trimmed == '.' ||
        trimmed == '..' ||
        trimmed.contains('..') ||
        lower == '__proto__' ||
        lower == 'constructor' ||
        lower == 'prototype' ||
        _reservedKey.hasMatch(trimmed);
  }

  static String _keyFor(Genre genre) =>
      genre.id.isNotEmpty ? genre.id : genre.name;

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.t('Genres Init');
    await loadGenres();

    final svc = _userService;
    if (svc != null) {
      if (svc.profile.genres != null) {
        favGenres.value = {
          for (final entry in svc.profile.genres!.entries)
            if (!isReservedGenreKey(entry.key)) entry.key: entry.value,
        };
      }
      profile = svc.profile;
    }

    sortFavGenres();
  }

  @override
  void onClose() {
    genres.close();
    favGenres.close();
    sortedGenres.close();
    isLoading.close();
    selectedGenres.close();
    super.onClose();
  }

  static List<Genre> parseGenresPayload(String genreStr) {
    if (genreStr.isEmpty || genreStr.length > maxGenresAssetChars) {
      return const [];
    }
    final decoded = jsonDecode(genreStr);
    if (decoded is! List) return const [];
    final List<Genre> genresList = [];
    for (final genreJSON in decoded) {
      if (genresList.length >= maxGenresCount) break;
      if (genreJSON is! Map) continue;
      try {
        final rawMap = Map<String, dynamic>.from(genreJSON);
        final rawId = rawMap['id']?.toString();
        if (rawId != null && isReservedGenreKey(rawId)) {
          continue;
        }
        final parsed = Genre.fromJsonDefault(rawMap);
        if (!isReservedGenreKey(_keyFor(parsed))) {
          genresList.add(parsed);
        }
      } catch (_) {}
    }
    return genresList;
  }

  @override
  Future<void> loadGenres() async {
    AppConfig.logger.t('loadGenres');
    try {
      final genreStr = await rootBundle.loadString(DataAssets.genresJsonPath);
      final genresList = parseGenresPayload(genreStr);

      AppConfig.logger.d('${genresList.length} loaded genres from json');

      genres.value = {for (final e in genresList) _keyFor(e): e};
    } catch (e) {
      AppConfig.logger.d(e.toString());
    } finally {
      isLoading.value = false;
      update([AppPageIdConstants.genres]);
    }
  }

  @override
  Future<void> addGenre(int index) async {
    if (!index.isFinite || index < 0 || index >= sortedGenres.length) return;
    AppConfig.logger.t('addGenre');

    final genre = sortedGenres.values.elementAt(index);
    final key = _keyFor(genre);
    if (isReservedGenreKey(key)) return;
    genre.isFavorite = true;
    sortedGenres[key] = genre;

    AppConfig.logger.d('Adding genre ${genre.name}');
    if (profile.id.isNotEmpty &&
        await _genreFirestore.addGenre(
          profileId: profile.id,
          genreId: genre.name.isNotEmpty ? genre.name : key,
        )) {
      favGenres[key] = genre;
    }

    sortFavGenres();
    update([AppPageIdConstants.genres]);
  }

  @override
  Future<void> removeGenre(int index) async {
    if (!index.isFinite || index < 0 || index >= sortedGenres.length) return;
    AppConfig.logger.t('Removing Genre');
    final genre = sortedGenres.values.elementAt(index);
    final key = _keyFor(genre);

    genre.isFavorite = false;
    sortedGenres[key] = genre;
    AppConfig.logger.d('Removing genre ${genre.name}');

    if (profile.id.isNotEmpty &&
        await _genreFirestore.removeGenre(
          profileId: profile.id,
          genreId: key,
        )) {
      favGenres.remove(key);
      favGenres.remove(genre.name);
    }

    sortFavGenres();
    update([AppPageIdConstants.genres]);
  }

  @override
  void makeMainGenre(Genre genre) {
    AppConfig.logger.d('Main genre ${genre.name}');

    String prevGenreId = '';
    for (final g in favGenres.values) {
      if (g.isMain) {
        g.isMain = false;
        prevGenreId = _keyFor(g);
      }
    }

    final key = _keyFor(genre);
    genre.isMain = true;
    favGenres[key] = genre;
    if (profile.id.isNotEmpty) {
      _genreFirestore.updateMainGenre(
        profileId: profile.id,
        genreId: key,
        prevGenreId: prevGenreId,
      );
    }

    profile.genres ??= <String, Genre>{};
    profile.genres![key] = genre;
    if (Sint.isRegistered<AppDrawerService>()) {
      Sint.find<AppDrawerService>().updateProfile(profile);
    }

    update([AppPageIdConstants.genres]);
  }

  @override
  void sortFavGenres() {
    final nextSorted = <String, Genre>{};

    for (final genre in genres.values) {
      final key = _keyFor(genre);
      final fav = favGenres[key] ??
          (genre.name.isNotEmpty ? favGenres[genre.name] : null);
      if (fav != null) {
        nextSorted[key] = fav;
      }
    }

    for (final genre in genres.values) {
      final key = _keyFor(genre);
      if (!nextSorted.containsKey(key)) {
        nextSorted[key] = genre;
      }
    }

    sortedGenres.value = nextSorted;
  }

  Iterable<Widget> get genreChips sync* {
    for (final genre in genres.values) {
      final trimmedName = genre.name.trim();
      if (trimmedName.isEmpty) continue;
      yield Padding(
        padding: const EdgeInsets.all(5.0),
        child: FilterChip(
          backgroundColor: AppColor.surfaceBright,
          avatar: CircleAvatar(
            backgroundColor: Colors.cyan.shade500,
            child: Text(
              trimmedName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          label: Text(
            trimmedName.capitalize,
            style: const TextStyle(fontSize: 12),
          ),
          selected: selectedGenres.contains(genre),
          selectedColor: AppColor.surfaceCard,
          onSelected: (bool selected) {
            genre.isFavorite = selected;
            selected ? addGenreFromChips(genre) : removeGenreFromChips(genre);
          },
        ),
      );
    }
  }

  void addGenreFromChips(Genre genre) {
    if (!selectedGenres.contains(genre)) {
      selectedGenres.add(genre);
    }
    update();
  }

  void removeGenreFromChips(Genre genre) {
    selectedGenres.removeWhere((g) => g == genre);
    update();
  }
}
