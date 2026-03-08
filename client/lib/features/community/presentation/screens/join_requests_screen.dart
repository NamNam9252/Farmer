import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/language_provider.dart';
import '../providers/community_provider.dart';
import '../../data/repository/community_repository.dart';

class JoinRequestsScreen extends ConsumerStatefulWidget {
  final String communityId;
  const JoinRequestsScreen({super.key, required this.communityId});

  @override
  ConsumerState<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends ConsumerState<JoinRequestsScreen> {
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final repo = CommunityRepository();
      final data = await repo.getJoinRequests(widget.communityId);
      setState(() {
        requests = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(languageProvider) == 'hi';

    return Scaffold(
      appBar: AppBar(
        title: Text(isHindi ? 'शामिल होने के अनुरोध' : 'Join Requests'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : requests.isEmpty
                  ? Center(child: Text(isHindi ? 'कोई लंबित अनुरोध नहीं' : 'No pending requests'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        final user = req['user'] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              child: Text(user['name']?[0] ?? '?'),
                            ),
                            title: Text(user['name'] ?? 'Unknown User'),
                            subtitle: Text(user['email'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => _handleApprove(req['id']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _handleReject(req['id']),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Future<void> _handleApprove(String requestId) async {
    try {
      await ref.read(communityDetailProvider.notifier).approveJoinRequest(widget.communityId, requestId);
      _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _handleReject(String requestId) async {
    try {
      await ref.read(communityDetailProvider.notifier).rejectJoinRequest(widget.communityId, requestId);
      _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
