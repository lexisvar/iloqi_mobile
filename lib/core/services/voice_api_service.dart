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
  @POST('samples/voice-samples/{sampleId}/analyze/')
  Future<VoiceAnalysis> analyzeVoiceSample(@Path('sampleId') int sampleId);

  // Get analysis results
  @GET('samples/voice-samples/{sampleId}/results/')
  Future<VoiceAnalysis> getAnalysisResults(@Path('sampleId') int sampleId);

  // Get voice samples list
  @GET('samples/voice-samples/')
  Future<List<VoiceSample>> getVoiceSamplesList({
    @Query('page') int? page,
    @Query('ordering') String? ordering,
    @Query('search') String? search,
  });

  // Generate accent twin
  @POST('samples/voice-samples/{sampleId}/generate-accent-twin/')
  Future<AccentTwin> generateAccentTwin(
    @Path('sampleId') int sampleId,
    @Body() Map<String, dynamic> request,
  );

  // Get accent twins list
  @GET('samples/accent-twins/')
  Future<List<AccentTwin>> getAccentTwinsList({
    @Query('page') int? page,
    @Query('ordering') String? ordering,
    @Query('search') String? search,
  });

  // Get specific accent twin
  @GET('samples/accent-twins/{id}/')
  Future<AccentTwin> getAccentTwin(@Path('id') int id);

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
