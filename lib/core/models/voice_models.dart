import 'package:json_annotation/json_annotation.dart';

part 'voice_models.g.dart';

@JsonSerializable()
class VoiceAnalysis {
  final String id;
  @JsonKey(name: 'audio_file')
  final String audioFile;
  final String transcription;
  @JsonKey(name: 'detected_accent')
  final String detectedAccent;
  final double confidence;
  @JsonKey(name: 'audio_quality')
  final double audioQuality;
  final double duration;
  @JsonKey(name: 'sample_rate')
  final int sampleRate;
  @JsonKey(name: 'snr_db')
  final double? snrDb;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const VoiceAnalysis({
    required this.id,
    required this.audioFile,
    required this.transcription,
    required this.detectedAccent,
    required this.confidence,
    required this.audioQuality,
    required this.duration,
    required this.sampleRate,
    this.snrDb,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VoiceAnalysis.fromJson(Map<String, dynamic> json) => _$VoiceAnalysisFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceAnalysisToJson(this);
}

@JsonSerializable()
class AccentTwin {
  final String id;
  @JsonKey(name: 'original_analysis')
  final String originalAnalysisId;
  @JsonKey(name: 'target_accent')
  final String targetAccent;
  @JsonKey(name: 'generated_audio')
  final String generatedAudio;
  @JsonKey(name: 'tts_provider')
  final String ttsProvider;
  @JsonKey(name: 'similarity_score')
  final double? similarityScore;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const AccentTwin({
    required this.id,
    required this.originalAnalysisId,
    required this.targetAccent,
    required this.generatedAudio,
    required this.ttsProvider,
    this.similarityScore,
    required this.createdAt,
  });

  factory AccentTwin.fromJson(Map<String, dynamic> json) => _$AccentTwinFromJson(json);

  Map<String, dynamic> toJson() => _$AccentTwinToJson(this);
}

@JsonSerializable()
class TrainingSession {
  final String id;
  @JsonKey(name: 'training_type')
  final String trainingType;
  @JsonKey(name: 'target_accent')
  final String targetAccent;
  @JsonKey(name: 'content_text')
  final String contentText;
  @JsonKey(name: 'reference_audio')
  final String? referenceAudio;
  @JsonKey(name: 'user_recording')
  final String? userRecording;
  @JsonKey(name: 'feedback_score')
  final double? feedbackScore;
  @JsonKey(name: 'feedback_text')
  final String? feedbackText;
  @JsonKey(name: 'session_duration')
  final int? sessionDuration;
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const TrainingSession({
    required this.id,
    required this.trainingType,
    required this.targetAccent,
    required this.contentText,
    this.referenceAudio,
    this.userRecording,
    this.feedbackScore,
    this.feedbackText,
    this.sessionDuration,
    this.completedAt,
    required this.createdAt,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) => _$TrainingSessionFromJson(json);

  Map<String, dynamic> toJson() => _$TrainingSessionToJson(this);
}

@JsonSerializable()
class UserProgress {
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  @JsonKey(name: 'avg_score')
  final double avgScore;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'best_streak')
  final int bestStreak;
  @JsonKey(name: 'total_practice_time')
  final int totalPracticeTime;
  @JsonKey(name: 'improvement_rate')
  final double improvementRate;

  const UserProgress({
    required this.totalSessions,
    required this.avgScore,
    required this.currentStreak,
    required this.bestStreak,
    required this.totalPracticeTime,
    required this.improvementRate,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) => _$UserProgressFromJson(json);

  Map<String, dynamic> toJson() => _$UserProgressToJson(this);
}

enum SupportedAccent {
  us('US', 'American English'),
  uk('UK', 'British English'),
  au('AU', 'Australian English'),
  ca('CA', 'Canadian English'),
  ie('IE', 'Irish English'),
  indianEnglish('IN', 'Indian English'),
  nz('NZ', 'New Zealand English'),
  za('ZA', 'South African English');

  const SupportedAccent(this.code, this.displayName);

  final String code;
  final String displayName;
}

enum TrainingType {
  pronunciation('pronunciation', 'Pronunciation'),
  rhythm('rhythm', 'Rhythm & Timing'),
  intonation('intonation', 'Intonation'),
  stress('stress', 'Word Stress'),
  connectedSpeech('connected_speech', 'Connected Speech');

  const TrainingType(this.value, this.displayName);

  final String value;
  final String displayName;
}
