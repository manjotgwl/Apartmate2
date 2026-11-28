import 'package:opendoor/models/forum_post.dart';
import 'package:opendoor/models/post_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForumRepository {
  final SupabaseClient _client;

  static const int createdCutoffDays =
      7; // constants to define which posts are shown in forum feed
  static const int updatedCutoffDays = 2;

  ForumRepository(this._client);

  // Returns a List of Forum Posts, the filtering criterea being whether or
  // not they have been created in the last createdCutoffDays and or
  // updated in the last updatedCutoffDays
  Future<List<ForumPost>> getActivePosts() async {
    final now = DateTime.now().toUtc();

    final creationCutoff = now
        .subtract(const Duration(days: createdCutoffDays))
        .toIso8601String();

    final updateCutoff = now
        .subtract(const Duration(days: updatedCutoffDays))
        .toIso8601String();

    // gte in sql means greater than or equal to
    final data = await _client
        .from('forum_posts')
        .select()
        .eq('status', 'open')
        .or(
          'created_at.gte.$creationCutoff,'
          'updated_at.gte.$updateCutoff',
        )
        .order('updated_at', ascending: false);

    return data.map(ForumPost.fromJson).toList();
  }

  // Returns a ForumPost with the given id
  Future<ForumPost> getPost(String id) async {
    final data = await _client
        .from('forum_posts')
        .select()
        .eq('id', id)
        .single();

    return ForumPost.fromJson(data);
  }

  // Returns a List of Forum Posts by a user specified by their id.
  // Returned list is ordered by creation date, descending.
  Future<List<ForumPost>> getPostsByUser(String id) async {
    final data = await _client
        .from('forum_posts')
        .select()
        .eq('author_id', id)
        .order('created_at', ascending: false);

    return data.map(ForumPost.fromJson).toList();
  }

  // Inserts a new forum post into the table and returns the created object
  Future<ForumPost> createPost({
    required String title,
    required String description,
    required PostType type,
    required String category,
  }) async {
    final data = await _client
        .from('forum_posts')
        .insert({
          'title': title,
          'description': description,
          'type': type.name,
          'category': category,
        })
        .select()
        .single();

    return ForumPost.fromJson(data);
  }

  // Updates the post in the table with the matching id. Only fields that are updated are title,
  // description and category. The rest are either immutable or managed automatically by Supabase.
  Future<ForumPost> updatePost(ForumPost post) async {
    final data = await _client
        .from('forum_posts')
        .update({
          'title': post.title,
          'description': post.description,
          'category': post.category,
        })
        .eq('id', post.id)
        .select()
        .single();

    return ForumPost.fromJson(data);
  }

  // Deletes the post with the passed in id
  Future<void> deletePost(String id) async {
    await _client
        .from('forum_posts')
        .delete()
        .eq('id', id)
        .select('id')
        .single();
  }
}
