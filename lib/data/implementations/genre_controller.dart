import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sint/sint.dart';
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

class GenreController extends SintController implements GenreService {

  final userServiceImpl = Sint.find<UserService>();

  final RxMap<String, Genre> genres = <String, Genre>{}.obs;
  final RxMap<String, Genre> favGenres = <String,Genre>{}.obs;
  final RxMap<String, Genre> sortedGenres = <String,Genre>{}.obs;
  final RxBool isLoading = true.obs;

  RxList<Genre> selectedGenres = <Genre>[].obs;

  AppProfile profile = AppProfile();

  @override
  void onInit() async {
    super.onInit();
    AppConfig.logger.t("Genres Init");
    await loadGenres();

    if(userServiceImpl.profile.genres != null) {
      favGenres.value = userServiceImpl.profile.genres!;
    }

    profile = userServiceImpl.profile;

    sortFavGenres();
  }

  @override
  Future<void> loadGenres() async {
    AppConfig.logger.t("loadGenres");
    String genreStr = await rootBundle.loadString(DataAssets.genresJsonPath);
    
    List<dynamic> genresJSON = jsonDecode(genreStr);
    List<Genre> genresList = [];
    for (var genreJSON in genresJSON) {
      genresList.add(Genre.fromJsonDefault(genreJSON));
    }

    AppConfig.logger.d("${genresList.length} loaded genres from json");

    genres.value = {for (var e in genresList) e.name : e};

    isLoading.value = false;
    update([AppPageIdConstants.genres]);
  }


  @override
  Future<void> addGenre(int index) async {
    AppConfig.logger.t("addGenre");

    Genre genre = sortedGenres.values.elementAt(index);
    sortedGenres[genre.id]!.isFavorite = true;

    AppConfig.logger.d("Adding genre ${genre.name}");
    if(await GenreFirestore().addGenre(profileId: profile.id, genreId:  genre.name)){
      favGenres[genre.id] = genre;
    }

    sortFavGenres();
    update([AppPageIdConstants.genres]);
  }

  @override
  Future<void> removeGenre(int index) async {
    AppConfig.logger.t("Removing Genre");
    Genre genre = sortedGenres.values.elementAt(index);

    sortedGenres[genre.id]!.isFavorite = false;
    AppConfig.logger.d("Removing genre ${genre.name}");

    if(await GenreFirestore().removeGenre(profileId: profile.id, genreId: genre.id)){
      favGenres.remove(genre.id);
    }

    sortFavGenres();
    update([AppPageIdConstants.genres]);
  }

  @override
  void makeMainGenre(Genre genre){
    AppConfig.logger.d("Main genre ${genre.name}");

    String prevGenreId = "";
    for (var g in favGenres.values) {
      if(g.isMain) {
        g.isMain = false;
        prevGenreId = g.id;
      }
    }

    genre.isMain = true;
    favGenres.update(genre.name, (g) => g);
    GenreFirestore().updateMainGenre(profileId: profile.id,
      genreId: genre.id, prevGenreId:  prevGenreId);

    profile.genres![genre.id] = genre;
    Sint.find<AppDrawerService>().updateProfile(profile);

    update([AppPageIdConstants.genres]);
  }

  @override
  void sortFavGenres(){

    sortedGenres.value = {};

    for (var genre in genres.values) {
      if (favGenres.containsKey(genre.id)) {
        sortedGenres[genre.id] = favGenres[genre.id]!;
      }
    }

    for (var genre in genres.values) {
      if (!favGenres.containsKey(genre.id)) {
        sortedGenres[genre.id] = genres[genre.id]!;
      }
    }

  }

  Iterable<Widget> get genreChips sync* {

    for (Genre genre in genres.values) {
      yield Padding(
        padding: const EdgeInsets.all(5.0),
        child: FilterChip(
          backgroundColor: AppColor.main50,
          avatar: CircleAvatar(
            backgroundColor: Colors.cyan.shade500,
            child: Text(genre.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          label: Text(genre.name.capitalize, style: const TextStyle(fontSize: 12),),
          selected: selectedGenres.contains(genre),
          selectedColor: AppColor.main50,
          onSelected: (bool selected) {
            genre.isFavorite = true;
            selected ? addGenreFromChips(genre) : removeGenreFromChips(genre);
          },
        ),
      );
    }
  }

  void addGenreFromChips(Genre genre) {
    selectedGenres.add(genre);
    update();
  }

  void removeGenreFromChips(Genre genre){
    selectedGenres.removeWhere((g) {
      return g == genre;
    });
    update();
  }


}
