// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceAnalysis _$VoiceAnalysisFromJson(Map<String, dynamic> json) =>
    VoiceAnalysis(
      id: json['id'] as String,
      audioFile: json['audio_file'] as String,
      transcription: json['transcription'] as String,
      detectedAccent: json['detected_accent'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      audioQuality: (json['audio_quality'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      sampleRate: (json['sample_rate'] as num).toInt(),
      snrDb: (json['snr_db'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$VoiceAnalysisToJson(VoiceAnalysis instance) =>
    <String, dynamic>{
      'id': instance.id,
      'audio_file': instance.audioFile,
      'transcription': instance.transcription,
      'detected_accent': instance.detectedAccent,
      'confidence': instance.confidence,
      'audio_quality': instance.audioQuality,
      'duration': instance.duration,
      'sample_rate': instance.sampleRate,
      'snr_db': instance.snrDb,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
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
