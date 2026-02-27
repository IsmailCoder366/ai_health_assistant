import 'package:ai_healthcare_assistant/models/conversation.dart';
import 'package:ai_healthcare_assistant/screens/conversation_screen.dart';
import 'package:ai_healthcare_assistant/services/ai_service.dart';
import 'package:ai_healthcare_assistant/services/context_service.dart';
import 'package:ai_healthcare_assistant/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:uuid/uuid.dart';

import '../models/messages.dart';

class ChartScreen extends StatefulWidget {
  final Conversation? initialConversation;

  const ChartScreen({super.key, this.initialConversation});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final StorageService _storageService = StorageService();
  final Uuid _uuid = Uuid();

  Conversation? _currentConversation;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _initiallizeConversation();
  }

  void _initiallizeConversation() async {
    if (widget.initialConversation != null) {
      setState(() {
        _currentConversation = widget.initialConversation!;
      });
    } else {
      final welcomeMessage = Message(
        id: _uuid.v4(),

        text:
        "Hello! I'm your Healthcare Assistant. I'm here to help you with health information, wellness tips, and answer your health-related questions. How can i assist you today",
        isUser: false,
        timestamp: DateTime.now(),
        messageType: 'welcome',
      );
      _currentConversation = Conversation(
        id: _uuid.v4(),
        title: 'New Health Consultation',
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        messages: [welcomeMessage],
        userContext: {},
      );

      await _storageService.saveConversation(_currentConversation!);
      await _storageService.setCurrentConversationId(_currentConversation!.id);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startNewConversation() async {
    final welcomeMessage = Message(
      id: _uuid.v4(),
      text:
      "Hello! I'm your Healthcare Assistant. I'm here to help you with health information, wellness tips, and answer your health-related questions. How can I assist you today",
      isUser: false,
      timestamp: DateTime.now(),
      messageType: 'welcome',
    );

    final newConversation = Conversation(
      id: _uuid.v4(),
      title: 'New Health Consultation',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      messages: [welcomeMessage],
      userContext: {},
    );

    await _storageService.saveConversation(newConversation);
    await _storageService.setCurrentConversationId(newConversation.id);

    setState(() {
      _currentConversation = newConversation;
    });

    _scrollToBottom();
  }


  Future<void> _sendMessage(String text) async {
    if (text
        .trim()
        .isEmpty || _isLoading) return;
    final newContext = ContextService.extractUserContext(text);
    final updatedContext = ContextService.mergeContext(
      _currentConversation!.userContext,
      newContext,
    );
    final userMessage = Message(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
      messageType: _aiService.extractMessageType(text),
    );
    final updatedMessages = List<Message>.from(_currentConversation!.messages)
      ..add(userMessage);
    setState(() {
      _currentConversation = _currentConversation!.copyWith(
        messages: updatedMessages,
        userContext: updatedContext,
        lastUpdated: DateTime.now(),
      );
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();
    try {
      final response = await _aiService.sendMessage(text, _currentConversation);
      final aiMessage = Message(
        id: _uuid.v4(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: 'response',
      );
      final finalMessages = List<Message>.from(_currentConversation!.messages)
        ..add(aiMessage);

      setState(() {
        _currentConversation = _currentConversation!.copyWith(
          messages: finalMessages,
          title: _generateConversationTitle(finalMessages),
          lastUpdated: DateTime.now(),
        );

        _isLoading = false;
      });

      await _storageService.saveConversation(_currentConversation!);
    } catch (e) {
      print(e);
      final errorMessage = Message(
        id: _uuid.v4(),
        text: "I apologise but I'm having issues right now. Please Try Again ",
        isUser: false,
        timestamp: DateTime.now(),
        messageType: 'error',
      );
      final errorMessages = List<Message>.from(_currentConversation!.messages)
        ..add(errorMessage);
      setState(() {
        _currentConversation = _currentConversation!.copyWith(
          messages: errorMessages,
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  String _generateConversationTitle(List<Message> messages) {
    if (messages.length < 1) return 'New Heath Consultation';

    final firstUserMessage = messages.firstWhere(
          (m) => m.isUser,
      orElse: () => messages.first,
    );

    String title = firstUserMessage.text;
    if (title.length > 30) {
      title = title.substring(0, 30) + '...';
    }
    return title;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showConversations() {
    Navigator.push(context, MaterialPageRoute(builder:  (context) => ConversationScreen(
      onConversationSelected : (conversation){
        setState(() {
          _currentConversation = conversation;
        });
        Navigator.pop(context);
      }
    )));
  }

  void _clearCurrentChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Clear Current Chat"),
        content: Text(
          'Are you sure you want to clear current conversation?. this action cannot be undone',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_currentConversation != null) {
                await _storageService.deleteConversation(
                  _currentConversation!.id,
                );
                Navigator.pop(context);
                _initiallizeConversation();
              }
            },
            child: Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BFA6), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.health_and_safety, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HealthCare Assistant',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Your personal healthcare companion',

                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00BFA6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _startNewConversation,
            icon: Icon(Icons.chat_bubble_outline),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            onSelected: (value) {
              if (value == 'clear') {
                _clearCurrentChat();
              } else if (value == 'conversations') {
                _showConversations();
              }
            },
            itemBuilder: (context) =>
            [
              PopupMenuItem(
                value: 'conversations',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20, color: Color(0xFF6B7280)),
                    SizedBox(width: 12),
                    Text('View All Chats'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.redAccent),
                    SizedBox(width: 12),
                    Text('Clear current Chats'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: _currentConversation == null
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _currentConversation!.messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(
                  _currentConversation!.messages[index],
                  context,
                );
              },
            )),
            if(_isLoading) _buildTypingIndicator(),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1)
              )
            ),
            child: SafeArea(child: Row(
              children: [
                Expanded(child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Color(0xFF00BFA6).withOpacity(0.2),
                    )
                  ),
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Chat or Ask about your symptoms, medications, welness...',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF9CA3AF)
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20
                      )
                    ),
                    onSubmitted: _sendMessage,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_isLoading,
                  ),
                )),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? null :()=> _sendMessage(_textController.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _isLoading ? [
                        Color(0xFFBDBDBD),
                        Color(0xFF9E9E9E),
                      ] : [
                        Color(0xFF00BFA6),
                        Color(0xFF4CAF50),
                      ]),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                )
              ],
            )),
          )

        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00BFA6), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 16,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery
                    .of(context)
                    .size
                    .width * 0.75,
              ),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                  color: message.isUser ? Color(0xFFF0FDF4) : Color(0xFF00BFA6),
                  borderRadius: BorderRadius.circular(18),
                  border: message.isUser
                      ? Border.all(color: Color(0xFF00BFA6).withOpacity(0.2))
                      : null
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [MarkdownBlock(
                    data: message.text,
                    config: MarkdownConfig(
                        configs: [
                          PConfig(
                            textStyle: TextStyle(
                                color: message.isUser
                                    ? Color(0xFF1F2937)
                                    : Colors.white,
                                fontSize: 16,
                                height: 1.4
                            ),
                          )
                        ]
                    )

                ),

                  if(message.messageType != null && !message.isUser)...[
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                      decoration: BoxDecoration(
                          color: Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10)
                      ),
                      child: Text(
                        message.messageType!.toUpperCase(),
                        style: TextStyle(
                            color: Color(0xFF00BFA6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),

          if(message.isUser)...[
            SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: Color(0xFF6B7280),
                  borderRadius: BorderRadius.circular(14)
              ),
              child: Icon(Icons.person_outline, color: Color(0xFF00BFA6), size: 18),

            )
          ]

        ],
      ),
    );
  }
  Widget _buildTypingIndicator(){
    return Padding(padding: EdgeInsetsGeometry.fromLTRB(16, 0, 16, 8),

    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Color(0xFF00BFA6),
              Color(0xFF4CAF50)
            ]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.health_and_safety),
        ),

        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Color(0xFF00BFA6).withOpacity(0.2))
          ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                SizedBox(width: 4),
                _buildTypingDot(1),
                SizedBox(width: 4),
                _buildTypingDot(1),
                SizedBox(width: 4),
              ],
            ),
        )
      ],
    ),
    );
  }


  Widget _buildTypingDot(int index){
    return AnimatedBuilder(animation: _animationController, builder: (context, child){
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Color(0xFF00BFA6),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    });
  }
}