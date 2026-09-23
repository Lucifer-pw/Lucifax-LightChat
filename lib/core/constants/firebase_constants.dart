class FirebaseConstants {
  // Collection Names
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';
  static const String userChatsCollection = 'userChats';
  static const String userCategoriesCollection = 'userCategories';
  static const String statusesCollection = 'statuses';
  static const String musicCollection = 'music';
  static const String playlistsCollection = 'userPlaylists';
  static const String webSessionsCollection = 'webSessions';
  static const String userWebSessionsCollection = 'userWebSessions';
  static const String appVersionsCollection = 'appVersions';

  // Storage Paths
  static const String profilePhotosPath = 'profile_photos';
  static const String coverPhotosPath = 'cover_photos';
  static const String chatMediaPath = 'chat_media';
  static const String statusMediaPath = 'status_media';
  static const String musicFilesPath = 'music_files';

  // Remote Config Keys
  static const String rcMinVersion = 'min_version';
  static const String rcLatestVersion = 'latest_version';
  static const String rcUpdateEnabled = 'update_enabled';
  static const String rcMaintenanceMode = 'maintenance_mode';
}
