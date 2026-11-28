import 'package:flutter/foundation.dart';
import 'package:opendoor/models/forum_post.dart';
import 'package:opendoor/models/post_type.dart';
import 'package:opendoor/repositories/forum_repository.dart';

// Handles fetching, filtering, updating, creating and delete forum posts
// from the database. Notifies listening widgets when data changes and when
// signals when a rebuild is needed.
class ForumProvider extends ChangeNotifier {
  final ForumRepository _repository; // forum_posts table

  List<ForumPost> _posts = []; // local copy of posts
  bool _isLoading = false; // flag to signal when posts are loading
  bool _isChanging =
      false; // flag to signal when the current posts list is changing
  String? _errorMessage;

  // fields for filtering posts
  // if a filter is null, allow anything
  PostType? _typeFilter;
  String? _categoryFilter;

  bool _disposed =
      false; // flag to keep track of whether or not this provider has been
  // disposed

  // default ctor
  ForumProvider(this._repository);

  // getters
  List<ForumPost> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  bool get isChanging => _isChanging;
  String? get errorMessage => _errorMessage;
  PostType? get typeFilter => _typeFilter;
  String? get categoryFilter => _categoryFilter;

  // Returns a list of filtered posts, filtered by either type and or category
  List<ForumPost> get filteredPosts {
    return _posts.where((post) {
      final matchesType = _typeFilter == null || post.type == _typeFilter;

      final matchesCategory =
          _categoryFilter == null || post.category == _categoryFilter;

      return matchesType && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // To avoid calling notify listeners on an already disposed provider
  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // Returns a List of Forum Posts for a specific user
  Future<List<ForumPost>> getPostsByUser(String id) async {
    return await _repository.getPostsByUser(id);
  }

  // setters for filters
  void setTypeFilter(PostType? type) {
    _typeFilter = type;
    _notify();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    _notify();
  }

  void clearFilters() {
    _typeFilter = null;
    _categoryFilter = null;
    _notify();
  }

  // Loads all active posts (which post is 'active' is decided by constants in
  // forum_repository.dart)
  Future<void> loadPosts() async {
    if (isChanging || isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      _posts = await _repository.getActivePosts();
    } catch (e) {
      _errorMessage = "failed to load active posts";
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  // Creates a post, returns a boolean representing whether or not the creation
  // was a success.
  Future<bool> createPost({
    required String title,
    required String description,
    required PostType type,
    required String category,
  }) async {
    if (isChanging || isLoading) {
      return false;
    }

    _isChanging = true;
    _errorMessage = null;
    _notify();

    try {
      final ForumPost post = await _repository.createPost(
        title: title,
        description: description,
        type: type,
        category: category,
      );
      _posts.insert(0, post);
      return true;
    } catch (e) {
      _errorMessage = 'failed to create post, please try again';
      return false;
    } finally {
      _isChanging = false;
      _notify();
    }
  }

  // Updates a post, checks the database against the passed in post's id and
  // updates the rows that matched. Returns a bool indicating success.
  Future<bool> updatePost(ForumPost post) async {
    if (isChanging || isLoading) {
      return false;
    }

    _isChanging = true;
    _errorMessage = null;
    _notify();

    try {
      final ForumPost returnedPost = await _repository.updatePost(post);
      _posts.removeWhere((elem) => elem.id == post.id);
      _posts.insert(0, returnedPost);
      return true;
    } catch (e) {
      _errorMessage = 'failed to update post, please try again';
      return false;
    } finally {
      _isChanging = false;
      _notify();
    }
  }

  // Deletes a given post, returns a boolean indicating success.
  Future<bool> deletePost(ForumPost post) async {
    if (isChanging || isLoading) {
      return false;
    }

    _isChanging = true;
    _errorMessage = null;
    _notify();

    try {
      await _repository.deletePost(post.id);
      _posts.removeWhere((elem) => elem.id == post.id);
      return true;
    } catch (e) {
      _errorMessage = 'failed to delete post';
      return false;
    } finally {
      _isChanging = false;
      _notify();
    }
  }
}
