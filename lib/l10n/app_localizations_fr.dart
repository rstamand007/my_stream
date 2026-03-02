// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'My Stream';

  @override
  String get library => 'Bibliothèque';

  @override
  String get search => 'Recherche';

  @override
  String get downloads => 'Téléchargements';

  @override
  String get settings => 'Paramètres';

  @override
  String get myLibrary => 'Ma bibliothèque';

  @override
  String get noPodcasts => 'Aucun podcast pour le moment';

  @override
  String get searchToStart => 'Recherchez des podcasts pour commencer';

  @override
  String get searchPodcasts => 'Rechercher des podcasts';

  @override
  String get searchHint => 'Rechercher des podcasts...';

  @override
  String get findShows => 'Trouvez vos émissions préférées';

  @override
  String get noResults => 'Aucun résultat trouvé';

  @override
  String get tryDifferentSearch => 'Essayez un autre terme de recherche';

  @override
  String get clearAllDownloads => 'Tout effacer';

  @override
  String get noDownloads => 'Aucun téléchargement';

  @override
  String get downloadedAppearHere =>
      'Les épisodes téléchargés apparaîtront ici';

  @override
  String get storageUsed => 'Espace utilisé';

  @override
  String get clearDownloadsTitle => 'Effacer tous les téléchargements';

  @override
  String get clearDownloadsConfirm =>
      'Êtes-vous sûr de vouloir supprimer tous les épisodes téléchargés ? Cette action est irréversible.';

  @override
  String get cancel => 'Annuler';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get subscribed => 'Abonné';

  @override
  String get subscribe => 'S\'abonner';

  @override
  String get about => 'À propos';

  @override
  String get episodes => 'Épisodes';

  @override
  String get noEpisodes => 'Aucun épisode disponible';

  @override
  String get nowPlaying => 'Lecture en cours';

  @override
  String get noEpisodePlaying => 'Aucun épisode en lecture';

  @override
  String get playback => 'Lecture';

  @override
  String get playbackSpeed => 'Vitesse de lecture par défaut';

  @override
  String get skipForward => 'Avancer';

  @override
  String get skipBackward => 'Reculer';

  @override
  String get autoDownload => 'Téléchargement automatique';

  @override
  String get autoDownloadSubtitle =>
      'Télécharger automatiquement les nouveaux épisodes';

  @override
  String get downloadQuality => 'Qualité de téléchargement';

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get version => 'Version';

  @override
  String get licenses => 'Licences open source';

  @override
  String get language => 'Langue';

  @override
  String get english => 'Anglais';

  @override
  String get french => 'Français';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get refresh => 'Actualiser';

  @override
  String lastUpdated(Object date) {
    return 'Dernière mise à jour : $date';
  }
}
