import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../data/post_model.dart';
import '../data/post_repository.dart';

part 'post_event.dart';
part 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc(this.repository) : super(const PostState.initial()) {
    on<PostFetched>(_onFetched);
    on<PostRefreshed>(_onRefreshed);
    on<PostCreated>(_onCreated);
    on<PostUpdated>(_onUpdated);
    on<PostDeleted>(_onDeleted);
  }

  final PostRepository repository;

  // ================= FETCH =================
  Future<void> _onFetched(
    PostFetched event,
    Emitter<PostState> emit,
  ) async {
    if (state.status == PostStatus.loading) return;

    emit(state.copyWith(status: PostStatus.loading));
    try {
      final posts = await repository.fetchPosts();
      emit(state.copyWith(status: PostStatus.success, posts: posts));
    } catch (e) {
      emit(
        state.copyWith(
          status: PostStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  // ================= REFRESH =================
  Future<void> _onRefreshed(
    PostRefreshed event,
    Emitter<PostState> emit,
  ) async {
    emit(state.copyWith(status: PostStatus.loading));
    try {
      final posts = await repository.fetchPosts();
      emit(state.copyWith(status: PostStatus.success, posts: posts));
    } catch (e) {
      emit(
        state.copyWith(
          status: PostStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  // ================= CREATE =================
  Future<void> _onCreated(
    PostCreated event,
    Emitter<PostState> emit,
  ) async {
    emit(state.copyWith(status: PostStatus.loading));
    try {
      await repository.createPost(
        title: event.title,
        author: event.author,
        article: event.article,
        imageFile: event.imageFile,
      );

      final posts = await repository.fetchPosts();

      emit(
        state.copyWith(
          status: PostStatus.success,
          posts: posts,
          message: 'Post berhasil dibuat',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PostStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  // ================= UPDATE =================
  Future<void> _onUpdated(
    PostUpdated event,
    Emitter<PostState> emit,
  ) async {
    emit(state.copyWith(status: PostStatus.loading));
    try {
      await repository.updatePost(
        id: event.id,
        title: event.title,
        author: event.author,
        article: event.article,
        imageFile: event.imageFile,
      );

      final posts = await repository.fetchPosts();

      emit(
        state.copyWith(
          status: PostStatus.success,
          posts: posts,
          message: 'Post berhasil diperbarui',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PostStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  // ================= DELETE =================
  Future<void> _onDeleted(
    PostDeleted event,
    Emitter<PostState> emit,
  ) async {
    emit(state.copyWith(status: PostStatus.loading));
    try {
      await repository.deletePost(event.id);

      final posts = await repository.fetchPosts();

      emit(
        state.copyWith(
          status: PostStatus.success,
          posts: posts,
          message: 'Post berhasil dihapus',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PostStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }
}
