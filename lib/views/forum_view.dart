import 'package:material_ui/material_ui.dart';
import 'package:opendoor/providers/forum_provider.dart';
import 'package:provider/provider.dart';

class ForumView extends StatelessWidget {
  const ForumView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ForumProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forum'),
        actions: [
          IconButton(
            onPressed: provider.isLoading || provider.isChanging
                ? null
                : () => provider.loadPosts(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(ForumProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!));
    }

    final posts = provider.filteredPosts;

    if (posts.isEmpty) {
      return const Center(
        child: Text("50000 people used to live here now it's a ghost town"),
      );
    }

    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];

        return Card(
          child: ListTile(
            title: Text(post.title),
            subtitle: Text(post.description),
            trailing: (Text(post.type.name)),
          ),
        );
      },
    );
  }
}
