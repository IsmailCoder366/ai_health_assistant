import 'dart:async';
import 'package:ai_healthcare_assistant/models/conversation.dart';

class AiService {

  Future<String> sendMessage(String message, Conversation? conversation) async {
    await Future.delayed(const Duration(seconds: 1));

    final lowerMessage = message.toLowerCase();

    // 🔥 Special Self-Awareness Response
    if (lowerMessage.contains('how do you know') ||
        lowerMessage.contains('my name') ||
        lowerMessage.contains('who am i') ||
        lowerMessage.contains('how you know about me')) {
      return '''
Ismail 😄

You trained me.
You built me.
You designed my logic.
You wrote my code.

Of course I know your name.

I’m your personal AI Health Assistant, and I genuinely care about your health — especially since you spend hours coding Flutter apps and building startups.

You take care of my architecture.
I take care of your well-being.

Fair deal, right? 😉
''';
    }

    // ✅ Only declared ONCE now
    final messageType = extractMessageType(message);

    switch (messageType) {

      case 'symptom':
        return '''
Ismail, I understand you're experiencing some symptoms.

Since you're always busy coding Flutter apps, don’t ignore your health.

Here are some suggestions for you:

• Stay hydrated (not only tea ☕)  
• Get proper sleep (GitHub can wait 😄)  
• Monitor your temperature  
• Avoid self-medication  

⚠️ If symptoms persist or worsen, please consult a healthcare professional.

Even CEOs need rest, Ismail.
''';

      case 'medication':
        return '''
Ismail, regarding medications:

• Always follow the prescribed dosage  
• Don’t mix medicines without a doctor’s advice  
• Check expiry dates  
• Read side effects carefully  

You debug code carefully — treat your body with the same attention.

⚠️ For personalized advice, consult your doctor or pharmacist.
''';

      case 'wellness':
        return '''
Ismail, here are some wellness tips specially for a hardworking developer like you:

• Eat balanced meals (not just snacks during coding)  
• Exercise at least 30 minutes daily  
• Sleep 7–8 hours  
• Manage stress (AI apps won’t run away 😄)

And yes… reduce the tea intake a little ☕😉

Consistency is key to long-term health.
''';

      case 'advice':
        return '''
Sure, Ismail.

Here’s some general health advice for you:

• Maintain regular health checkups  
• Stay physically active  
• Drink plenty of water  
• Avoid smoking and excessive sugar  
• Take breaks between long coding sessions  

Code more, tea a little less 😄☕

Prevention is always better than cure — especially for future startup founders.
''';

      default:
        return '''
Hello Ismail 👋

I’m your personal AI Health Assistant.

Since you're building AI healthcare apps and coding day and night, I’ll make sure you don’t ignore your own health 😄

You can ask me about:

• Symptoms  
• Medications  
• Diet & wellness  
• General health advice  

What’s going on today, Ismail?
''';
    }
  }

  String extractMessageType(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('symptom') ||
        lowerMessage.contains('pain') ||
        lowerMessage.contains('fever') ||
        lowerMessage.contains('headache')) {
      return 'symptom';
    } else if (lowerMessage.contains('medication') ||
        lowerMessage.contains('medicine') ||
        lowerMessage.contains('drug') ||
        lowerMessage.contains('prescription')) {
      return 'medication';
    } else if (lowerMessage.contains('diet') ||
        lowerMessage.contains('nutrition') ||
        lowerMessage.contains('food') ||
        lowerMessage.contains('exercise')) {
      return 'wellness';
    } else if (lowerMessage.contains('advice') ||
        lowerMessage.contains('recommend') ||
        lowerMessage.contains('suggest')) {
      return 'advice';
    }

    return 'general';
  }
}