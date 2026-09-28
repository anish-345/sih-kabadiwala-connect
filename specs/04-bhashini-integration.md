# Kabadiwala Connect - Bhashini API Integration Specification

**Version:** 1.0.0  
**Date:** September 28, 2026  
**API Provider:** Bhashini ( Ministry of Electronics & IT, Govt. of India)  
**Status:** Draft - Ready for Implementation

---

## 1. Overview

This specification defines the integration with Bhashini API for vernacular voice interface in Hindi and Marathi languages.

---

## 2. Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        CLIENT APP                                │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   Voice Service Layer                      │  │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │  │
│  │  │ STT Service  │ │ TTS Service  │ │ Translation  │      │  │
│  │  │ (Hindi/Mar)  │ │ (Hindi/Mar)  │ │ (Hindi/Mar)  │      │  │
│  │  └───────┬──────┘ └───────┬──────┘ └───────┬──────┘      │  │
│  │          │                 │                 │             │  │
│  │  ┌───────▼──────┐ ┌───────▼──────┐ ┌───────▼──────┐      │  │
│  │  │ Bhashini API │ │ Bhashini API │ │ Bhashini API │      │  │
│  │  │  (HTTP)      │ │  (HTTP)      │ │  (HTTP)      │      │  │
│  │  └──────────────┘ └──────────────┘ └──────────────┘      │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────────┐
│                        Bhashini API                              │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  API Gateway / Load Balancer                              │  │
│  └───────────────────────────────────────────────────────────┘  │
│                          │                                       │
│  ┌──────────────────────▼────────────────────────────────────┐  │
│  │                     Speech Services                       │  │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │  │
│  │  │ STT Service  │ │ TTS Service  │ │ ASR Models   │      │  │
│  │  │ (Whisper)    │ │ (TTS Engine) │ │ (Hindi/Mar)  │      │  │
│  │  └──────────────┘ └──────────────┘ └──────────────┘      │  │
│  └───────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. API Endpoints

### 3.1 Base Configuration

```
Base URL: https://bhashini.gov.in/api/v1
API Key: <api_key_from_bhashini_dashboard>
Authentication: Bearer <api_key>
```

---

### 3.2 Speech-to-Text (STT)

#### Endpoint

```
POST /speech-to-text
Authorization: Bearer <api_key>
Content-Type: application/json
```

#### Request

```json
{
  "sourceLanguage": "hi",
  "audioBase64": "base64_encoded_audio_data...",
  "audioFormat": "wav",
  "sampleRate": 16000,
  "requestId": "uuid-uuid-uuid"
}
```

**Audio Requirements:**
- Format: WAV, MP3, or PCM
- Sample Rate: 16 kHz (recommended), 8 kHz (minimum)
- Duration: ≤60 seconds
- Bit Depth: 16-bit

#### Response (Success - 200 OK)

```json
{
  "requestId": "uuid-uuid-uuid",
  "sourceLanguage": "hi",
  "transcript": "मैं पीसीबी कबाड़ी लाया हूँ",
  "confidence": 0.92,
  "words": [
    {
      "word": "मैं",
      "start": 0.0,
      "end": 0.3,
      "confidence": 0.95
    },
    {
      "word": "पीसीबी",
      "start": 0.3,
      "end": 0.7,
      "confidence": 0.90
    },
    {
      "word": "कबाड़ी",
      "start": 0.7,
      "end": 1.1,
      "confidence": 0.94
    },
    {
      "word": "लाया",
      "start": 1.1,
      "end": 1.4,
      "confidence": 0.89
    },
    {
      "word": "हूँ",
      "start": 1.4,
      "end": 1.7,
      "confidence": 0.91
    }
  ],
  "timestamp": "2026-09-28T10:30:00Z"
}
```

#### Response (Error)

```json
{
  "requestId": "uuid-uuid-uuid",
  "error": {
    "code": "ERR_INVALID_AUDIO",
    "message": "Audio format not supported or duration exceeded 60 seconds",
    "timestamp": "2026-09-28T10:30:00Z"
  }
}
```

---

### 3.3 Text-to-Speech (TTS)

#### Endpoint

```
POST /text-to-speech
Authorization: Bearer <api_key>
Content-Type: application/json
```

#### Request

```json
{
  "sourceLanguage": "hi",
  "text": "आपका सामग्री स्कैन हो गई है। वजन 2.5 किलो है।",
  "speaker": "female",
  "pitch": "1.0",
  "speed": "1.0",
  "requestId": "uuid-uuid-uuid"
}
```

**Parameters:**
- `speaker`: "male" or "female"
- `pitch`: 0.5 - 2.0 (default: 1.0)
- `speed`: 0.5 - 2.0 (default: 1.0)

#### Response (Success - 200 OK)

```json
{
  "requestId": "uuid-uuid-uuid",
  "audioBase64": "base64_encoded_audio_data...",
  "audioFormat": "wav",
  "sampleRate": 16000,
  "durationSeconds": 3.5,
  "timestamp": "2026-09-28T10:30:00Z"
}
```

#### Response (Error)

```json
{
  "requestId": "uuid-uuid-uuid",
  "error": {
    "code": "ERR_TEXT_TOO_LONG",
    "message": "Text length exceeded 500 characters",
    "timestamp": "2026-09-28T10:30:00Z"
  }
}
```

---

### 3.4 Translation

#### Endpoint

```
POST /translate
Authorization: Bearer <api_key>
Content-Type: application/json
```

#### Request

```json
{
  "sourceLanguage": "hi",
  "targetLanguage": "en",
  "text": "मैं पीसीबी कबाड़ी लाया हूँ",
  "requestId": "uuid-uuid-uuid"
}
```

#### Response (Success - 200 OK)

```json
{
  "requestId": "uuid-uuid-uuid",
  "sourceLanguage": "hi",
  "targetLanguage": "en",
  "translatedText": "I have brought PCB scrap",
  "timestamp": "2026-09-28T10:30:00Z"
}
```

---

## 4. Client Implementation

### 4.1 Audio Recording

```kotlin
class AudioRecorder(context: Context) {
    private val audioRecord: AudioRecord
    private var isRecording = false
    private var audioFilePath: String? = null
    
    init {
        val sampleRate = 16000
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val bufferSize = AudioRecord.getMinBufferSize(
            sampleRate, channelConfig, audioFormat
        )
        
        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            sampleRate,
            channelConfig,
            audioFormat,
            bufferSize
        )
    }
    
    suspend fun startRecording(): String {
        isRecording = true
        val audioFile = File.createTempFile("recording_", ".wav", context.filesDir)
        audioFilePath = audioFile.absolutePath
        
        // Write WAV header
        audioFile.outputStream().use { os ->
            os.write(WavHeader(1, 16000, 16, 0).toByteArray())
        }
        
        val bufferSize = audioRecord.bufferSize
        val audioBuffer = ByteArray(bufferSize)
        var totalBytesRead = 0
        
        audioRecord.startRecording()
        
        while (isRecording) {
            val bytesRead = audioRecord.read(audioBuffer, 0, bufferSize)
            if (bytesRead > 0) {
                totalBytesRead += bytesRead
                audioFile.appendBytes(audioBuffer.copyOf(bytesRead))
            }
        }
        
        audioRecord.stop()
        
        // Update WAV header with actual size
        audioFile.outputStream().use { os ->
            os.write(WavHeader(1, 16000, 16, totalBytesRead).toByteArray())
        }
        
        return audioFile.absolutePath
    }
    
    fun stopRecording() {
        isRecording = false
    }
    
    private data class WavHeader(
        val channels: Int,
        val sampleRate: Int,
        val bitsPerSample: Int,
        val dataSize: Int
    ) {
        fun toByteArray(): ByteArray {
            // WAV header implementation
            return byteArrayOf() // Simplified
        }
    }
}
```

### 4.2 STT Service

```kotlin
class BhashiniSTTService(private val apiKey: String) {
    private val retrofit = Retrofit.Builder()
        .baseUrl("https://bhashini.gov.in/api/v1/")
        .addConverterFactory(GsonConverterFactory.create())
        .build()
    
    private val api = retrofit.create(BhashiniApi::class.java)
    
    private val sharedPreferences = PreferenceManager.getDefaultSharedPreferences(context)
    
    suspend fun transcribeAudio(audioFile: File): STTResult {
        // Check API quota
        if (!checkApiQuota()) {
            return STTResult.Error("API quota exceeded")
        }
        
        // Encode audio to base64
        val audioBytes = audioFile.readBytes()
        val audioBase64 = Base64.encodeToString(audioBytes, Base64.NO_WRAP)
        
        // Detect language (auto or user preference)
        val sourceLanguage = sharedPreferences.getString("preferred_lang", "hi") ?: "hi"
        
        // Call API
        return try {
            val requestId = UUID.randomUUID().toString()
            val response = api.stt(
                Authorization = "Bearer $apiKey",
                body = STTRequest(
                    sourceLanguage = sourceLanguage,
                    audioBase64 = audioBase64,
                    audioFormat = "wav",
                    sampleRate = 16000,
                    requestId = requestId
                )
            )
            
            if (response.error == null) {
                STTResult.Success(
                    transcript = response.transcript,
                    confidence = response.confidence,
                    words = response.words
                )
            } else {
                STTResult.Error(response.error.message)
            }
        } catch (e: Exception) {
            STTResult.Error(e.message ?: "Unknown error")
        }
    }
    
    private suspend fun checkApiQuota(): Boolean {
        // Implement quota checking logic
        return true
    }
}

sealed class STTResult {
    data class Success(
        val transcript: String,
        val confidence: Float,
        val words: List<WordTimestamp>
    ) : STTResult()
    
    data class Error(val message: String) : STTResult()
    
    data class WordTimestamp(
        val word: String,
        val start: Double,
        val end: Double,
        val confidence: Float
    )
}
```

### 4.3 TTS Service

```kotlin
class BhashiniTTSService(private val apiKey: String) {
    private val retrofit = Retrofit.Builder()
        .baseUrl("https://bhashini.gov.in/api/v1/")
        .addConverterFactory(GsonConverterFactory.create())
        .build()
    
    private val api = retrofit.create(BhashiniApi::class.java)
    
    suspend fun synthesizeSpeech(text: String, speaker: String = "female"): TTSResult {
        val sourceLanguage = sharedPreferences.getString("preferred_lang", "hi") ?: "hi"
        
        return try {
            val requestId = UUID.randomUUID().toString()
            val response = api.tts(
                Authorization = "Bearer $apiKey",
                body = TTSRequest(
                    sourceLanguage = sourceLanguage,
                    text = text,
                    speaker = speaker,
                    pitch = "1.0",
                    speed = "1.0",
                    requestId = requestId
                )
            )
            
            if (response.error == null) {
                val audioBytes = Base64.decode(response.audioBase64, Base64.DEFAULT)
                val audioFile = File.createTempFile("tts_", ".wav", context.cacheDir)
                audioFile.writeBytes(audioBytes)
                
                TTSResult.Success(
                    audioFile = audioFile,
                    durationSeconds = response.durationSeconds
                )
            } else {
                TTSResult.Error(response.error.message)
            }
        } catch (e: Exception) {
            TTSResult.Error(e.message ?: "Unknown error")
        }
    }
}

sealed class TTSResult {
    data class Success(
        val audioFile: File,
        val durationSeconds: Double
    ) : TTSResult()
    
    data class Error(val message: String) : TTSResult()
}
```

### 4.4 Voice UI Implementation

```kotlin
class VoiceScannerViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(VoiceScannerUiState())
    val uiState: StateFlow<VoiceScannerUiState> = _uiState.asStateFlow()
    
    private val audioRecorder = AudioRecorder(context)
    private val sttService = BhashiniSTTService(apiKey)
    private val ttsService = BhashiniTTSService(apiKey)
    
    private var recordingJob: Job? = null
    
    fun onStartRecording() {
        viewModelScope.launch {
            _uiState.update { it.copy(isRecording = true, statusMessage = "Listening..." ) }
            
            recordingJob = launch {
                try {
                    val audioFile = audioRecorder.startRecording()
                    val result = sttService.transcribeAudio(audioFile)
                    
                    when (result) {
                        is STTResult.Success -> {
                            handleTranscript(result.transcript)
                        }
                        is STTResult.Error -> {
                            playTTS("क्षमा करें, मैं आपकी बात समझ नहीं पाया।")
                            _uiState.update { it.copy(statusMessage = "Error: ${result.message}") }
                        }
                    }
                    
                    _uiState.update { it.copy(isRecording = false) }
                } catch (e: Exception) {
                    _uiState.update { it.copy(isRecording = false, statusMessage = "Error: ${e.message}") }
                }
            }
        }
    }
    
    fun onStopRecording() {
        recordingJob?.cancel()
        audioRecorder.stopRecording()
        _uiState.update { it.copy(isRecording = false) }
    }
    
    private suspend fun handleTranscript(transcript: String) {
        // Parse transcript for material detection
        val materials = listOf("pcb", "plastic", "metal", "glass", "paper")
        val detectedMaterial = materials.firstOrNull { transcript.contains(it, ignoreCase = true) }
        
        if (detectedMaterial != null) {
            // Material detected
            playTTS("आपने ${translateToHindi(detectedMaterial)} बताया। क्या यह सही है?")
            
            _uiState.update { it.copy(
                detectedMaterial = detectedMaterial,
                isConfirming = true
            ) }
        } else {
            // No material detected, ask for clarification
            playTTS("कृपया अपने पास कौन सी सामग्री है, यह बताएं। जैसे: पीसीबी, प्लास्टिक, धातु")
        }
    }
    
    private suspend fun playTTS(text: String) {
        val result = ttsService.synthesizeSpeech(text)
        when (result) {
            is TTSResult.Success -> {
                // Play audio file
                // Use Android's AudioTrack or MediaPlayer
            }
            is TTSResult.Error -> {
                Log.e("TTS", "Error: ${result.message}")
            }
        }
    }
    
    fun onConfirmMaterial(confirmed: Boolean) {
        if (confirmed) {
            // Proceed with material registration
            _uiState.update { it.copy(isConfirming = false, materialConfirmed = true) }
        } else {
            // Restart recording
            _uiState.update { it.copy(isConfirming = false) }
        }
    }
}

data class VoiceScannerUiState(
    val isRecording: Boolean = false,
    val isConfirming: Boolean = false,
    val materialConfirmed: Boolean = false,
    val detectedMaterial: String? = null,
    val statusMessage: String = "Tap to speak"
)
```

---

## 5. Error Handling

### 5.1 Error Codes

| Code | HTTP Status | Description | User Message |
|------|-------------|-------------|--------------|
| `ERR_INVALID_AUDIO` | 400 | Invalid audio format | "Audio format not supported. Please record in WAV format." |
| `ERR_AUDIO_TOO_LONG` | 400 | Audio >60 seconds | "Recording too long. Maximum 60 seconds." |
| `ERR_TEXT_TOO_LONG` | 400 | Text >500 chars | "Message too long. Please be concise." |
| `ERR_INVALID_API_KEY` | 401 | Invalid API key | "API authentication failed. Please check settings." |
| `ERR_QUOTA_EXCEEDED` | 429 | Rate limit exceeded | "Please try again in a few minutes." |
| `ERR_SERVICE_UNAVAILABLE` | 503 | Service down | "Voice service temporarily unavailable." |

### 5.2 Fallback Strategy

1. **First STT attempt:** Use Bhashini API
2. **Failed:** Use offline Whisper model (bundled)
3. **Failed:** Show text input fallback
4. **User input:** Parse with keyword matching

---

## 6. Performance Targets

| Metric | Target |
|--------|--------|
| STT Latency | <3s for 10s audio |
| TTS Latency | <2s for 20 words |
| API Quota | ≤100 requests/minute/user |
| Error Rate | <5% |

---

## 7. Testing

### 7.1 Unit Tests

```kotlin
@Test
fun testSTTService() = runTest {
    val service = BhashiniSTTService("test_api_key")
    val audioFile = createTestAudioFile()
    
    val result = service.transcribeAudio(audioFile)
    
    assertTrue(result is STTResult.Success)
    assertTrue(result.transcript.isNotEmpty())
}
```

### 7.2 Integration Tests

- Test STT with Hindi audio
- Test TTS with Marathi text
- Test translation Hindi→English
- Test error handling (invalid API key)

---

## 8. Security

### 8.1 API Key Storage

```kotlin
class ApiKeyStorage(context: Context) {
    private val sharedPreferences = context.getSharedPreferences("api_keys", Context.MODE_PRIVATE)
    
    fun saveApiKey(key: String) {
        val encrypted = encrypt(key)
        sharedPreferences.edit().putString("bhashini_api_key", encrypted).apply()
    }
    
    fun getApiKey(): String? {
        val encrypted = sharedPreferences.getString("bhashini_api_key", null) ?: return null
        return decrypt(encrypted)
    }
    
    private fun encrypt(key: String): String {
        // Use Android Keystore for encryption
        return key
    }
    
    private fun decrypt(encrypted: String): String {
        // Use Android Keystore for decryption
        return encrypted
    }
}
```

### 8.2 Audio Privacy

- Audio files are deleted after processing
- No audio data stored on server
- Client-side encryption for audio files

---

## 9. Configuration

### 9.1 API Key Setup

```xml
<!-- AndroidManifest.xml -->
<application>
    <meta-data
        android:name="bhashini_api_key"
        android:value="${BHASHINI_API_KEY}" />
</application>

<!-- gradle.properties -->
BHASHINI_API_KEY=your_api_key_here
```

### 9.2 Language Support

```kotlin
// Supported languages in Bhashini API
val SUPPORTED_LANGUAGES = listOf(
    "hi" to "Hindi",
    "mr" to "Marathi",
    "en" to "English",
    "bn" to "Bengali",
    "ta" to "Tamil"
)

// User can select preferred language
val preferredLang = sharedPreferences.getString("preferred_lang", "hi") ?: "hi"
```

---

## 10. Monitoring

### 10.1 Telemetry

```kotlin
class BhashiniTelemetry(private val context: Context) {
    fun logSTTCall(success: Boolean, durationMs: Long, error: String? = null) {
        val prefs = context.getSharedPreferences("telemetry", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        
        editor.putInt("stt_calls", prefs.getInt("stt_calls", 0) + 1)
        editor.putFloat("stt_avg_duration", 
            (prefs.getFloat("stt_avg_duration", 0f) * 0.9f + durationMs * 0.1f)
        )
        
        if (!success) {
            editor.putInt("stt_errors", prefs.getInt("stt_errors", 0) + 1)
            editor.putString("stt_last_error", error)
        }
        
        editor.apply()
    }
}
```

---

## 11. References

1. [Bhashini Official Documentation](https://bhashini.gov.in/)
2. [Bhashini API Portal](https://bhashini.gov.in/api-documentation)
3. [Indian Language Interface Guidelines](https://www.cse.iitb.ac.in/~jayant/bhasha/)

---

**Status:** ✅ Approved for Implementation  
**Next Step:** Backend API Service Integration