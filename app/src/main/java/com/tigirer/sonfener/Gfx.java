package com.tigirer.sonfener;

import android.graphics.Canvas;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RadialGradient;
import android.graphics.RectF;
import android.graphics.Shader;
import android.graphics.Typeface;

import com.tigirer.sonfener.core.Shadow;
import com.tigirer.sonfener.core.ShadowType;
import com.tigirer.sonfener.core.World;

import java.util.ArrayList;
import java.util.List;

/** Ortak çizim yardımcıları. Tek (arayüz) iş parçacığından kullanılır; paint'ler paylaşılır. */
final class Gfx {
    static final int NAVY = 0xFF070B1A;
    static final int DAWN = 0xFF37306B;
    static final int GOLD = 0xFFFFC857;
    static final int GOLD_SOFT = 0xFFFFE3A3;
    static final int TEXT = 0xFFE8ECF8;
    static final int MUTED = 0xFF8E98B8;
    static final int PANEL = 0xDD121A33;
    static final int PANEL_EDGE = 0xFF2A3560;
    static final int RED = 0xFFE5484D;
    static final int CYAN = 0xFF55D6FF;
    static final int INK = 0xFF1B1405;

    static final Typeface SERIF = Typeface.create("serif", Typeface.NORMAL);
    static final Typeface SERIF_ITALIC = Typeface.create("serif", Typeface.ITALIC);
    static final Typeface SANS_BOLD = Typeface.create("sans-serif", Typeface.BOLD);
    static final Typeface SANS_MED = Typeface.create("sans-serif-medium", Typeface.NORMAL);

    private static final Paint P = new Paint(Paint.ANTI_ALIAS_FLAG);
    private static final Paint M = new Paint(Paint.ANTI_ALIAS_FLAG);
    private static final RectF R = new RectF();
    private static final Path PATH = new Path();

    private static int w, h;
    private static float scale = 1f;
    private static RadialGradient unitGlow, unitFog, beamShader, hitShader, vignette;
    private static LinearGradient horizon, dawnGlow;
    private static final float[] STAR_X = new float[70], STAR_Y = new float[70], STAR_P = new float[70];

    static {
        java.util.Random r = new java.util.Random(11);
        for (int i = 0; i < STAR_X.length; i++) {
            STAR_X[i] = r.nextFloat();
            STAR_Y[i] = r.nextFloat();
            STAR_P[i] = r.nextFloat() * 6.28f;
        }
    }

    private Gfx() {
    }

    /** Ekran boyutu değişince gölge/gradyanları yeniden kurar. */
    static void resize(int width, int height) {
        w = width;
        h = height;
        scale = w / 1000f;
        unitGlow = new RadialGradient(0, 0, 1f, new int[]{0xAAFFC857, 0x44FFC857, 0x00FFC857},
                new float[]{0f, 0.35f, 1f}, Shader.TileMode.CLAMP);
        unitFog = new RadialGradient(0, 0, 1f, new int[]{0x2A6E7FB0, 0x006E7FB0},
                new float[]{0f, 1f}, Shader.TileMode.CLAMP);
        float br = World.BEAM_RANGE * scale;
        beamShader = new RadialGradient(0, 0, br, new int[]{0xF0FFF1C4, 0x90FFD97A, 0x00FFC857},
                new float[]{0.05f, 0.55f, 1f}, Shader.TileMode.CLAMP);
        hitShader = new RadialGradient(w / 2f, h / 2f, Math.max(w, h) * 0.7f,
                new int[]{0x00E5484D, 0x00E5484D, 0xCCE5484D}, new float[]{0f, 0.45f, 1f}, Shader.TileMode.CLAMP);
        vignette = new RadialGradient(w / 2f, h / 2f, Math.max(w, h) * 0.75f,
                new int[]{0x00000000, 0x00000000, 0xAA000000}, new float[]{0f, 0.5f, 1f}, Shader.TileMode.CLAMP);
        horizon = new LinearGradient(0, 0, 0, h, 0x00000000, 0x55263A78, Shader.TileMode.CLAMP);
        dawnGlow = new LinearGradient(0, h, 0, h * 0.2f, new int[]{0xF2FF9F43, 0x80FF7A59, 0x00FF7A59},
                new float[]{0f, 0.5f, 1f}, Shader.TileMode.CLAMP);
    }

    // ----------------------------------------------------------- temel

    static Paint fill(int color) {
        P.reset();
        P.setAntiAlias(true);
        P.setStyle(Paint.Style.FILL);
        P.setColor(color);
        return P;
    }

    static Paint stroke(int color, float width) {
        P.reset();
        P.setAntiAlias(true);
        P.setStyle(Paint.Style.STROKE);
        P.setStrokeCap(Paint.Cap.ROUND);
        P.setStrokeWidth(width);
        P.setColor(color);
        return P;
    }

    static int alpha(int color, float a) {
        int al = Math.max(0, Math.min(255, (int) (((color >>> 24) & 0xFF) * a)));
        return (al << 24) | (color & 0xFFFFFF);
    }

    static int lerp(int a, int b, float t) {
        t = Math.max(0f, Math.min(1f, t));
        int ar = (a >> 16) & 255, ag = (a >> 8) & 255, ab = a & 255;
        int br = (b >> 16) & 255, bg = (b >> 8) & 255, bb = b & 255;
        return 0xFF000000 | ((int) (ar + (br - ar) * t) << 16) | ((int) (ag + (bg - ag) * t) << 8)
                | (int) (ab + (bb - ab) * t);
    }

    static void text(Canvas c, String s, float x, float y, float size, int color, Paint.Align align,
                     Typeface tf) {
        P.reset();
        P.setAntiAlias(true);
        P.setStyle(Paint.Style.FILL);
        P.setColor(color);
        P.setTextSize(size);
        P.setTextAlign(align);
        P.setTypeface(tf);
        c.drawText(s, x, y, P);
    }

    /** Metni verilen genişliğe göre satırlara böler; "\n" paragraf sonudur. */
    static List<String> wrap(String text, float size, Typeface tf, float maxWidth) {
        M.reset();
        M.setAntiAlias(true);
        M.setTextSize(size);
        M.setTypeface(tf);
        List<String> lines = new ArrayList<>();
        for (String para : text.split("\n", -1)) {
            if (para.isEmpty()) {
                lines.add("");
                continue;
            }
            StringBuilder line = new StringBuilder();
            for (String word : para.split(" ")) {
                String tryLine = line.length() == 0 ? word : line + " " + word;
                if (M.measureText(tryLine) > maxWidth && line.length() > 0) {
                    lines.add(line.toString());
                    line = new StringBuilder(word);
                } else {
                    line = new StringBuilder(tryLine);
                }
            }
            lines.add(line.toString());
        }
        return lines;
    }

    static void panel(Canvas c, float l, float t, float r, float b, float radius, int fillColor, int edge) {
        R.set(l, t, r, b);
        c.drawRoundRect(R, radius, radius, fill(fillColor));
        c.drawRoundRect(R, radius, radius, stroke(edge, Math.max(2f, radius * 0.07f)));
    }

    // ------------------------------------------------------------- düğme

    static final class Button {
        final RectF r = new RectF();
        String label = "";
        boolean primary;
        boolean enabled = true;

        Button set(float l, float t, float rr, float b, String label, boolean primary) {
            r.set(l, t, rr, b);
            this.label = label;
            this.primary = primary;
            return this;
        }

        boolean hit(float x, float y) {
            return enabled && r.contains(x, y);
        }
    }

    static void button(Canvas c, Button b, float u, boolean pressed) {
        float rad = 30f * u;
        int fillC, edge, txt;
        if (!b.enabled) {
            fillC = 0x66121A33;
            edge = 0x663A4468;
            txt = 0x668E98B8;
        } else if (b.primary) {
            fillC = pressed ? 0xFFE0A93E : GOLD;
            edge = GOLD_SOFT;
            txt = INK;
        } else {
            fillC = pressed ? 0xFF222D55 : PANEL;
            edge = PANEL_EDGE;
            txt = TEXT;
        }
        c.drawRoundRect(b.r, rad, rad, fill(fillC));
        c.drawRoundRect(b.r, rad, rad, stroke(edge, 3f * u));
        float size = Math.min(44f * u, (b.r.height() * 0.42f));
        text(c, b.label, b.r.centerX(), b.r.centerY() + size * 0.35f, size, txt, Paint.Align.CENTER, SANS_BOLD);
    }

    // ---------------------------------------------------------- arka plan

    /** Yıldızlı, sisli gece zemini. dawn: 0 gece … 1 şafak. */
    static void background(Canvas c, float t, float dawn) {
        c.drawColor(lerp(NAVY, DAWN, dawn * 0.9f));
        P.reset();
        P.setShader(horizon);
        c.drawRect(0, 0, w, h, P);
        if (dawn > 0.01f) {
            P.reset();
            P.setShader(dawnGlow);
            P.setAlpha((int) (255 * Math.min(1f, dawn)));
            c.drawRect(0, 0, w, h, P);
        }
        float sa = 1f - dawn;
        for (int i = 0; i < STAR_X.length; i++) {
            float tw = 0.5f + 0.5f * (float) Math.sin(t * 1.3f + STAR_P[i]);
            c.drawCircle(STAR_X[i] * w, STAR_Y[i] * h, (1.2f + tw) * scale * 1.2f,
                    fill(alpha(0xFFDDE6FF, (0.25f + 0.5f * tw) * sa)));
        }
        for (int i = 0; i < 5; i++) {
            float fx = w * (0.5f + 0.55f * (float) Math.sin(t * 0.05f + i * 1.9f));
            float fy = h * (0.5f + 0.42f * (float) Math.cos(t * 0.04f + i * 2.7f));
            fog(c, fx, fy, (260f + 40f * i) * scale * 1.6f);
        }
    }

    private static void fog(Canvas c, float x, float y, float r) {
        c.save();
        c.translate(x, y);
        c.scale(r, r);
        P.reset();
        P.setShader(unitFog);
        c.drawCircle(0, 0, 1f, P);
        c.restore();
    }

    static void vignette(Canvas c) {
        P.reset();
        P.setShader(vignette);
        c.drawRect(0, 0, w, h, P);
    }

    static void hitFlash(Canvas c, float a) {
        P.reset();
        P.setShader(hitShader);
        P.setAlpha((int) (255 * Math.min(1f, a)));
        c.drawRect(0, 0, w, h, P);
    }

    static void glow(Canvas c, float x, float y, float r, float a) {
        c.save();
        c.translate(x, y);
        c.scale(r, r);
        P.reset();
        P.setShader(unitGlow);
        P.setAlpha((int) (255 * Math.max(0f, Math.min(1f, a))));
        c.drawCircle(0, 0, 1f, P);
        c.restore();
    }

    // -------------------------------------------------------------- fener

    /** Fenerin çevresindeki sıcak ışıltı; gölgelerin altına çizilir ki silüet olarak kalsınlar. */
    static void lanternGlow(Canvas c, float x, float y, float s, float t, float energy01, boolean on) {
        float pulse = 0.85f + 0.15f * (float) Math.sin(t * 3f);
        glow(c, x, y, 330f * s * (on ? 1.15f : 1f), pulse * (0.55f + 0.45f * energy01));
    }

    static void lantern(Canvas c, float x, float y, float s, float t, float energy01, boolean on) {
        lanternGlow(c, x, y, s, t, energy01, on);
        lanternBody(c, x, y, s, energy01);
    }

    static void lanternBody(Canvas c, float x, float y, float s, float energy01) {
        c.drawCircle(x, y, 78f * s, fill(0xFF0A0F22));
        c.drawCircle(x, y, 78f * s, stroke(0xFF26335E, 4f * s));
        c.drawCircle(x, y, World.LANTERN_R * s, fill(0xFF3A4560));
        c.drawCircle(x, y, World.LANTERN_R * s, stroke(0xFF5B6A94, 3f * s));
        c.drawCircle(x, y, World.LANTERN_R * 0.62f * s, fill(lerp(0xFF8C6A2A, GOLD_SOFT, 0.35f + 0.65f * energy01)));
        c.drawCircle(x - 6f * s, y - 7f * s, World.LANTERN_R * 0.22f * s, fill(0xAAFFFFFF));
    }

    /** Işın dilimi; (x,y) fenerdir, intensity 0..1. */
    static void beam(Canvas c, float x, float y, float s, float angle, float half, float intensity, float t) {
        float range = World.BEAM_RANGE * s;
        float flick = 0.9f + 0.1f * (float) Math.sin(t * 27f);
        c.save();
        c.translate(x, y);
        double a0 = angle - half;
        PATH.reset();
        PATH.moveTo(0, 0);
        PATH.lineTo((float) (range * Math.cos(a0)), (float) (range * Math.sin(a0)));
        R.set(-range, -range, range, range);
        PATH.arcTo(R, (float) Math.toDegrees(a0), (float) Math.toDegrees(half * 2), false);
        PATH.close();
        P.reset();
        P.setAntiAlias(true);
        P.setShader(beamShader);
        P.setAlpha((int) (255 * intensity * flick));
        c.drawPath(PATH, P);
        // parlak çekirdek: açının üçte biri
        double b0 = angle - half * 0.35f;
        PATH.reset();
        PATH.moveTo(0, 0);
        PATH.lineTo((float) (range * Math.cos(b0)), (float) (range * Math.sin(b0)));
        PATH.arcTo(R, (float) Math.toDegrees(b0), (float) Math.toDegrees(half * 0.7f), false);
        PATH.close();
        P.setAlpha((int) (150 * intensity * flick));
        c.drawPath(PATH, P);
        c.restore();
    }

    static void flashRing(Canvas c, float x, float y, float s, float progress) {
        float r = World.FLASH_RADIUS * s * (1f - (1f - progress) * (1f - progress));
        int a = (int) (255 * (1f - progress));
        c.drawCircle(x, y, r, stroke((a << 24) | 0xFFF1C4, 10f * s * (1f - progress) + 2f));
        c.drawCircle(x, y, r * 0.97f, fill(((a / 11) << 24) | 0xFFE3A3));
    }

    // ----------------------------------------------------------- gölgeler

    private static int edgeColor(ShadowType t) {
        switch (t) {
            case RUNNER:
                return 0xFFFF6E8A;
            case ARMORED:
                return 0xFF8FA6D8;
            case SPLITTER:
            case SPLITLING:
                return 0xFFB07CFF;
            case CAPTAIN:
                return 0xFF3FD6C2;
            case MOTHER:
                return 0xFFD04CFF;
            default:
                return 0xFF6E86C9;
        }
    }

    static void shadow(Canvas c, Shadow sh, float cx, float cy, float s, float t) {
        ShadowType ty = sh.type;
        float x = cx + sh.x * s, y = cy + sh.y * s, r = ty.radius * s;
        if (x < -r * 3 || x > w + r * 3 || y < -r * 3 || y > h + r * 3) return;
        float face = (float) Math.atan2(-sh.y, -sh.x);
        float fx = (float) Math.cos(face), fy = (float) Math.sin(face);
        float px = -fy, py = fx;
        int edge = sh.lit ? GOLD : edgeColor(ty);
        int body = sh.hurt > 0f ? 0xFF3A3F66 : 0xFF04050B;
        float wob = (float) Math.sin(t * 6f + sh.phase);

        c.drawCircle(x, y, r * 1.7f, fill(alpha(edge, sh.lit ? 0.22f : 0.10f)));

        switch (ty) {
            case CRAWLER:
                for (int i = 0; i < 6; i++) {
                    float a = i * 1.047f + (float) Math.sin(t * 6f + sh.phase + i) * 0.35f;
                    c.drawLine(x + (float) Math.cos(a) * r * 0.7f, y + (float) Math.sin(a) * r * 0.7f,
                            x + (float) Math.cos(a) * r * 1.4f, y + (float) Math.sin(a) * r * 1.4f,
                            stroke(edge, r * 0.16f));
                }
                c.drawCircle(x, y, r, fill(body));
                c.drawCircle(x, y, r, stroke(edge, r * 0.12f));
                break;
            case RUNNER:
                PATH.reset();
                PATH.moveTo(x + fx * r * 1.2f, y + fy * r * 1.2f);
                PATH.lineTo(x - fx * r * 2.6f + px * wob * r * 0.5f, y - fy * r * 2.6f + py * wob * r * 0.5f);
                PATH.lineTo(x + px * r * 0.9f, y + py * r * 0.9f);
                PATH.close();
                c.drawPath(PATH, fill(alpha(edge, 0.55f)));
                PATH.reset();
                PATH.moveTo(x + fx * r * 1.2f, y + fy * r * 1.2f);
                PATH.lineTo(x - fx * r * 2.6f + px * wob * r * 0.5f, y - fy * r * 2.6f + py * wob * r * 0.5f);
                PATH.lineTo(x - px * r * 0.9f, y - py * r * 0.9f);
                PATH.close();
                c.drawPath(PATH, fill(alpha(edge, 0.55f)));
                c.drawCircle(x, y, r, fill(body));
                c.drawCircle(x, y, r, stroke(edge, r * 0.14f));
                break;
            case ARMORED:
                c.drawCircle(x, y, r, fill(body));
                c.drawCircle(x, y, r * 0.9f, stroke(edge, r * 0.3f));
                for (int i = 0; i < 6; i++) {
                    float a = i * 1.047f + face;
                    c.drawCircle(x + (float) Math.cos(a) * r * 0.9f, y + (float) Math.sin(a) * r * 0.9f,
                            r * 0.12f, fill(0xFFE8ECF8));
                }
                break;
            case SPLITTER:
                float sep = r * (0.32f + 0.08f * wob);
                c.drawCircle(x + px * sep, y + py * sep, r * 0.8f, fill(body));
                c.drawCircle(x - px * sep, y - py * sep, r * 0.8f, fill(body));
                c.drawCircle(x + px * sep, y + py * sep, r * 0.8f, stroke(edge, r * 0.12f));
                c.drawCircle(x - px * sep, y - py * sep, r * 0.8f, stroke(edge, r * 0.12f));
                break;
            case SPLITLING:
                c.drawCircle(x, y, r, fill(body));
                c.drawCircle(x, y, r, stroke(edge, r * 0.2f));
                break;
            case CAPTAIN:
                for (int i = 0; i < 8; i++) {
                    float a = i * 0.785f + t * 0.3f;
                    c.drawLine(x + (float) Math.cos(a) * r * 0.8f, y + (float) Math.sin(a) * r * 0.8f,
                            x + (float) Math.cos(a) * r * 1.35f, y + (float) Math.sin(a) * r * 1.35f,
                            stroke(edge, r * 0.1f));
                }
                c.drawCircle(x, y, r, fill(body));
                c.drawCircle(x, y, r, stroke(edge, r * 0.08f));
                c.drawCircle(x, y, r * 0.45f, stroke(alpha(edge, 0.6f), r * 0.05f));
                break;
            case MOTHER:
                for (int i = 0; i < 12; i++) {
                    float a = i * 0.5236f + (float) Math.sin(t * 1.5f + i) * 0.15f;
                    float len = r * (1.5f + 0.25f * (float) Math.sin(t * 2f + i * 1.3f));
                    PATH.reset();
                    PATH.moveTo(x + (float) Math.cos(a) * r * 0.8f, y + (float) Math.sin(a) * r * 0.8f);
                    PATH.quadTo(x + (float) Math.cos(a + 0.4f) * len * 0.95f, y + (float) Math.sin(a + 0.4f) * len * 0.95f,
                            x + (float) Math.cos(a) * len, y + (float) Math.sin(a) * len);
                    c.drawPath(PATH, stroke(alpha(edge, 0.8f), r * 0.07f));
                }
                c.drawCircle(x, y, r, fill(body));
                c.drawCircle(x, y, r, stroke(edge, r * 0.06f));
                break;
            default:
                break;
        }

        // gözler
        int eye = sh.lit ? 0xFFFFFFFF : (ty == ShadowType.RUNNER ? 0xFFFFB3C1 : 0xFFE6F0FF);
        if (ty == ShadowType.CAPTAIN || ty == ShadowType.MOTHER) {
            int n = ty == ShadowType.MOTHER ? 5 : 3;
            for (int i = 0; i < n; i++) {
                float o = (i - (n - 1) / 2f) * r * 0.32f;
                c.drawCircle(x + fx * r * 0.3f + px * o, y + fy * r * 0.3f + py * o, r * 0.1f, fill(eye));
            }
        } else if (ty != ShadowType.SPLITLING) {
            float er = r * 0.13f;
            c.drawCircle(x + fx * r * 0.35f + px * r * 0.28f, y + fy * r * 0.35f + py * r * 0.28f, er, fill(eye));
            c.drawCircle(x + fx * r * 0.35f - px * r * 0.28f, y + fy * r * 0.35f - py * r * 0.28f, er, fill(eye));
        } else {
            c.drawCircle(x + fx * r * 0.3f, y + fy * r * 0.3f, r * 0.2f, fill(eye));
        }

        if (ty.isBoss()) {
            float bw = r * 1.8f, bh = 9f * s * 2f;
            float by = y - r * 1.5f - 14f * s;
            R.set(x - bw / 2, by, x + bw / 2, by + bh);
            c.drawRoundRect(R, bh / 2, bh / 2, fill(0x99000000));
            R.set(x - bw / 2, by, x - bw / 2 + bw * Math.max(0f, sh.hp / sh.maxHp), by + bh);
            c.drawRoundRect(R, bh / 2, bh / 2, fill(edge));
        }
    }

    // ------------------------------------------------------------- çubuk

    static void bar(Canvas c, float l, float t, float r, float b, float frac, int color, int back) {
        float rad = (b - t) / 2f;
        R.set(l, t, r, b);
        c.drawRoundRect(R, rad, rad, fill(back));
        frac = Math.max(0f, Math.min(1f, frac));
        if (frac > 0f) {
            R.set(l, t, l + Math.max(b - t, (r - l) * frac), b);
            c.drawRoundRect(R, rad, rad, fill(color));
        }
    }

    static void ring(Canvas c, float x, float y, float radius, float width, float frac, int color) {
        ring(c, x, y, radius, width, frac, color, 0x55FFFFFF);
    }

    static void ring(Canvas c, float x, float y, float radius, float width, float frac, int color, int back) {
        c.drawCircle(x, y, radius, stroke(back, width));
        R.set(x - radius, y - radius, x + radius, y + radius);
        P.reset();
        P.setAntiAlias(true);
        P.setStyle(Paint.Style.STROKE);
        P.setStrokeCap(Paint.Cap.ROUND);
        P.setStrokeWidth(width);
        P.setColor(color);
        c.drawArc(R, -90f, 360f * Math.max(0f, Math.min(1f, frac)), false, P);
    }

    static void circleFill(Canvas c, float x, float y, float r, int color) {
        c.drawCircle(x, y, r, fill(color));
    }
}
