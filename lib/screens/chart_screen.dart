import 'package:ai_healthcare_assistant/models/conversation.dart';
import 'package:ai_healthcare_assistant/services/ai_service.dart';
import 'package:ai_healthcare_assistant/services/context_service.dart';
import 'package:ai_healthcare_assistant/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/messages.dart';

class ChartScreen extends StatefulWidget {

  final Conversation? initialConversation;
  const ChartScreen({super.key, this.initialConversation});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiService _aiService = AiService();
  final StorageService _storageService = StorageService();
  final Uuid _uuid = Uuid();

  Conversation? _currentConversation;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState(){
    super.initState();
    _animationController = AnimationController(vsync: this,
    duration: Duration(milliseconds: 300)
    );

    _initiallizeConversation();
  }

  void _initiallizeConversation() async{
    if(widget.initialConversation != null){
      setState(() {
        _currentConversation = widget.initialConversation;
      });
  }
    else{
      final welcomeMessage = Message(
          id: _uuid.v4(),

      text : "Hello! I'm your Healthcare Assistant. I'm here to help you with health information, wellness tips, and answer your health-related questions. How can i assist you today",
        isUser : false,
        timestamp : DateTime.now(),
        messageType: 'welcome'
      );
      _currentConversation = Conversation(
          id: _uuid.v4(),
          title: 'New Health Consultation',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          messages: [welcomeMessage],
          userContext: {}
      );


      await _storageService.saveConversation(_currentConversation!);
      await _storageService.setCurrentConversationId(_currentConversation!.id);

    }
}

@override
void dispose(){
    _animationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
}

_startNewConversation()async{
  final welcomeMessage = Message(
      id: _uuid.v4(),

      text : "Hello! I'm your Healthcare Assistant. I'm here to help you with health information, wellness tips, and answer your health-related questions. How can i assist you today",
      isUser : false,
      timestamp : DateTime.now(),
      messageType: 'welcome'
  );
  _currentConversation = Conversation(
      id: _uuid.v4(),
      title: 'New Health Consultation',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      messages: [welcomeMessage],
      userContext: {}
  );


  await _storageService.saveConversation(_currentConversation!);
  await _storageService.setCurrentConversationId(_currentConversation!.id);
}

Future<void> _sendMessage(String text) async{
    if(text.trim().isEmpty || _isLoading) return;
    final newContext = ContextService.extractUserContext(text);
    final updatedContext = ContextService.mergeContext(_currentConversation!.userContext, newContext);
    final userMessage = Message(
      id: _uuid.v4(),
      text: text,
      isUser: true,
      timestamp : DateTime.now(),
      messageType : _aiService.extractMessageType(text),
    );
    final updatedMessages = List<Message>.from(_currentConversation!.messages)..add(userMessage);
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
    try{
      final response = await _aiService.sendMessage(text, _currentConversation);
      final aiMessage = Message(
        id: _uuid.v4(),
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: 'response',
      );
      final finalMessages = List<Message>.from(_currentConversation!.messages)..add(aiMessage);

      setState(() {
        _currentConversation = _currentConversation!.copyWith(
          messages: finalMessages,
          title: _generateConversationTitle(finalMessages),
          lastUpdated: DateTime.now(),
        );

        _isLoading = false;

      });

      await _storageService.saveConversation(_currentConversation!);



    }catch(e){
      final errorMessage = Message(
        id: _uuid.v4(),
        text: "I apologise but I'm having issues right now. Please Try Again ",
        isUser:  false,
        timestamp: DateTime.now(),
        messageType: 'error'
      );
      final errorMessages = List<Message>.from(_currentConversation!.messages)..add(errorMessage);
      setState(() {
        _currentConversation = _currentConversation!.copyWith(
          messages: errorMessages
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
}

String _generateConversationTitle(List<Message> messages){
    if(messages.length < 1) return 'New Heath Consultation';

    final firstUserMessage = messages.firstWhere((m) => m.isUser,
    orElse: () => messages.first
    );

    String title = firstUserMessage.text;
    if(title.length > 30){
      title = title.substring(0, 30) + '...';
    }
    return title;
}


void _scrollToBottom(){
    WidgetsBinding.instance.addPostFrameCallback((_){
      if(_scrollController.hasClients){
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut
        );
      }
    });
}

void _showConversations(){
    // Navigator.push(context, MaterialPageRoute(builder:  (context) => ConversationScreen(
    //   onConversationSelected : (conversation){
    //     setState(() {
    //       _currentConversation = conversation;
    //     });
    //     Navigator.pop(context);
    //   }
    // )));
}

void _clearCurrentChat(){
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text("Clear Current Chat"),
      content: Text('Are you sure you want to clear current conversation?. this action cannot be undone'),
      actions: [
        TextButton(onPressed: (){Navigator.pop(context);}, child: Text('Cancel')),
        TextButton(onPressed: ()async{
          if(_currentConversation != null){
            await _storageService.deleteConversation(_currentConversation!.id);
            Navigator.pop(context);
            _initiallizeConversation();
          }
        }, child: Text('Clear', style: TextStyle(color: Colors.redAccent))),
      ],
    ));
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
                gradient: LinearGradient(colors: [
                  Color(0xFF00BFA6),
                  Color(0xFF4CAF50),
                ]),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Icon(Icons.health_and_safety, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HealthCare Assistant', style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 18,
                  fontWeight: FontWeight.w600
                )),
                Text('Your personal healthcare companion',

                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00BFA6)
                ),
                )
              ],
            )),
          ],
        ),
        actions: [
          IconButton(onPressed: _startNewConversation, icon: Icon(Icons.chat_bubble_outline)),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            onSelected: (value){
              if(value == 'clear'){
                _clearCurrentChat();
              }
              else if(value == 'conversations'){
                _showConversations();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'conversations',
                  child: Row(
                children: [
                  Icon(Icons.history, size: 20, color: Color(0xFF6B7280)),
                  SizedBox(width: 12),
                  Text('View All Chats')
                ],
              )),
              PopupMenuItem(
                  value: 'clear',
                  child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Text('Clear current Chats')
                ],
              )),
            ]
          ),
        ],
      ),
    );
  }
}
