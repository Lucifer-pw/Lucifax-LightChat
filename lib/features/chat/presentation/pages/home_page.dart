import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/chat_list/chat_list_bloc.dart';
import '../bloc/chat_list/chat_list_event.dart';
import '../bloc/chat_list/chat_list_state.dart';
import '../widgets/chat_tile.dart';
import '../widgets/sort_filter_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ChatListBloc _privateChatBloc;
  late ChatListBloc _groupChatBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _privateChatBloc = getIt<ChatListBloc>();
    _groupChatBloc = getIt<ChatListBloc>();

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthenticatedState) {
      _privateChatBloc.add(LoadChatsEvent(userId: authState.user.uid, type: 'private'));
      _groupChatBloc.add(LoadChatsEvent(userId: authState.user.uid, type: 'group'));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _privateChatBloc.close();
    _groupChatBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthenticatedState ? authState.user.uid : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'LightChat',
          style: AppTextStyles.heading2.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppColors.surface,
            onSelected: (value) {
              if (value == 'new_group') {
                context.push('/create-group');
              } else if (value == 'profile') {
                context.push('/profile');
              } else if (value == 'settings') {
                context.push('/appearance-settings');
              } else if (value == 'qr_web') {
                context.push('/qr-scanner');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_group',
                child: Text('New Group'),
              ),
              const PopupMenuItem(
                value: 'qr_web',
                child: Text('Linked Devices (LightChatWeb)'),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Appearance & Settings'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTextStyles.bodyMedium,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'CHATS (PRIVATE)'),
            Tab(text: 'GROUPS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Private Chats
          _buildChatListView(_privateChatBloc, currentUserId, isGroup: false),

          // Tab 2: Group Chats
          _buildChatListView(_groupChatBloc, currentUserId, isGroup: true),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 1) {
            context.push('/create-group');
          } else {
            context.push('/contacts');
          }
        },
        child: Icon(_tabController.index == 1 ? Icons.group_add_rounded : Icons.chat_bubble_rounded),
      ),
    );
  }

  Widget _buildChatListView(ChatListBloc bloc, String currentUserId, {required bool isGroup}) {
    return BlocBuilder<ChatListBloc, ChatListState>(
      bloc: bloc,
      builder: (context, state) {
        return Column(
          children: [
            SortFilterBar(
              currentSort: state.sortBy,
              onSortChanged: (sortBy) {
                bloc.add(ChangeSortFilterEvent(sortBy));
              },
            ),
            Expanded(
              child: _buildChatListContent(state, currentUserId, isGroup),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChatListContent(ChatListState state, String currentUserId, bool isGroup) {
    if (state is ChatListLoading) {
      return const LoadingIndicator(message: 'Loading conversations...');
    } else if (state is ChatListError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    } else if (state is ChatListLoaded) {
      if (state.chats.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGroup ? Icons.groups_rounded : Icons.chat_bubble_outline_rounded,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                isGroup ? 'No group conversations yet' : 'No chats yet',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                isGroup ? 'Create a group to start chatting' : 'Tap the button below to start a new chat',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        itemCount: state.chats.length,
        separatorBuilder: (context, index) => const Divider(
          color: AppColors.divider,
          indent: 80,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final chat = state.chats[index];
          return ChatTile(
            chat: chat,
            currentUserId: currentUserId,
            onTap: () {
              context.push('/chat/${chat.chatId}', extra: chat);
            },
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
