import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service.dart';
import 'package:intl/intl.dart';
import '../../jobs/screens/job_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final notifications = await apiService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final apiService = context.read<ApiService>();
      await apiService.markNotificationAsRead(id);
      _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking as read: $e')),
      );
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    } catch (e) {
      return isoString;
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    // Check if notification has job_id
    if (notification['job_id'] != null) {
      try {
        final apiService = context.read<ApiService>();
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading job details...'),
            duration: Duration(seconds: 1),
          ),
        );
        
        // Fetch the job details using the job_id
        final job = await apiService.getJobDetails(notification['job_id']);
        
        if (mounted) {
          // Navigate to job details screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailsScreen(job: job),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading job details: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Show message for notifications without job_id
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This notification is not linked to any job'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications found.'))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['is_read'] == true;
                      return ListTile(
                        leading: Icon(
                          isRead ? Icons.notifications_none : Icons.notifications,
                          color: isRead ? Colors.grey : Theme.of(context).primaryColor,
                        ),
                        title: Text(notification['message'] ?? 'No message'),
                        subtitle: Text(
                          _formatDate(notification['created_at']),
                        ),
                        trailing: isRead
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.mark_email_read),
                                tooltip: 'Mark as read',
                                onPressed: () => _markAsRead(notification['id']),
                              ),
                        onTap: () => _handleNotificationTap(notification),
                      );
                    },
                  ),
                ),
    );
  }
} 