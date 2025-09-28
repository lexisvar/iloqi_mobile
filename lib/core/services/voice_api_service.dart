import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/voice_models.dart';

part 'voice_api_service.g.dart';

@RestApi(baseUrl: 'http://172.20.10.13:8000/api/')
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
  Future<VoiceSample> getAnalysisResults(@Path('sample_id') int sampleId);

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

  // Training endpoints
  @POST('training/session/')
  Future<TrainingSession> createTrainingSession(@Body() Map<String, dynamic> request);

  @GET('training/session/{id}/')
  Future<TrainingSession> getTrainingSession(@Path('id') String id);

  @PUT('training/session/{id}/')
  @MultiPart()
  Future<TrainingSession> submitTrainingRecording(
    @Path('id') String id,
    @Part() File recording,
  );

  @GET('training/sessions/')
  Future<List<TrainingSession>> getTrainingSessions({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
    @Query('training_type') String? trainingType,
    @Query('target_accent') String? targetAccent,
  });

  @GET('training/progress/')
  Future<UserProgress> getUserProgress();
}
