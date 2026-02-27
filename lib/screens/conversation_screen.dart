import 'package:ai_healthcare_assistant/screens/chart_screen.dart';
import 'package:ai_healthcare_assistant/services/storage_service.dart';
import 'package:flutter/material.dart';

import '../models/conversation.dart';

class ConversationScreen extends StatefulWidget {
  final Function(Conversation) onConversationSelected;

  const ConversationScreen({super.key, required this.onConversationSelected});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final StorageService _storageService = StorageService();
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _storageService.loadConversations();
      setState(() {
        _conversations = conversations
          ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    await _storageService.deleteConversation(conversationId);
    await _loadConversations();
  }

  Future<void> _clearAllConversations() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Conversations'),
        content: Text(
          'Are you sure you want to delete all conversations? This action cannot be undone',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _storageService.clearAllConversations();
              Navigator.pop(context);
              await _loadConversations();
            },
            child: Text('Clear All', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FFE0),
      appBar: AppBar(
        elevation: 0,
        title: Text('Your Conversations'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChartScreen()),
              );
            },
            icon: Icon(Icons.add),
            color: Color(0xFF00BFA6),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            onSelected: (value) {
              if (value == 'clear_all') {
                _clearAllConversations();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text('Clear All Chats'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF00BFA6)))
          : _conversations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          return _buildConversationCard(_conversations[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00BFA6), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Conversations Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start a new conversation to get health advice and information',
            style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ChartScreen()),
              );
            },
            icon: Icon(Icons.add),
            label: Text('Start New Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00BFA6),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Conversation conversation) {
    final lastMessage = conversation.messages.isNotEmpty
        ? conversation.messages.last
        : null;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => widget.onConversationSelected(conversation),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00BFA6), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.health_and_safety,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conversation.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          _formateDate(conversation.lastUpdated),
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        color: Color(0xFF9CA4AF), size: 20),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(conversation);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete,
                                size: 18, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
              if (lastMessage != null) ...[
                SizedBox(height: 12),
                Text(
                  lastMessage.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (conversation.userContext.isNotEmpty) ...[
                SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: conversation.userContext.entries
                      .take(3)
                      .map(
                        (entry) => Container(
                      padding:
                      EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFF00BFA6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF00BFA6),
                              fontWeight: FontWeight.w500
                            ),
                          ),
                    ),
                  )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formateDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if(difference.inDays == 0){
      return 'Today ${_formatTime(date)}';
    }
    else if(difference.inDays == 1){
      return 'Yesterday ${_formatTime(date)}';
    }
    else if(difference.inDays < 7){
      return '${difference.inDays} days ago';
    }
    else{
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteDialog(Conversation conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Conversation'),
        content:
        Text('Are you sure you want to delete this conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteConversation(conversation.id);
            },
            child: Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date){
    final hour = date.hour.toString().padLeft(2, '0');
    final mins = date.minute.toString().padLeft(2, '0');

    return '$hour : $mins';
  }
}