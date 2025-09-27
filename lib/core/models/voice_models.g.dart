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

AccentTwin _$AccentTwinFromJson(Map<String, dynamic> json) => AccentTwin(
      id: json['id'] as String,
      originalAnalysisId: json['original_analysis'] as String,
      targetAccent: json['target_accent'] as String,
      generatedAudio: json['generated_audio'] as String,
      ttsProvider: json['tts_provider'] as String,
      similarityScore: (json['similarity_score'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$AccentTwinToJson(AccentTwin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'original_analysis': instance.originalAnalysisId,
      'target_accent': instance.targetAccent,
      'generated_audio': instance.generatedAudio,
      'tts_provider': instance.ttsProvider,
      'similarity_score': instance.similarityScore,
      'created_at': instance.createdAt,
    };

TrainingSession _$TrainingSessionFromJson(Map<String, dynamic> json) =>
    TrainingSession(
      id: json['id'] as String,
      trainingType: json['training_type'] as String,
      targetAccent: json['target_accent'] as String,
      contentText: json['content_text'] as String,
      referenceAudio: json['reference_audio'] as String?,
      userRecording: json['user_recording'] as String?,
      feedbackScore: (json['feedback_score'] as num?)?.toDouble(),
      feedbackText: json['feedback_text'] as String?,
      sessionDuration: (json['session_duration'] as num?)?.toInt(),
      completedAt: json['completed_at'] as String?,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$TrainingSessionToJson(TrainingSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'training_type': instance.trainingType,
      'target_accent': instance.targetAccent,
      'content_text': instance.contentText,
      'reference_audio': instance.referenceAudio,
      'user_recording': instance.userRecording,
      'feedback_score': instance.feedbackScore,
      'feedback_text': instance.feedbackText,
      'session_duration': instance.sessionDuration,
      'completed_at': instance.completedAt,
      'created_at': instance.createdAt,
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
