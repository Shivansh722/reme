import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final GenerativeModel _model;
  
  GeminiService({required String apiKey}) 
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: apiKey,
        );
  
  Future<String> generateContent(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'No response from Gemini';
    } catch (e) {
      return 'Error communicating with Gemini: $e';
    }
  }
}