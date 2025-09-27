import 'dart:io';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/voice_models.dart';

part 'voice_api_service.g.dart';

@RestApi(baseUrl: 'http://172.20.10.13:8000/api/')
abstract class VoiceApiService {
  factory VoiceApiService(Dio dio, {String baseUrl}) = _VoiceApiService;

  @POST('voice/analyze/')
  @MultiPart()
  Future<VoiceAnalysis> analyzeVoice(@Part() File audioFile);

  @GET('voice/analysis/{id}/')
  Future<VoiceAnalysis> getVoiceAnalysis(@Path('id') String id);

  @GET('voice/analysis/')
  Future<List<VoiceAnalysis>> getVoiceAnalysesList({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  @POST('voice/accent-twin/')
  Future<AccentTwin> generateAccentTwin(@Body() Map<String, dynamic> request);

  @GET('voice/accent-twin/{id}/')
  Future<AccentTwin> getAccentTwin(@Path('id') String id);

  @GET('voice/accent-twin/')
  Future<List<AccentTwin>> getAccentTwinsList({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

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
