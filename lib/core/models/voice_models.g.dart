// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceSample _$VoiceSampleFromJson(Map<String, dynamic> json) => VoiceSample(
      id: (json['id'] as num).toInt(),
      user: json['user'] as String,
      userUsername: json['user_username'] as String,
      fileUrl: json['file_url'] as String,
      originalFilename: json['original_filename'] as String,
      fileSize: (json['file_size'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toDouble(),
      sampleRate: (json['sample_rate'] as num?)?.toInt(),
      channels: (json['channels'] as num?)?.toInt(),
      isAnalyzed: json['is_analyzed'] as bool,
      analysisData: json['analysis_data'] as Map<String, dynamic>?,
      analysisTimestamp: json['analysis_timestamp'] as String?,
      analysisSummary: json['analysis_summary'] as String?,
      promptText: json['prompt_text'] as String?,
      targetAccent: json['target_accent'] as String?,
      trainingSession: (json['training_session'] as num?)?.toInt(),
      needsReanalysis: json['needs_reanalysis'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$VoiceSampleToJson(VoiceSample instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'user_username': instance.userUsername,
      'file_url': instance.fileUrl,
      'original_filename': instance.originalFilename,
      'file_size': instance.fileSize,
      'duration': instance.duration,
      'sample_rate': instance.sampleRate,
      'channels': instance.channels,
      'is_analyzed': instance.isAnalyzed,
      'analysis_data': instance.analysisData,
      'analysis_timestamp': instance.analysisTimestamp,
      'analysis_summary': instance.analysisSummary,
      'prompt_text': instance.promptText,
      'target_accent': instance.targetAccent,
      'training_session': instance.trainingSession,
      'needs_reanalysis': instance.needsReanalysis,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

VoiceAnalysisResponse _$VoiceAnalysisResponseFromJson(
        Map<String, dynamic> json) =>
    VoiceAnalysisResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      analysis: AnalysisData.fromJson(json['analysis'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VoiceAnalysisResponseToJson(
        VoiceAnalysisResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'analysis': instance.analysis,
    };

VoiceAnalysisResultsResponse _$VoiceAnalysisResultsResponseFromJson(
        Map<String, dynamic> json) =>
    VoiceAnalysisResultsResponse(
      status: json['status'] as String,
      analyzed: json['analyzed'] as bool,
      analysis: json['analysis'] == null
          ? null
          : AnalysisData.fromJson(json['analysis'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$VoiceAnalysisResultsResponseToJson(
        VoiceAnalysisResultsResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'analyzed': instance.analyzed,
      'analysis': instance.analysis,
      'message': instance.message,
    };

VoiceAnalysis _$VoiceAnalysisFromJson(Map<String, dynamic> json) =>
    VoiceAnalysis(
      status: json['status'] as String,
      message: json['message'] as String,
      analysis: AnalysisData.fromJson(json['analysis'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VoiceAnalysisToJson(VoiceAnalysis instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'analysis': instance.analysis,
    };

AnalysisData _$AnalysisDataFromJson(Map<String, dynamic> json) => AnalysisData(
      transcription: json['transcription'] as String,
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      detectedAccent: json['detected_accent'] as String,
      accentConfidence: (json['accent_confidence'] as num).toDouble(),
      overallScore: (json['overall_score'] as num).toDouble(),
      pronunciationScore: (json['pronunciation_score'] as num).toDouble(),
      fluencyScore: (json['fluency_score'] as num).toDouble(),
      feedback:
          (json['feedback'] as List<dynamic>).map((e) => e as String).toList(),
      phonemeIssues: json['phoneme_issues'] as List<dynamic>,
      audioFeatures: AudioFeatures.fromJson(
          json['audio_features'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AnalysisDataToJson(AnalysisData instance) =>
    <String, dynamic>{
      'transcription': instance.transcription,
      'confidence_score': instance.confidenceScore,
      'detected_accent': instance.detectedAccent,
      'accent_confidence': instance.accentConfidence,
      'overall_score': instance.overallScore,
      'pronunciation_score': instance.pronunciationScore,
      'fluency_score': instance.fluencyScore,
      'feedback': instance.feedback,
      'phoneme_issues': instance.phonemeIssues,
      'audio_features': instance.audioFeatures,
    };

AudioFeatures _$AudioFeaturesFromJson(Map<String, dynamic> json) =>
    AudioFeatures(
      mfcc: (json['mfcc'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      spectralCentroid: (json['spectral_centroid'] as num).toDouble(),
      spectralRolloff: (json['spectral_rolloff'] as num).toDouble(),
      zeroCrossingRate: (json['zero_crossing_rate'] as num).toDouble(),
      fundamentalFrequency: (json['fundamental_frequency'] as num).toDouble(),
      rmsEnergy: (json['rms_energy'] as num).toDouble(),
      tempo: (json['tempo'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      snrEstimate: (json['snr_estimate'] as num).toDouble(),
    );

Map<String, dynamic> _$AudioFeaturesToJson(AudioFeatures instance) =>
    <String, dynamic>{
      'mfcc': instance.mfcc,
      'spectral_centroid': instance.spectralCentroid,
      'spectral_rolloff': instance.spectralRolloff,
      'zero_crossing_rate': instance.zeroCrossingRate,
      'fundamental_frequency': instance.fundamentalFrequency,
      'rms_energy': instance.rmsEnergy,
      'tempo': instance.tempo,
      'duration': instance.duration,
      'snr_estimate': instance.snrEstimate,
    };

AccentTwinComparison _$AccentTwinComparisonFromJson(
        Map<String, dynamic> json) =>
    AccentTwinComparison(
      similarityScore: (json['similarity_score'] as num).toDouble(),
      comparisonDetails: json['comparison_details'] as Map<String, dynamic>,
      status: json['status'] as String,
      message: json['message'] as String,
    );

Map<String, dynamic> _$AccentTwinComparisonToJson(
        AccentTwinComparison instance) =>
    <String, dynamic>{
      'similarity_score': instance.similarityScore,
      'comparison_details': instance.comparisonDetails,
      'status': instance.status,
      'message': instance.message,
    };

AccentTwinResponse _$AccentTwinResponseFromJson(Map<String, dynamic> json) =>
    AccentTwinResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      accentTwin:
          AccentTwin.fromJson(json['accent_twin'] as Map<String, dynamic>),
      generationInfo: json['generation_info'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AccentTwinResponseToJson(AccentTwinResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'accent_twin': instance.accentTwin,
      'generation_info': instance.generationInfo,
    };

GenerationInfo _$GenerationInfoFromJson(Map<String, dynamic> json) =>
    GenerationInfo(
      provider: json['provider'] as String,
      voiceModel: json['voice_model'] as String,
      processingTime: (json['processing_time'] as num?)?.toDouble(),
      fileSize: (json['file_size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GenerationInfoToJson(GenerationInfo instance) =>
    <String, dynamic>{
      'provider': instance.provider,
      'voice_model': instance.voiceModel,
      'processing_time': instance.processingTime,
      'file_size': instance.fileSize,
    };

AccentTwin _$AccentTwinFromJson(Map<String, dynamic> json) => AccentTwin(
      id: (json['id'] as num?)?.toInt(),
      user: json['user'] as String?,
      userUsername: json['user_username'] as String?,
      originalSample: (json['original_sample'] as num).toInt(),
      targetAccent: json['target_accent'] as String,
      ttsProvider: json['tts_provider'] as String,
      voiceModel: json['voice_model'] as String,
      generationStatus: json['generation_status'] as String?,
      accentTwinFile: json['accent_twin_file'] as String?,
      fileUrl: json['file_url'] as String?,
      generationParams: json['generation_params'] as Map<String, dynamic>,
      processingTime: (json['processing_time'] as num?)?.toDouble(),
      errorMessage: json['error_message'] as String?,
      similarityScore: (json['similarity_score'] as num?)?.toDouble(),
      phonemeGaps: json['phoneme_gaps'] as Map<String, dynamic>?,
      isReady: json['is_ready'] as bool?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );

Map<String, dynamic> _$AccentTwinToJson(AccentTwin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'user_username': instance.userUsername,
      'original_sample': instance.originalSample,
      'target_accent': instance.targetAccent,
      'tts_provider': instance.ttsProvider,
      'voice_model': instance.voiceModel,
      'generation_status': instance.generationStatus,
      'accent_twin_file': instance.accentTwinFile,
      'file_url': instance.fileUrl,
      'generation_params': instance.generationParams,
      'processing_time': instance.processingTime,
      'error_message': instance.errorMessage,
      'similarity_score': instance.similarityScore,
      'phoneme_gaps': instance.phonemeGaps,
      'is_ready': instance.isReady,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

TrainingSession _$TrainingSessionFromJson(Map<String, dynamic> json) =>
    TrainingSession(
      id: (json['id'] as num).toInt(),
      user: json['user'] as String,
      userUsername: json['user_username'] as String,
      name: json['name'] as String,
      exerciseType: json['exercise_type'] as String,
      targetAccent: json['target_accent'] as String,
      promptText: json['prompt_text'] as String,
      isCompleted: json['is_completed'] as bool,
      sessionScore: (json['session_score'] as num?)?.toDouble(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      sampleCount: (json['sample_count'] as num).toInt(),
      analyzedSampleCount: (json['analyzed_sample_count'] as num).toInt(),
      completionPercentage: (json['completion_percentage'] as num).toInt(),
      createdAt: json['created_at'] as String,
      completedAt: json['completed_at'] as String?,
    );

Map<String, dynamic> _$TrainingSessionToJson(TrainingSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'user_username': instance.userUsername,
      'name': instance.name,
      'exercise_type': instance.exerciseType,
      'target_accent': instance.targetAccent,
      'prompt_text': instance.promptText,
      'is_completed': instance.isCompleted,
      'session_score': instance.sessionScore,
      'duration_minutes': instance.durationMinutes,
      'sample_count': instance.sampleCount,
      'analyzed_sample_count': instance.analyzedSampleCount,
      'completion_percentage': instance.completionPercentage,
      'created_at': instance.createdAt,
      'completed_at': instance.completedAt,
    };

UserProgress _$UserProgressFromJson(Map<String, dynamic> json) => UserProgress(
      totalSessions: (json['total_sessions'] as num).toInt(),
      avgScore: (json['avg_score'] as num).toDouble(),
      currentStreak: (json['current_streak'] as num).toInt(),
      bestStreak: (json['best_streak'] as num).toInt(),
      totalPracticeTime: (json['total_practice_time'] as num).toInt(),
      improvementRate: (json['improvement_rate'] as num).toDouble(),
    );

Map<String, dynamic> _$UserProgressToJson(UserProgress instance) =>
    <String, dynamic>{
      'total_sessions': instance.totalSessions,
      'avg_score': instance.avgScore,
      'current_streak': instance.currentStreak,
      'best_streak': instance.bestStreak,
      'total_practice_time': instance.totalPracticeTime,
      'improvement_rate': instance.improvementRate,
    };

PaginatedVoiceSampleList _$PaginatedVoiceSampleListFromJson(
        Map<String, dynamic> json) =>
    PaginatedVoiceSampleList(
      count: (json['count'] as num).toInt(),
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => VoiceSample.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaginatedVoiceSampleListToJson(
        PaginatedVoiceSampleList instance) =>
    <String, dynamic>{
      'count': instance.count,
      'next': instance.next,
      'previous': instance.previous,
      'results': instance.results,
    };

PaginatedAccentTwinList _$PaginatedAccentTwinListFromJson(
        Map<String, dynamic> json) =>
    PaginatedAccentTwinList(
      count: (json['count'] as num).toInt(),
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => AccentTwin.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaginatedAccentTwinListToJson(
        PaginatedAccentTwinList instance) =>
    <String, dynamic>{
      'count': instance.count,
      'next': instance.next,
      'previous': instance.previous,
      'results': instance.results,
    };

PaginatedTrainingSessionList _$PaginatedTrainingSessionListFromJson(
        Map<String, dynamic> json) =>
    PaginatedTrainingSessionList(
      count: (json['count'] as num).toInt(),
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => TrainingSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaginatedTrainingSessionListToJson(
        PaginatedTrainingSessionList instance) =>
    <String, dynamic>{
      'count': instance.count,
      'next': instance.next,
      'previous': instance.previous,
      'results': instance.results,
    };

AccentTwinCreateRequest _$AccentTwinCreateRequestFromJson(
        Map<String, dynamic> json) =>
    AccentTwinCreateRequest(
      originalSample: (json['original_sample'] as num).toInt(),
      targetAccent: json['target_accent'] as String,
      ttsProvider: json['tts_provider'] as String?,
      voiceModel: json['voice_model'] as String?,
      generationParams: json['generation_params'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AccentTwinCreateRequestToJson(
        AccentTwinCreateRequest instance) =>
    <String, dynamic>{
      'original_sample': instance.originalSample,
      'target_accent': instance.targetAccent,
      'tts_provider': instance.ttsProvider,
      'voice_model': instance.voiceModel,
      'generation_params': instance.generationParams,
    };

AccentTwinStatusResponse _$AccentTwinStatusResponseFromJson(
        Map<String, dynamic> json) =>
    AccentTwinStatusResponse(
      status: json['status'] as String,
      message: json['message'] as String?,
      accentTwin:
          AccentTwin.fromJson(json['accent_twin'] as Map<String, dynamic>),
      generationInfo: json['generation_info'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AccentTwinStatusResponseToJson(
        AccentTwinStatusResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'accent_twin': instance.accentTwin,
      'generation_info': instance.generationInfo,
    };

TrainingSessionCompleteResponse _$TrainingSessionCompleteResponseFromJson(
        Map<String, dynamic> json) =>
    TrainingSessionCompleteResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      sessionScore: (json['session_score'] as num?)?.toDouble(),
      completionTime: json['completion_time'] as String?,
    );

Map<String, dynamic> _$TrainingSessionCompleteResponseToJson(
        TrainingSessionCompleteResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'session_score': instance.sessionScore,
      'completion_time': instance.completionTime,
    };

UserProgressResponse _$UserProgressResponseFromJson(
        Map<String, dynamic> json) =>
    UserProgressResponse(
      status: json['status'] as String,
      targetAccent: json['target_accent'] as String?,
      totalSessions: (json['total_sessions'] as num).toInt(),
      completedSessions: (json['completed_sessions'] as num).toInt(),
      averageScore: (json['average_score'] as num).toDouble(),
      currentStreak: (json['current_streak'] as num).toInt(),
      bestStreak: (json['best_streak'] as num).toInt(),
      improvementTrend: (json['improvement_trend'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      lastPracticeDate: json['last_practice_date'] as String?,
    );

Map<String, dynamic> _$UserProgressResponseToJson(
        UserProgressResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'target_accent': instance.targetAccent,
      'total_sessions': instance.totalSessions,
      'completed_sessions': instance.completedSessions,
      'average_score': instance.averageScore,
      'current_streak': instance.currentStreak,
      'best_streak': instance.bestStreak,
      'improvement_trend': instance.improvementTrend,
      'last_practice_date': instance.lastPracticeDate,
    };

RecommendationsResponse _$RecommendationsResponseFromJson(
        Map<String, dynamic> json) =>
    RecommendationsResponse(
      status: json['status'] as String,
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      personalizedTips: (json['personalized_tips'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      nextSessionSuggestion:
          json['next_session_suggestion'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$RecommendationsResponseToJson(
        RecommendationsResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'recommendations': instance.recommendations,
      'personalized_tips': instance.personalizedTips,
      'next_session_suggestion': instance.nextSessionSuggestion,
    };

AccentStatisticsResponse _$AccentStatisticsResponseFromJson(
        Map<String, dynamic> json) =>
    AccentStatisticsResponse(
      status: json['status'] as String,
      totalAnalyses: (json['total_analyses'] as num).toInt(),
      accentDistribution:
          Map<String, int>.from(json['accent_distribution'] as Map),
      averageScores: (json['average_scores'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      popularAccents: (json['popular_accents'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      improvementRates: (json['improvement_rates'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$AccentStatisticsResponseToJson(
        AccentStatisticsResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'total_analyses': instance.totalAnalyses,
      'accent_distribution': instance.accentDistribution,
      'average_scores': instance.averageScores,
      'popular_accents': instance.popularAccents,
      'improvement_rates': instance.improvementRates,
    };

TtsStatusResponse _$TtsStatusResponseFromJson(Map<String, dynamic> json) =>
    TtsStatusResponse(
      status: json['status'] as String,
      ttsProvider: json['tts_provider'] as String,
      isAvailable: json['is_available'] as bool,
      queueLength: (json['queue_length'] as num).toInt(),
      processingTimeAvg: (json['processing_time_avg'] as num).toDouble(),
      successRate: (json['success_rate'] as num).toDouble(),
      lastHealthCheck: json['last_health_check'] as String,
    );

Map<String, dynamic> _$TtsStatusResponseToJson(TtsStatusResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'tts_provider': instance.ttsProvider,
      'is_available': instance.isAvailable,
      'queue_length': instance.queueLength,
      'processing_time_avg': instance.processingTimeAvg,
      'success_rate': instance.successRate,
      'last_health_check': instance.lastHealthCheck,
    };

AccentRecommendation _$AccentRecommendationFromJson(
        Map<String, dynamic> json) =>
    AccentRecommendation(
      accentCode: json['accent_code'] as String,
      accentName: json['accent_name'] as String,
      difficulty: json['difficulty'] as String,
      difficultyScore: (json['difficulty_score'] as num).toDouble(),
      reasons:
          (json['reasons'] as List<dynamic>).map((e) => e as String).toList(),
      phoneticSimilarities: (json['phonetic_similarities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      phoneticChallenges: (json['phonetic_challenges'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      estimatedLearningTime: json['estimated_learning_time'] as String,
      successProbability: (json['success_probability'] as num).toDouble(),
    );

Map<String, dynamic> _$AccentRecommendationToJson(
        AccentRecommendation instance) =>
    <String, dynamic>{
      'accent_code': instance.accentCode,
      'accent_name': instance.accentName,
      'difficulty': instance.difficulty,
      'difficulty_score': instance.difficultyScore,
      'reasons': instance.reasons,
      'phonetic_similarities': instance.phoneticSimilarities,
      'phonetic_challenges': instance.phoneticChallenges,
      'estimated_learning_time': instance.estimatedLearningTime,
      'success_probability': instance.successProbability,
    };

AccentRecommendationsResponse _$AccentRecommendationsResponseFromJson(
        Map<String, dynamic> json) =>
    AccentRecommendationsResponse(
      status: json['status'] as String,
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => AccentRecommendation.fromJson(e as Map<String, dynamic>))
          .toList(),
      userProfile: json['user_profile'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$AccentRecommendationsResponseToJson(
        AccentRecommendationsResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'recommendations': instance.recommendations,
      'user_profile': instance.userProfile,
    };

PracticeSessionCreateRequest _$PracticeSessionCreateRequestFromJson(
        Map<String, dynamic> json) =>
    PracticeSessionCreateRequest(
      targetAccent: json['target_accent'] as String,
      voiceGender: json['voice_gender'] as String,
      ttsProvider: json['tts_provider'] as String?,
      sessionName: json['session_name'] as String?,
    );

Map<String, dynamic> _$PracticeSessionCreateRequestToJson(
        PracticeSessionCreateRequest instance) =>
    <String, dynamic>{
      'target_accent': instance.targetAccent,
      'voice_gender': instance.voiceGender,
      'tts_provider': instance.ttsProvider,
      'session_name': instance.sessionName,
    };

PracticeSessionResponse _$PracticeSessionResponseFromJson(
        Map<String, dynamic> json) =>
    PracticeSessionResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      session:
          TrainingSession.fromJson(json['session'] as Map<String, dynamic>),
      practiceInfo: json['practice_info'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$PracticeSessionResponseToJson(
        PracticeSessionResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'session': instance.session,
      'practice_info': instance.practiceInfo,
    };

PracticeAudioResponse _$PracticeAudioResponseFromJson(
        Map<String, dynamic> json) =>
    PracticeAudioResponse(
      status: json['status'] as String,
      audioUrl: json['audio_url'] as String,
      generationInfo: json['generation_info'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$PracticeAudioResponseToJson(
        PracticeAudioResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'audio_url': instance.audioUrl,
      'generation_info': instance.generationInfo,
    };

ReanalyzeRequest _$ReanalyzeRequestFromJson(Map<String, dynamic> json) =>
    ReanalyzeRequest(
      promptText: json['prompt_text'] as String?,
      forceCompleteReanalysis: json['force_complete_reanalysis'] as bool?,
    );

Map<String, dynamic> _$ReanalyzeRequestToJson(ReanalyzeRequest instance) =>
    <String, dynamic>{
      'prompt_text': instance.promptText,
      'force_complete_reanalysis': instance.forceCompleteReanalysis,
    };
