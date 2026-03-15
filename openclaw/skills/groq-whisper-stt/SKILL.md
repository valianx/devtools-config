---
name: groq-whisper-stt
description: Transcribe audio via Groq Whisper API (STT).
homepage: https://console.groq.com/docs/speech-text
metadata:
  clawdbot: '{"emoji":"🎙️","requires":{"bins":["curl"],"env":["GROQ_API_KEY"]},"primaryEnv":"GROQ_API_KEY"}'
---

# Groq Whisper STT

Transcribe an audio file via Groq's `/v1/audio/transcriptions` endpoint.

## Quick start

```bash
{baseDir}/scripts/transcribe.sh /path/to/audio.m4a
```

Defaults:
- Model: `whisper-large-v3`
- Output: `<input>.txt`

## Useful flags

```bash
{baseDir}/scripts/transcribe.sh /path/to/audio.ogg --model whisper-large-v3-turbo --out /tmp/transcript.txt
{baseDir}/scripts/transcribe.sh /path/to/audio.m4a --language en
{baseDir}/scripts/transcribe.sh /path/to/audio.m4a --prompt "Speaker names: Peter, Daniel"
{baseDir}/scripts/transcribe.sh /path/to/audio.m4a --json --out /tmp/transcript.json
```

## API key

Set `GROQ_API_KEY`, or configure it in `~/.clawdbot/clawdbot.json`:

```json5
{
  skills: {
    "groq-whisper-stt": {
      apiKey: "GROQ_KEY_HERE"
    }
  }
}
```
