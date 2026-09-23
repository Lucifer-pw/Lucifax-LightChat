import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/app_update/data/datasources/github_release_datasource.dart';
import '../../features/app_update/data/repositories/update_repository_impl.dart';
import '../../features/app_update/domain/repositories/update_repository.dart';
import '../../features/app_update/domain/usecases/check_for_update.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/save_user_profile.dart';
import '../../features/auth/domain/usecases/send_phone_otp.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/update_online_status.dart';
import '../../features/auth/domain/usecases/verify_otp.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/create_or_get_chat.dart';
import '../../features/chat/domain/usecases/get_chats_stream.dart';
import '../../features/chat/domain/usecases/get_messages_stream.dart';
import '../../features/chat/domain/usecases/mark_as_read.dart';
import '../../features/chat/domain/usecases/send_message.dart';
import '../../features/chat/domain/usecases/set_typing_status.dart';
import '../../features/chat/presentation/bloc/chat_list/chat_list_bloc.dart';
import '../../features/chat/presentation/bloc/chat_room/chat_room_bloc.dart';
import '../../features/contacts/data/datasources/contacts_remote_datasource.dart';
import '../../features/contacts/data/repositories/contacts_repository_impl.dart';
import '../../features/contacts/domain/repositories/contacts_repository.dart';
import '../../features/contacts/domain/usecases/sync_contacts.dart';
import '../../features/contacts/presentation/bloc/contacts_bloc.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // Firebase Singletons
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  // ----------------------------------------------------
  // Auth Feature
  // ----------------------------------------------------
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: getIt(),
      firestore: getIt(),
      storage: getIt(),
    ),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton(() => GetCurrentUser(getIt()));
  getIt.registerLazySingleton(() => SendPhoneOtp(getIt()));
  getIt.registerLazySingleton(() => VerifyOtp(getIt()));
  getIt.registerLazySingleton(() => SaveUserProfile(getIt()));
  getIt.registerLazySingleton(() => SignOut(getIt()));
  getIt.registerLazySingleton(() => UpdateOnlineStatus(getIt()));

  getIt.registerFactory(
    () => AuthBloc(
      getCurrentUser: getIt(),
      sendPhoneOtp: getIt(),
      verifyOtp: getIt(),
      saveUserProfile: getIt(),
      signOut: getIt(),
    ),
  );

  // ----------------------------------------------------
  // Chat Feature
  // ----------------------------------------------------
  getIt.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(
      firestore: getIt(),
      firebaseAuth: getIt(),
    ),
  );
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton(() => GetChatsStream(getIt()));
  getIt.registerLazySingleton(() => GetMessagesStream(getIt()));
  getIt.registerLazySingleton(() => SendMessage(getIt()));
  getIt.registerLazySingleton(() => MarkAsRead(getIt()));
  getIt.registerLazySingleton(() => CreateOrGetPrivateChat(getIt()));
  getIt.registerLazySingleton(() => SetTypingStatus(getIt()));

  getIt.registerFactory(() => ChatListBloc(getChatsStream: getIt()));
  getIt.registerFactory(
    () => ChatRoomBloc(
      getMessagesStream: getIt(),
      sendMessage: getIt(),
      markAsRead: getIt(),
      setTypingStatus: getIt(),
    ),
  );

  // ----------------------------------------------------
  // Contacts Feature
  // ----------------------------------------------------
  getIt.registerLazySingleton<ContactsRemoteDataSource>(
    () => ContactsRemoteDataSourceImpl(firestore: getIt()),
  );
  getIt.registerLazySingleton<ContactsRepository>(
    () => ContactsRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerLazySingleton(() => SyncContacts(getIt()));
  getIt.registerFactory(() => ContactsBloc(syncContacts: getIt()));

  // ----------------------------------------------------
  // App Update Feature
  // ----------------------------------------------------
  getIt.registerLazySingleton<GithubReleaseDataSource>(
    () => GithubReleaseDataSourceImpl(),
  );
  getIt.registerLazySingleton<UpdateRepository>(
    () => UpdateRepositoryImpl(dataSource: getIt()),
  );
  getIt.registerLazySingleton(() => CheckForUpdate(getIt()));
}
