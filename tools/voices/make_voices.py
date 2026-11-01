"""Machine voices for the Life Tools phrases (Tigrinya + Amharic) with Meta's open MMS-TTS models.
Runs once on the PC; the mp3 files go to public/games/life-tools/voice/<ti|am>/<id>.mp3.
Recorded voices (made on the recording page) always win over these in the game.

  python tools/voices/make_voices.py            all phrases, both languages (skips files that exist)
  python tools/voices/make_voices.py --test     only the first phrase of each language
"""
import json, os, re, sys
import numpy as np
import torch, lameenc
from transformers import VitsModel, AutoTokenizer

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', '..', 'public', 'games', 'life-tools', 'voice')
MODELS = {'ti': 'facebook/mms-tts-tir', 'am': 'facebook/mms-tts-amh'}
test = '--test' in sys.argv

phrases = json.load(open(os.path.join(HERE, 'phrases.json'), encoding='utf-8'))
try:
    import uroman as ur
    ROMAN = ur.Uroman()
except Exception:
    ROMAN = None


def to_mp3(wave, rate):
    pcm = (np.clip(wave, -1, 1) * 32767).astype(np.int16).tobytes()
    enc = lameenc.Encoder()
    enc.set_bit_rate(64); enc.set_in_sample_rate(rate); enc.set_channels(1); enc.set_quality(2)
    return enc.encode(pcm) + enc.flush()


for lang, name in MODELS.items():
    tok = AutoTokenizer.from_pretrained(name)
    model = VitsModel.from_pretrained(name)
    model.eval()
    torch.manual_seed(7)
    os.makedirs(os.path.join(OUT, lang), exist_ok=True)
    made = 0
    for p in phrases[:1] if test else phrases:
        text = p[lang]
        dest = os.path.join(OUT, lang, p['id'] + '.mp3')
        if not text or (os.path.exists(dest) and not test):
            continue
        clean = re.sub(r'[!?¡¿.,;:«»"()]', ' ', text).strip()
        if getattr(tok, 'is_uroman', False) and ROMAN:
            clean = ROMAN.romanize_string(clean)
        ids = tok(clean, return_tensors='pt')
        with torch.no_grad():
            wave = model(**ids).waveform[0].numpy()
        # a little silence before and after
        pad = np.zeros(int(model.config.sampling_rate * 0.15), dtype=wave.dtype)
        open(dest, 'wb').write(to_mp3(np.concatenate([pad, wave, pad]), model.config.sampling_rate))
        made += 1
    print(lang, 'uroman' if getattr(tok, 'is_uroman', False) else 'geez', made, 'files')
