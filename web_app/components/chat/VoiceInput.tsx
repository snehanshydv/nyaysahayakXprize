import { Mic, Square, MessageSquare, Type } from "lucide-react";
import { useState, useRef, useEffect, forwardRef, useImperativeHandle } from "react";
import { cn } from "@/lib/utils";
import { touchIconButton, touchIconButtonCompact } from "@/lib/motion";

export type VoiceMode = "dictation" | "conversation";

interface VoiceInputProps {
  onTranscription: (text: string, mode: VoiceMode, languageCode?: string) => void;
  isProcessing?: boolean;
  /** Compact dark styling for admin toolbars (e.g. LangGraph tester). */
  variant?: "default" | "admin";
}

export interface VoiceInputRef {
  startRecording: () => void;
  stopRecording: () => void;
  mode: VoiceMode;
}

export const VoiceInput = forwardRef<VoiceInputRef, VoiceInputProps>(
  ({ onTranscription, isProcessing, variant = "default" }, ref) => {
  const admin = variant === "admin";
  const [isRecording, setIsRecording] = useState(false);
  const [mode, setMode] = useState<VoiceMode>("dictation");
  const audioContextRef = useRef<AudioContext | null>(null);
  const animationFrameRef = useRef<number | null>(null);

  // Refs for raw PCM capture
  const pcmBufferRef = useRef<Float32Array[]>([]);
  const streamRef = useRef<MediaStream | null>(null);
  const scriptNodeRef = useRef<ScriptProcessorNode | null>(null);

  const startRecording = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
          sampleRate: 16000,
        }
      });
      streamRef.current = stream;
      pcmBufferRef.current = [];

      // --- Use Web Audio API to capture RAW PCM data directly ---
      const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
      const source = audioContext.createMediaStreamSource(stream);
      const analyser = audioContext.createAnalyser();
      analyser.fftSize = 256;
      source.connect(analyser);

      // ScriptProcessorNode to capture raw audio samples
      const scriptNode = audioContext.createScriptProcessor(4096, 1, 1);
      scriptNodeRef.current = scriptNode;
      source.connect(scriptNode);
      scriptNode.connect(audioContext.destination); // required for processing to work

      scriptNode.onaudioprocess = (event) => {
        const inputData = event.inputBuffer.getChannelData(0);
        // Store a copy of the float32 samples
        pcmBufferRef.current.push(new Float32Array(inputData));
      };

      audioContextRef.current = audioContext;

      // --- Volume-based Silence Detection ---
      const bufferLength = analyser.frequencyBinCount;
      const dataArray = new Uint8Array(bufferLength);

      let lastSoundTime = Date.now();
      const startTime = Date.now();
      let hasStartedSpeaking = false;
      const SILENCE_THRESHOLD = 5;
      const SILENCE_DURATION = 3500;
      const MAX_DURATION = 20000;

      const checkVolume = () => {
        if (!streamRef.current || !streamRef.current.active) return;

        if (Date.now() - startTime >= MAX_DURATION) {
          console.log("Max 20s duration reached, turning off mic");
          stopRecording();
          return;
        }

        analyser.getByteFrequencyData(dataArray);

        let sum = 0;
        for (let i = 0; i < bufferLength; i++) sum += dataArray[i];
        const average = sum / bufferLength;

        if (average > SILENCE_THRESHOLD) {
          if (!hasStartedSpeaking) console.log("Speech detected, starting silence countdown...");
          hasStartedSpeaking = true;
          lastSoundTime = Date.now();
        } else if (hasStartedSpeaking) {
          if (Date.now() - lastSoundTime > SILENCE_DURATION) {
            console.log("Silence auto-stop triggered");
            stopRecording();
            return;
          }
        }
        animationFrameRef.current = requestAnimationFrame(checkVolume);
      };

      setIsRecording(true);
      checkVolume();
    } catch (err) {
      console.error("Error accessing microphone:", err);
      alert("Could not access microphone.");
    }
  };

  const handleTranscription = async (audioBlob: Blob) => {
    try {
      console.log(`Sending audio blob: size=${audioBlob.size} bytes, type=${audioBlob.type}`);
      if (audioBlob.size < 5000) {
        console.warn("Audio blob is too small, likely no speech was captured.");
        if (mode === "conversation") {
          startRecording();
        }
        return;
      }

      // Call Sarvam STT directly from the browser (no FastAPI hop).
      const sarvamKey = (process.env.NEXT_PUBLIC_SARVAM_API_KEY || "").trim();
      if (!sarvamKey) {
        throw new Error(
          "NEXT_PUBLIC_SARVAM_API_KEY is not set in web_app/.env.local — required for frontend Sarvam STT"
        );
      }

      const formData = new FormData();
      formData.append("file", audioBlob, "recording.wav");
      formData.append("model", "saaras:v3");
      formData.append("language_code", "unknown"); // Sarvam auto-detects Indian language
      formData.append("mode", "transcribe");

      const response = await fetch("https://api.sarvam.ai/speech-to-text", {
        method: "POST",
        headers: {
          "api-subscription-key": sarvamKey,
        },
        body: formData,
      });

      if (!response.ok) {
        let errMessage = "Sarvam STT error";
        try {
          const errData = await response.json();
          errMessage =
            (typeof errData?.detail === "string" && errData.detail) ||
            (typeof errData?.message === "string" && errData.message) ||
            JSON.stringify(errData) ||
            errMessage;
        } catch {
          try {
            errMessage = await response.text();
          } catch {
            /* ignore */
          }
        }
        throw new Error(`STT failed (${response.status}): ${errMessage}`);
      }

      const data = await response.json();
      console.log("Sarvam STT Full Response:", data);

      const transcriptText =
        data.transcript ||
        data.text ||
        data.data ||
        (data.message && typeof data.message === "string" ? data.message : null);

      if (transcriptText && transcriptText.trim()) {
        // language_code from Sarvam = detected Indian language used for this transcript
        const langCode = data.language_code || "hi-IN";
        onTranscription(transcriptText, mode, langCode);
      } else {
        console.warn("Empty or missing transcript in Sarvam STT response:", data);
        if (mode === "conversation") {
          console.log("Restarting conversation loop after empty transcription detection.");
          startRecording();
        }
      }
    } catch (error: any) {
      console.warn("Transcription failed:", error?.message || error);
      // If we are in conversation mode, pause for 3 seconds then try again to avoid spinning
      if (mode === "conversation") {
        console.log("Retrying conversation mode after error...");
        setTimeout(() => startRecording(), 3000);
      }
    }
  };

  const encodeWav = (samples: Float32Array, sampleRate: number): Blob => {
    const length = samples.length;
    const buffer = new ArrayBuffer(44 + length * 2);
    const view = new DataView(buffer);

    const writeString = (offset: number, str: string) => {
      for (let i = 0; i < str.length; i++) {
        view.setUint8(offset + i, str.charCodeAt(i));
      }
    };

    writeString(0, 'RIFF');
    view.setUint32(4, 36 + length * 2, true);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    view.setUint32(16, 16, true);          // chunk size
    view.setUint16(20, 1, true);           // PCM format
    view.setUint16(22, 1, true);           // mono
    view.setUint32(24, sampleRate, true);   // sample rate
    view.setUint32(28, sampleRate * 2, true); // byte rate
    view.setUint16(32, 2, true);           // block align
    view.setUint16(34, 16, true);          // bits per sample
    writeString(36, 'data');
    view.setUint32(40, length * 2, true);

    let offset = 44;
    for (let i = 0; i < length; i++) {
      const s = Math.max(-1, Math.min(1, samples[i]));
      view.setInt16(offset, s < 0 ? s * 0x8000 : s * 0x7FFF, true);
      offset += 2;
    }

    return new Blob([view], { type: 'audio/wav' });
  };

  const stopRecording = () => {
    if (animationFrameRef.current) cancelAnimationFrame(animationFrameRef.current);

    // Disconnect ScriptProcessorNode
    if (scriptNodeRef.current) {
      scriptNodeRef.current.disconnect();
      scriptNodeRef.current = null;
    }

    // Close AudioContext
    if (audioContextRef.current && audioContextRef.current.state !== 'closed') {
      const sampleRate = audioContextRef.current.sampleRate;
      audioContextRef.current.close();

      // Merge all PCM buffers into a single Float32Array
      const totalLength = pcmBufferRef.current.reduce((acc, buf) => acc + buf.length, 0);
      const mergedBuffer = new Float32Array(totalLength);
      let writeOffset = 0;
      for (const buf of pcmBufferRef.current) {
        mergedBuffer.set(buf, writeOffset);
        writeOffset += buf.length;
      }

      console.log(`PCM capture: ${totalLength} samples at ${sampleRate}Hz = ${(totalLength / sampleRate).toFixed(1)}s, max amplitude: ${Math.max(...mergedBuffer.slice(0, 1000).map(Math.abs))}`);

      // Resample to 16kHz if needed
      let finalSamples = mergedBuffer;
      let finalRate = sampleRate;
      if (sampleRate !== 16000) {
        const ratio = 16000 / sampleRate;
        const newLength = Math.round(totalLength * ratio);
        const resampled = new Float32Array(newLength);
        for (let i = 0; i < newLength; i++) {
          const srcIdx = i / ratio;
          const idx = Math.floor(srcIdx);
          const frac = srcIdx - idx;
          resampled[i] = (1 - frac) * (mergedBuffer[idx] || 0) + frac * (mergedBuffer[idx + 1] || 0);
        }
        finalSamples = resampled;
        finalRate = 16000;
      }

      const wavBlob = encodeWav(finalSamples, finalRate);
      console.log(`WAV blob created: ${wavBlob.size} bytes`);
      handleTranscription(wavBlob);
    }

    // Stop mic stream
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop());
      streamRef.current = null;
    }

    setIsRecording(false);
  };

  useEffect(() => {
    return () => {
      if (animationFrameRef.current) cancelAnimationFrame(animationFrameRef.current);
      if (audioContextRef.current && audioContextRef.current.state !== 'closed') {
        audioContextRef.current.close();
      }
    };
  }, []);

  const toggleMode = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (!isRecording && !isProcessing) {
      setMode(prev => prev === "dictation" ? "conversation" : "dictation");
    }
  };

  useImperativeHandle(ref, () => ({
    startRecording,
    stopRecording,
    mode
  }));

  return (
    <div
      className={cn(
        "flex items-center gap-1 rounded-full border p-1 shadow-sm",
        admin
          ? "border-white/15 bg-zinc-900"
          : "border-gray-100 bg-white dark:border-slate-700 dark:bg-slate-800"
      )}
    >
      <button
        type="button"
        onClick={isRecording ? stopRecording : startRecording}
        disabled={isProcessing}
        className={cn(
          "relative flex items-center justify-center rounded-full transition-[transform,background-color] duration-300",
          admin ? "p-1.5" : cn(touchIconButton, "md:h-auto md:w-auto md:p-2.5"),
          isRecording
            ? "scale-105 animate-pulse bg-red-500 text-white shadow-lg shadow-red-500/30"
            : admin
              ? "text-emerald-300 hover:bg-white/10"
              : "text-[#00634B] hover:bg-[#E6F0ED] dark:hover:bg-emerald-900/30",
          isProcessing ? "cursor-not-allowed opacity-50" : ""
        )}
        title={
          isRecording
            ? "Stop recording"
            : `Voice input (${mode === "dictation" ? "dictation — fill query" : "conversation — send after STT"}). Sarvam auto-detects Indian language.`
        }
      >
        {isRecording ? (
          <Square className={cn("fill-current", admin ? "h-3.5 w-3.5" : "h-4 w-4")} />
        ) : (
          <Mic className={admin ? "h-3.5 w-3.5" : "h-4 w-4"} />
        )}
        {!isRecording && mode === "conversation" && (
          <span
            className={cn(
              "absolute -right-1 -top-1 h-2.5 w-2.5 rounded-full border-2 bg-emerald-500",
              admin ? "border-zinc-900" : "border-white dark:border-slate-800"
            )}
          />
        )}
      </button>

      {/* Mode Toggle Split Button */}
      <button
        type="button"
        onClick={toggleMode}
        disabled={isRecording || isProcessing}
        className={cn(
          "rounded-full transition-colors duration-200",
          admin
            ? "p-1.5 text-white/40 hover:text-white/80"
            : cn(touchIconButtonCompact, "text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 md:p-2"),
          (isRecording || isProcessing) && "cursor-not-allowed opacity-50"
        )}
        title={`Switch to ${mode === "dictation" ? "Conversation" : "Dictation"} mode`}
      >
        {mode === "dictation" ? (
          <Type className="h-3.5 w-3.5" />
        ) : (
          <MessageSquare className={cn("h-3.5 w-3.5", !admin && "text-[#00634B]")} />
        )}
      </button>
    </div>
  );
});
