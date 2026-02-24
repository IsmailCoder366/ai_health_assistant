class ContextService {
  static Map<String, dynamic>  extractUserContext(String message){
  final  context = <String, dynamic>{};
  final lowerMessage = message.toLowerCase();
  final ageRegex = RegExp(r'(\d{1,3})\s*(?:years?\s*old|yr|age)');
  final ageMatch = ageRegex.firstMatch(lowerMessage);
  if(ageMatch != null){
    context['age'] = int.tryParse(ageMatch.group(1)!) ?? 0;
  }

  if(lowerMessage.contains('male') || lowerMessage.contains('man')){
    context['gender'] = 'male';
  }
  else if(lowerMessage.contains('female') || lowerMessage.contains('woman')){
    context['gender']  = 'female';
  } else{
    context['gender'] = 'not specified';
  }

  final symptoms = <String>[];
  final symptomKeywords= [
    'pain',
    'fever',
    'headache',
    'nausea',
    'fatigue',
    'cought',
    'cold',
  ];

  for(final symptom in symptomKeywords){
    if(lowerMessage.contains(symptom)){
      symptoms.add(symptom);
    }
  }

  if(symptoms.isNotEmpty){
    context['symptoms'] = symptoms;
  }
  return context;
}
static Map<String, dynamic> mergeContext(
    Map<String, dynamic> existing,
    Map<String, dynamic> newContext
    ){
    final merged = Map<String, dynamic>.from(existing);
    newContext.forEach((key, value){
      if(key == 'symptoms' && merged.containsKey('symptoms')){
        final existingSymptoms = List<String>.from(merged['symptoms']);
        final newSymptoms = List<String>.from(value);
        existingSymptoms.addAll(newSymptoms);
        merged['symptoms'] = existingSymptoms.toSet().toList();
      }
      else{
        merged[key] = value;
      }
    });
    return merged;
}

}