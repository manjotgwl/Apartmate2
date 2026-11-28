import 'package:opendoor/models/post_status.dart';
import 'package:opendoor/models/post_type.dart';

// A forum post object
class ForumPost {
  final String id; // pkey for forum post table
  final String authorId; // fkey into profiles table
  final String title; // forum post title
  final String description; // description of post
  final PostType type; // type of post (offer or request)
  final String category; // category of post (user decides)
  final PostStatus status; // status of post (open/reserved/closed)
  final DateTime createdAt; // time of creation
  final DateTime updatedAt; // time of last update

  // default ctor that takes in all fields
  const ForumPost({
    required this.id,
    required this.authorId,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // build new ForumPost object from a json as a map
  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: PostType.values.byName(json['type'] as String),
      category: json['category'] as String,
      status: PostStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // convert a map of fields and their values to json format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'title': title,
      'description': description,
      'type': type.name,
      'category': category,
      'status': status.name,
      'created_at': createdAt
          .toUtc()
          .toIso8601String(), // how datetimes are stored on the database
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
