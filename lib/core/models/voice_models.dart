import 'package:json_annotation/json_annotation.dart';

part 'voice_models.g.dart';

@JsonSerializable()
class VoiceSample {
  final int id;
  final String user;
  @JsonKey(name: 'user_username')
  final String userUsername;
  @JsonKey(name: 'file_url')
  final String fileUrl;
  @JsonKey(name: 'original_filename')
  final String originalFilename;
  @JsonKey(name: 'file_size')
  final int? fileSize;
  final double? duration;
  @JsonKey(name: 'sample_rate')
  final int? sampleRate;
  final int? channels;
  @JsonKey(name: 'is_analyzed')
  final bool isAnalyzed;
  @JsonKey(name: 'analysis_data')
  final Map<String, dynamic>? analysisData;
  @JsonKey(name: 'analysis_timestamp')
  final String? analysisTimestamp;
  @JsonKey(name: 'analysis_summary')
  final String? analysisSummary;
  @JsonKey(name: 'prompt_text')
  final String? promptText;
  @JsonKey(name: 'target_accent')
  final String? targetAccent;
  @JsonKey(name: 'training_session')
  final int? trainingSession;
  @JsonKey(name: 'needs_reanalysis')
  final bool needsReanalysis;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const VoiceSample({
    required this.id,
    required this.user,
    required this.userUsername,
    required this.fileUrl,
    required this.originalFilename,
    this.fileSize,
    this.duration,
    this.sampleRate,
    this.channels,
    required this.isAnalyzed,
    this.analysisData,
    this.analysisTimestamp,
    this.analysisSummary,
    this.promptText,
    this.targetAccent,
    this.trainingSession,
    required this.needsReanalysis,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VoiceSample.fromJson(Map<String, dynamic> json) => _$VoiceSampleFromJson(json);
  Map<String, dynamic> toJson() => _$VoiceSampleToJson(this);
}

@JsonSerializable()
class VoiceAnalysisResponse {
  final String status;
  final String message;
  final AnalysisData analysis;

  const VoiceAnalysisResponse({
    required this.status,
    required this.message,
    required this.analysis,
  });

  factory VoiceAnalysisResponse.fromJson(Map<String, dynamic> json) => _$VoiceAnalysisResponseFromJson(json);
  Map<String, dynamic> toJson() => _$VoiceAnalysisResponseToJson(this);
}

@JsonSerializable()
class VoiceAnalysisResultsResponse {
  final String status;
  final bool analyzed;
  final AnalysisData? analysis;
  final String? message;

  const VoiceAnalysisResultsResponse({
    required this.status,
    required this.analyzed,
    this.analysis,
    this.message,
  });

  factory VoiceAnalysisResultsResponse.fromJson(Map<String, dynamic> json) => _$VoiceAnalysisResultsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$VoiceAnalysisResultsResponseToJson(this);
}

@JsonSerializable()
class VoiceAnalysis {
  final String status;
  final String message;
  final AnalysisData analysis;

  const VoiceAnalysis({
    required this.status,
    required this.message,
    required this.analysis,
  });

  factory VoiceAnalysis.fromJson(Map<String, dynamic> json) => _$VoiceAnalysisFromJson(json);
  Map<String, dynamic> toJson() => _$VoiceAnalysisToJson(this);

  // Convenience getters for backward compatibility
  String get id => analysis.hashCode.toString();
  String get transcription => analysis.transcription;
  String get detectedAccent => analysis.detectedAccent;
  double get confidence => analysis.confidenceScore;
  double get audioQuality => analysis.overallScore;
  double get pronunciationScore => analysis.pronunciationScore;
  double get duration => analysis.audioFeatures.duration;
  int get sampleRate => 44100; // Default sample rate
  double? get snrDb => analysis.audioFeatures.snrEstimate;
  String get createdAt => DateTime.now().toIso8601String();
  String get updatedAt => DateTime.now().toIso8601String();
}

@JsonSerializable()
class AnalysisData {
  final String transcription;
  @JsonKey(name: 'confidence_score')
  final double confidenceScore;
  @JsonKey(name: 'detected_accent')
  final String detectedAccent;
  @JsonKey(name: 'accent_confidence')
  final double accentConfidence;
  @JsonKey(name: 'overall_score')
  final double overallScore;
  @JsonKey(name: 'pronunciation_score')
  final double pronunciationScore;
  @JsonKey(name: 'fluency_score')
  final double fluencyScore;
  final List<String> feedback;
  @JsonKey(name: 'phoneme_issues')
  final List<dynamic> phonemeIssues;
  @JsonKey(name: 'audio_features')
  final AudioFeatures audioFeatures;

  const AnalysisData({
    required this.transcription,
    required this.confidenceScore,
    required this.detectedAccent,
    required this.accentConfidence,
    required this.overallScore,
    required this.pronunciationScore,
    required this.fluencyScore,
    required this.feedback,
    required this.phonemeIssues,
    required this.audioFeatures,
  });

  factory AnalysisData.fromJson(Map<String, dynamic> json) => _$AnalysisDataFromJson(json);
  Map<String, dynamic> toJson() => _$AnalysisDataToJson(this);
}

@JsonSerializable()
class AudioFeatures {
  final List<double> mfcc;
  @JsonKey(name: 'spectral_centroid')
  final double spectralCentroid;
  @JsonKey(name: 'spectral_rolloff')
  final double spectralRolloff;
  @JsonKey(name: 'zero_crossing_rate')
  final double zeroCrossingRate;
  @JsonKey(name: 'fundamental_frequency')
  final double fundamentalFrequency;
  @JsonKey(name: 'rms_energy')
  final double rmsEnergy;
  final double tempo;
  final double duration;
  @JsonKey(name: 'snr_estimate')
  final double snrEstimate;

  const AudioFeatures({
    required this.mfcc,
    required this.spectralCentroid,
    required this.spectralRolloff,
    required this.zeroCrossingRate,
    required this.fundamentalFrequency,
    required this.rmsEnergy,
    required this.tempo,
    required this.duration,
    required this.snrEstimate,
  });

  factory AudioFeatures.fromJson(Map<String, dynamic> json) => _$AudioFeaturesFromJson(json);
  Map<String, dynamic> toJson() => _$AudioFeaturesToJson(this);
}

@JsonSerializable()
class AccentTwinComparison {
  @JsonKey(name: 'similarity_score')
  final double similarityScore;
  @JsonKey(name: 'comparison_details')
  final Map<String, dynamic> comparisonDetails;
  final String status;
  final String message;

  const AccentTwinComparison({
    required this.similarityScore,
    required this.comparisonDetails,
    required this.status,
    required this.message,
  });

  factory AccentTwinComparison.fromJson(Map<String, dynamic> json) => _$AccentTwinComparisonFromJson(json);
  Map<String, dynamic> toJson() => _$AccentTwinComparisonToJson(this);
}

@JsonSerializable()
class AccentTwinResponse {
  final String status;
  final String message;
  @JsonKey(name: 'accent_twin')
  final AccentTwin accentTwin;
  @JsonKey(name: 'generation_info')
  final Map<String, dynamic>? generationInfo;

  const AccentTwinResponse({
    required this.status,
    required this.message,
    required this.accentTwin,
    this.generationInfo,
  });

  factory AccentTwinResponse.fromJson(Map<String, dynamic> json) => _$AccentTwinResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AccentTwinResponseToJson(this);
}

@JsonSerializable()
class GenerationInfo {
  final String provider;
  @JsonKey(name: 'voice_model')
  final String voiceModel;
  @JsonKey(name: 'processing_time')
  final double? processingTime;
  @JsonKey(name: 'file_size')
  final int? fileSize;

  const GenerationInfo({
    required this.provider,
    required this.voiceModel,
    this.processingTime,
    this.fileSize,
  });

  factory GenerationInfo.fromJson(Map<String, dynamic> json) => _$GenerationInfoFromJson(json);
  Map<String, dynamic> toJson() => _$GenerationInfoToJson(this);
}

@JsonSerializable()
class AccentTwin {
  final int? id; // Made optional for creation responses
  final String? user; // Made optional for creation responses
  @JsonKey(name: 'user_username')
  final String? userUsername; // Made optional for creation responses
  @JsonKey(name: 'original_sample')
  final int originalSample;
  @JsonKey(name: 'target_accent')
  final String targetAccent;
  @JsonKey(name: 'tts_provider')
  final String ttsProvider;
  @JsonKey(name: 'voice_model')
  final String voiceModel;
  @JsonKey(name: 'generation_status')
  final String? generationStatus; // Made optional for creation responses
  @JsonKey(name: 'accent_twin_file')
  final String? accentTwinFile;
  @JsonKey(name: 'file_url')
  final String? fileUrl;
  @JsonKey(name: 'generation_params')
  final Map<String, dynamic> generationParams;
  @JsonKey(name: 'processing_time')
  final double? processingTime;
  @JsonKey(name: 'error_message')
  final String? errorMessage; // Made optional for creation responses
  @JsonKey(name: 'similarity_score')
  final double? similarityScore;
  @JsonKey(name: 'phoneme_gaps')
  final Map<String, dynamic>? phonemeGaps; // Made optional for creation responses
  @JsonKey(name: 'is_ready')
  final bool? isReady; // Made optional for creation responses
  @JsonKey(name: 'created_at')
  final String? createdAt; // Made optional for creation responses
  @JsonKey(name: 'updated_at')
  final String? updatedAt; // Made optional for creation responses

  const AccentTwin({
    this.id,
    this.user,
    this.userUsername,
    required this.originalSample,
    required this.targetAccent,
    required this.ttsProvider,
    required this.voiceModel,
    this.generationStatus,
    this.accentTwinFile,
    this.fileUrl,
    required this.generationParams,
    this.processingTime,
    this.errorMessage,
    this.similarityScore,
    this.phonemeGaps,
    this.isReady,
    this.createdAt,
    this.updatedAt,
  });

  factory AccentTwin.fromJson(Map<String, dynamic> json) => _$AccentTwinFromJson(json);
  Map<String, dynamic> toJson() => _$AccentTwinToJson(this);
}

@JsonSerializable()
@JsonSerializable()
class TrainingSession {
  final int id;
  final String user;
  @JsonKey(name: 'user_username')
  final String userUsername;
  final String name;
  @JsonKey(name: 'exercise_type')
  final String exerciseType;
  @JsonKey(name: 'target_accent')
  final String targetAccent;
  @JsonKey(name: 'prompt_text')
  final String promptText;
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @JsonKey(name: 'session_score')
  final double? sessionScore;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  @JsonKey(name: 'sample_count')
  final int sampleCount;
  @JsonKey(name: 'analyzed_sample_count')
  final int analyzedSampleCount;
  @JsonKey(name: 'completion_percentage')
  final int completionPercentage;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'completed_at')
  final String? completedAt;

  const TrainingSession({
    required this.id,
    required this.user,
    required this.userUsername,
    required this.name,
    required this.exerciseType,
    required this.targetAccent,
    required this.promptText,
    required this.isCompleted,
    this.sessionScore,
    this.durationMinutes,
    required this.sampleCount,
    required this.analyzedSampleCount,
    required this.completionPercentage,
    required this.createdAt,
    this.completedAt,
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

@JsonSerializable()
class PaginatedVoiceSampleList {
  final int count;
  final String? next;
  final String? previous;
  final List<VoiceSample> results;

  const PaginatedVoiceSampleList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedVoiceSampleList.fromJson(Map<String, dynamic> json) => _$PaginatedVoiceSampleListFromJson(json);
  Map<String, dynamic> toJson() => _$PaginatedVoiceSampleListToJson(this);
}

@JsonSerializable()
class PaginatedAccentTwinList {
  final int count;
  final String? next;
  final String? previous;
  final List<AccentTwin> results;

  const PaginatedAccentTwinList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedAccentTwinList.fromJson(Map<String, dynamic> json) => _$PaginatedAccentTwinListFromJson(json);
  Map<String, dynamic> toJson() => _$PaginatedAccentTwinListToJson(this);
}

@JsonSerializable()
class PaginatedTrainingSessionList {
  final int count;
  final String? next;
  final String? previous;
  final List<TrainingSession> results;

  const PaginatedTrainingSessionList({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedTrainingSessionList.fromJson(Map<String, dynamic> json) => _$PaginatedTrainingSessionListFromJson(json);
  Map<String, dynamic> toJson() => _$PaginatedTrainingSessionListToJson(this);
}

@JsonSerializable()
class AccentTwinCreateRequest {
  @JsonKey(name: 'original_sample')
  final int originalSample;
  @JsonKey(name: 'target_accent')
  final String targetAccent;
  @JsonKey(name: 'tts_provider')
  final String? ttsProvider;
  @JsonKey(name: 'voice_model')
  final String? voiceModel;
  @JsonKey(name: 'generation_params')
  final Map<String, dynamic>? generationParams;

  const AccentTwinCreateRequest({
    required this.originalSample,
    required this.targetAccent,
    this.ttsProvider,
    this.voiceModel,
    this.generationParams,
  });

  factory AccentTwinCreateRequest.fromJson(Map<String, dynamic> json) => _$AccentTwinCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AccentTwinCreateRequestToJson(this);
}

@JsonSerializable()
class AccentTwinStatusResponse {
  final String status;
  final String? message;
  @JsonKey(name: 'accent_twin')
  final AccentTwin accentTwin;
  @JsonKey(name: 'generation_info')
  final Map<String, dynamic>? generationInfo;

  const AccentTwinStatusResponse({
    required this.status,
    this.message,
    required this.accentTwin,
    this.generationInfo,
  });

  factory AccentTwinStatusResponse.fromJson(Map<String, dynamic> json) => _$AccentTwinStatusResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AccentTwinStatusResponseToJson(this);
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

@JsonSerializable()
class TrainingSessionCompleteResponse {
  final String status;
  final String message;
  @JsonKey(name: 'session_score')
  final double? sessionScore;
  @JsonKey(name: 'completion_time')
  final String? completionTime;

  const TrainingSessionCompleteResponse({
    required this.status,
    required this.message,
    this.sessionScore,
    this.completionTime,
  });

  factory TrainingSessionCompleteResponse.fromJson(Map<String, dynamic> json) =>
      _$TrainingSessionCompleteResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TrainingSessionCompleteResponseToJson(this);
}

@JsonSerializable()
class UserProgressResponse {
  final String status;
  @JsonKey(name: 'target_accent')
  final String? targetAccent;
  @JsonKey(name: 'total_sessions')
  final int totalSessions;
  @JsonKey(name: 'completed_sessions')
  final int completedSessions;
  @JsonKey(name: 'average_score')
  final double averageScore;
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  @JsonKey(name: 'best_streak')
  final int bestStreak;
  @JsonKey(name: 'improvement_trend')
  final List<double> improvementTrend;
  @JsonKey(name: 'last_practice_date')
  final String? lastPracticeDate;

  const UserProgressResponse({
    required this.status,
    this.targetAccent,
    required this.totalSessions,
    required this.completedSessions,
    required this.averageScore,
    required this.currentStreak,
    required this.bestStreak,
    required this.improvementTrend,
    this.lastPracticeDate,
  });

  factory UserProgressResponse.fromJson(Map<String, dynamic> json) =>
      _$UserProgressResponseFromJson(json);
  Map<String, dynamic> toJson() => _$UserProgressResponseToJson(this);
}

@JsonSerializable()
class RecommendationsResponse {
  final String status;
  final List<Map<String, dynamic>> recommendations;
  @JsonKey(name: 'personalized_tips')
  final List<String> personalizedTips;
  @JsonKey(name: 'next_session_suggestion')
  final Map<String, dynamic>? nextSessionSuggestion;

  const RecommendationsResponse({
    required this.status,
    required this.recommendations,
    required this.personalizedTips,
    this.nextSessionSuggestion,
  });

  factory RecommendationsResponse.fromJson(Map<String, dynamic> json) =>
      _$RecommendationsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RecommendationsResponseToJson(this);
}

@JsonSerializable()
class AccentStatisticsResponse {
  final String status;
  @JsonKey(name: 'total_analyses')
  final int totalAnalyses;
  @JsonKey(name: 'accent_distribution')
  final Map<String, int> accentDistribution;
  @JsonKey(name: 'average_scores')
  final Map<String, double> averageScores;
  @JsonKey(name: 'popular_accents')
  final List<String> popularAccents;
  @JsonKey(name: 'improvement_rates')
  final Map<String, double> improvementRates;

  const AccentStatisticsResponse({
    required this.status,
    required this.totalAnalyses,
    required this.accentDistribution,
    required this.averageScores,
    required this.popularAccents,
    required this.improvementRates,
  });

  factory AccentStatisticsResponse.fromJson(Map<String, dynamic> json) =>
      _$AccentStatisticsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AccentStatisticsResponseToJson(this);
}

@JsonSerializable()
class TtsStatusResponse {
  final String status;
  @JsonKey(name: 'tts_provider')
  final String ttsProvider;
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @JsonKey(name: 'queue_length')
  final int queueLength;
  @JsonKey(name: 'processing_time_avg')
  final double processingTimeAvg;
  @JsonKey(name: 'success_rate')
  final double successRate;
  @JsonKey(name: 'last_health_check')
  final String lastHealthCheck;

  const TtsStatusResponse({
    required this.status,
    required this.ttsProvider,
    required this.isAvailable,
    required this.queueLength,
    required this.processingTimeAvg,
    required this.successRate,
    required this.lastHealthCheck,
  });

  factory TtsStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$TtsStatusResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TtsStatusResponseToJson(this);
}

@JsonSerializable()
class AccentRecommendation {
  @JsonKey(name: 'accent_code')
  final String accentCode;
  @JsonKey(name: 'accent_name')
  final String accentName;
  final String difficulty;
  @JsonKey(name: 'difficulty_score')
  final double difficultyScore;
  final List<String> reasons;
  @JsonKey(name: 'phonetic_similarities')
  final List<String> phoneticSimilarities;
  @JsonKey(name: 'phonetic_challenges')
  final List<String> phoneticChallenges;
  @JsonKey(name: 'estimated_learning_time')
  final String estimatedLearningTime;
  @JsonKey(name: 'success_probability')
  final double successProbability;

  const AccentRecommendation({
    required this.accentCode,
    required this.accentName,
    required this.difficulty,
    required this.difficultyScore,
    required this.reasons,
    required this.phoneticSimilarities,
    required this.phoneticChallenges,
    required this.estimatedLearningTime,
    required this.successProbability,
  });

  factory AccentRecommendation.fromJson(Map<String, dynamic> json) => _$AccentRecommendationFromJson(json);
  Map<String, dynamic> toJson() => _$AccentRecommendationToJson(this);
}

@JsonSerializable()
class AccentRecommendationsResponse {
  final String status;
  final List<AccentRecommendation> recommendations;
  @JsonKey(name: 'user_profile')
  final Map<String, dynamic> userProfile;

  const AccentRecommendationsResponse({
    required this.status,
    required this.recommendations,
    required this.userProfile,
  });

  factory AccentRecommendationsResponse.fromJson(Map<String, dynamic> json) => _$AccentRecommendationsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AccentRecommendationsResponseToJson(this);
}

@JsonSerializable()
class PracticeSessionCreateRequest {
  @JsonKey(name: 'target_accent')
  final String targetAccent;
  @JsonKey(name: 'voice_gender')
  final String voiceGender;
  @JsonKey(name: 'tts_provider')
  final String? ttsProvider;
  @JsonKey(name: 'session_name')
  final String? sessionName;

  const PracticeSessionCreateRequest({
    required this.targetAccent,
    required this.voiceGender,
    this.ttsProvider,
    this.sessionName,
  });

  factory PracticeSessionCreateRequest.fromJson(Map<String, dynamic> json) => _$PracticeSessionCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PracticeSessionCreateRequestToJson(this);
}

@JsonSerializable()
class PracticeSessionResponse {
  final String status;
  final String message;
  final TrainingSession session;
  @JsonKey(name: 'practice_info')
  final Map<String, dynamic> practiceInfo;

  const PracticeSessionResponse({
    required this.status,
    required this.message,
    required this.session,
    required this.practiceInfo,
  });

  factory PracticeSessionResponse.fromJson(Map<String, dynamic> json) => _$PracticeSessionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PracticeSessionResponseToJson(this);
}

@JsonSerializable()
class PracticeAudioResponse {
  final String status;
  @JsonKey(name: 'audio_url')
  final String audioUrl;
  @JsonKey(name: 'generation_info')
  final Map<String, dynamic> generationInfo;

  const PracticeAudioResponse({
    required this.status,
    required this.audioUrl,
    required this.generationInfo,
  });

  factory PracticeAudioResponse.fromJson(Map<String, dynamic> json) => _$PracticeAudioResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PracticeAudioResponseToJson(this);
}

@JsonSerializable()
class ReanalyzeRequest {
  @JsonKey(name: 'prompt_text')
  final String? promptText;
  @JsonKey(name: 'force_complete_reanalysis')
  final bool? forceCompleteReanalysis;

  const ReanalyzeRequest({
    this.promptText,
    this.forceCompleteReanalysis,
  });

  factory ReanalyzeRequest.fromJson(Map<String, dynamic> json) => _$ReanalyzeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ReanalyzeRequestToJson(this);
}
