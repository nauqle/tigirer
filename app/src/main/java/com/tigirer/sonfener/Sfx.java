package com.tigirer.sonfener;

import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioTrack;

import java.util.Random;

/** Dosyasız ses efektleri: kısa PCM örnekleri çalışma anında üretilir. */
final class Sfx {
    private static final int RATE = 22050;

    private final AudioTrack hit, kill, flash, hurt, dawn, lose, click, boss, overheat;
    private long lastKill, lastHit;
    boolean enabled = true;

    Sfx() {
        Random r = new Random(7);
        hit = make(sweep(520f, 380f, 0.05f, 0.18f, 0.25f, r));
        kill = make(sweep(520f, 1040f, 0.12f, 0.30f, 0.05f, r));
        flash = make(sweep(180f, 1400f, 0.35f, 0.40f, 0.20f, r));
        hurt = make(sweep(140f, 55f, 0.25f, 0.55f, 0.45f, r));
        dawn = make(arpeggio(new float[]{523f, 659f, 784f, 1046f}, 0.16f, 0.35f));
        lose = make(arpeggio(new float[]{392f, 311f, 247f, 165f}, 0.24f, 0.35f));
        click = make(sweep(700f, 900f, 0.05f, 0.25f, 0f, r));
        boss = make(sweep(90f, 45f, 0.9f, 0.55f, 0.35f, r));
        overheat = make(sweep(300f, 120f, 0.22f, 0.30f, 0.35f, r));
    }

    void hit() {
        long now = System.currentTimeMillis();
        if (now - lastHit < 110) return;
        lastHit = now;
        play(hit);
    }

    void kill() {
        long now = System.currentTimeMillis();
        if (now - lastKill < 50) return;
        lastKill = now;
        play(kill);
    }

    void flash() { play(flash); }
    void hurt() { play(hurt); }
    void dawn() { play(dawn); }
    void lose() { play(lose); }
    void click() { play(click); }
    void boss() { play(boss); }
    void overheat() { play(overheat); }

    void release() {
        for (AudioTrack t : new AudioTrack[]{hit, kill, flash, hurt, dawn, lose, click, boss, overheat}) {
            try {
                if (t != null) t.release();
            } catch (RuntimeException ignored) {
            }
        }
    }

    private void play(AudioTrack t) {
        if (!enabled || t == null) return;
        try {
            t.stop();
            t.reloadStaticData();
            t.play();
        } catch (RuntimeException ignored) {
        }
    }

    private static AudioTrack make(short[] data) {
        try {
            AudioTrack t = new AudioTrack.Builder()
                    .setAudioAttributes(new AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_GAME)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build())
                    .setAudioFormat(new AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(RATE)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build())
                    .setBufferSizeInBytes(data.length * 2)
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .build();
            t.write(data, 0, data.length);
            return t;
        } catch (RuntimeException e) {
            return null;
        }
    }

    /** f0'dan f1'e kayan, üstel sönümlü bir ton; noise 0..1 gürültü karışımı. */
    private static short[] sweep(float f0, float f1, float dur, float vol, float noise, Random r) {
        int n = (int) (RATE * dur);
        short[] d = new short[n];
        double phase = 0;
        for (int i = 0; i < n; i++) {
            float p = i / (float) n;
            double f = f0 + (f1 - f0) * p;
            phase += 2 * Math.PI * f / RATE;
            double env = Math.exp(-4.0 * p) * Math.min(1.0, i / 80.0);
            double s = Math.sin(phase) * (1 - noise) + (r.nextDouble() * 2 - 1) * noise;
            d[i] = (short) (s * env * vol * Short.MAX_VALUE);
        }
        return d;
    }

    private static short[] arpeggio(float[] notes, float step, float vol) {
        int per = (int) (RATE * step);
        short[] d = new short[per * notes.length + per];
        for (int k = 0; k < notes.length; k++) {
            double phase = 0;
            for (int i = 0; i < per * 2 && k * per + i < d.length; i++) {
                phase += 2 * Math.PI * notes[k] / RATE;
                double env = Math.exp(-3.0 * i / (per * 2.0)) * Math.min(1.0, i / 60.0);
                int idx = k * per + i;
                d[idx] = (short) Math.max(Short.MIN_VALUE, Math.min(Short.MAX_VALUE,
                        d[idx] + Math.sin(phase) * env * vol * Short.MAX_VALUE));
            }
        }
        return d;
    }
}
