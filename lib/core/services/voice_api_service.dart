import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/voice_models.dart';

part 'voice_api_service.g.dart';

@RestApi(baseUrl: 'https://iloqi-production.up.railway.app/api/')
abstract class VoiceApiService {
  factory VoiceApiService(Dio dio, {String baseUrl}) = _VoiceApiService;

  // Upload voice sample first
  @POST('samples/voice-samples/')
  @MultiPart()
  Future<VoiceSample> uploadVoiceSample(@Part() File file);

  // Then analyze the uploaded sample
  @POST('samples/voice-samples/{sample_id}/analyze/')
  Future<VoiceAnalysisResponse> analyzeVoiceSample(@Path('sample_id') int sampleId);

  // Get analysis results
  @GET('samples/voice-samples/{sample_id}/results/')
  Future<VoiceAnalysisResultsResponse> getAnalysisResults(@Path('sample_id') int sampleId);

  // Re-analyze voice sample
  @POST('samples/voice-samples/{sample_id}/reanalyze/')
  Future<VoiceAnalysisResponse> reanalyzeVoiceSample(
    @Path('sample_id') int sampleId,
    @Body() ReanalyzeRequest request,
  );

  // Get accent recommendations
  @GET('samples/voice-samples/{sample_id}/accent-recommendations/')
  Future<AccentRecommendationsResponse> getAccentRecommendations(@Path('sample_id') int sampleId);

  // Create practice session
  @POST('samples/voice-samples/{sample_id}/practice-sessions/')
  Future<PracticeSessionResponse> createPracticeSession(
    @Path('sample_id') int sampleId,
    @Body() PracticeSessionCreateRequest request,
  );

  // Generate practice audio
  @POST('samples/practice-sessions/{session_id}/generate-audio/')
  Future<PracticeAudioResponse> generatePracticeAudio(
    @Path('session_id') int sessionId,
    @Body() Map<String, dynamic> request,
  );

  // Get voice samples list
  @GET('samples/voice-samples/')
  Future<PaginatedVoiceSampleList> getVoiceSamplesList({
    @Query('page') int? page,
    @Query('ordering') String? ordering,
    @Query('search') String? search,
  });

  // Generate accent twin (create new accent twin directly)
  @POST('samples/accent-twins/')
  Future<AccentTwin> createAccentTwin(
    @Body() AccentTwinCreateRequest request,
  );

  // Check accent twin status
  @GET('samples/accent-twins/{twin_id}/status/')
  Future<AccentTwinStatusResponse> getAccentTwinStatus(@Path('twin_id') int twinId);

  // Get accent twins list
  @GET('samples/accent-twins/')
  Future<PaginatedAccentTwinList> getAccentTwinsList({
    @Query('page') int? page,
    @Query('ordering') String? ordering,
    @Query('search') String? search,
  });

  // Get specific accent twin
  @GET('samples/accent-twins/{id}/')
  Future<AccentTwin> getAccentTwin(@Path('id') int id);

  // Compare accent twin with original
  @POST('samples/accent-twins/{twin_id}/compare/')
  Future<AccentTwinComparison> compareAccentTwin(
    @Path('twin_id') int twinId,
    @Body() Map<String, dynamic> request,
  );

  // Get available accents
  @GET('samples/accent-twins/available-accents/')
  Future<List<String>> getAvailableAccents();

  // Training endpoints (updated to match new API)
  @GET('samples/training-sessions/')
  Future<PaginatedTrainingSessionList> getTrainingSessions({
    @Query('page') int? page,
    @Query('ordering') String? ordering,
    @Query('search') String? search,
  });

  @POST('samples/training-sessions/')
  Future<TrainingSession> createTrainingSession(@Body() Map<String, dynamic> request);

  @GET('samples/training-sessions/{id}/')
  Future<TrainingSession> getTrainingSession(@Path('id') int id);

  @PUT('samples/training-sessions/{id}/')
  Future<TrainingSession> updateTrainingSession(@Path('id') int id, @Body() Map<String, dynamic> request);

  @PATCH('samples/training-sessions/{id}/')
  Future<TrainingSession> partialUpdateTrainingSession(@Path('id') int id, @Body() Map<String, dynamic> request);

  @DELETE('samples/training-sessions/{id}/')
  Future<void> deleteTrainingSession(@Path('id') int id);

  @POST('samples/training-sessions/{session_id}/complete/')
  Future<TrainingSessionCompleteResponse> completeTrainingSession(@Path('session_id') int sessionId);

  // Progress endpoints
  @GET('samples/progress/')
  Future<UserProgressResponse> getUserProgress({
    @Query('target_accent') String? targetAccent,
  });

  @GET('samples/progress/details/')
  Future<UserProgress> getUserProgressDetails();

  @PUT('samples/progress/details/')
  Future<UserProgress> updateUserProgress(@Body() Map<String, dynamic> request);

  @PATCH('samples/progress/details/')
  Future<UserProgress> partialUpdateUserProgress(@Body() Map<String, dynamic> request);

  // Recommendations
  @GET('samples/recommendations/')
  Future<RecommendationsResponse> getRecommendations();

  // Statistics
  @GET('samples/statistics/accents/')
  Future<AccentStatisticsResponse> getAccentStatistics();

  // TTS Status
  @GET('samples/tts/status/')
  Future<TtsStatusResponse> getTtsStatus();

  // Audio quality inspection (multipart)
  @POST('samples/audio/inspect/')
  @MultiPart()
  Future<Map<String, dynamic>> inspectAudioQuality(@Part() File file);

  // Consent APIs
  @POST('samples/consent/record/')
  Future<Map<String, dynamic>> recordConsent(@Body() Map<String, dynamic> body);

  @GET('samples/consent/check/')
  Future<Map<String, dynamic>> checkConsent(
    @Query('consent_type') String consentType, [
    @Query('voice_sample_id') int? voiceSampleId,
  ]);

  @GET('samples/consent/history/')
  Future<Map<String, dynamic>> getConsentHistory();

  @POST('samples/consent/{consent_id}/revoke/')
  Future<Map<String, dynamic>> revokeConsent(@Path('consent_id') int consentId);
}
