package com.tigirer.sonfener;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.view.MotionEvent;

import com.tigirer.sonfener.core.SaveData;

import java.util.ArrayList;
import java.util.List;

final class MenuScreen extends Screen {
    private final Gfx.Button play = new Gfx.Button();
    private final Gfx.Button endless = new Gfx.Button();
    private final Gfx.Button howto = new Gfx.Button();
    private final Gfx.Button sound = new Gfx.Button();
    private final Gfx.Button reset = new Gfx.Button();
    private final List<Gfx.Button> buttons = new ArrayList<>();
    private float t;
    private boolean confirmReset;

    MenuScreen(Game g) {
        super(g);
        buttons.add(play);
        buttons.add(endless);
        buttons.add(howto);
        buttons.add(sound);
        buttons.add(reset);
    }

    @Override
    void onResize() {
        float u = g.u;
        float bw = 360f * u, bh = 128f * u, gap = 28f * u;
        float y = g.h * 0.56f;
        float l = g.w / 2f - bw, r = g.w / 2f + bw;
        SaveData s = g.save;
        play.set(l, y, r, y + bh, s.prologueSeen ? "DEVAM ET" : "OYNA", true);
        y += bh + gap;
        endless.enabled = s.completed;
        String endlessLabel = !s.completed ? "SONSUZ GECE · KİLİTLİ"
                : s.endlessBest > 0f ? "SONSUZ GECE · " + PlayScreen.clock(s.endlessBest) : "SONSUZ GECE";
        endless.set(l, y, r, y + bh, endlessLabel, false);
        y += bh + gap;
        howto.set(l, y, r, y + bh, "NASIL OYNANIR", false);
        y += bh + gap;
        sound.set(l, y, r, y + bh, s.sound ? "SES: AÇIK" : "SES: KAPALI", false);
        reset.set(g.w / 2f - 330f * u, g.h - 150f * u, g.w / 2f + 330f * u, g.h - 60f * u,
                confirmReset ? "EMİN MİSİN? TEKRAR DOKUN" : "İLERLEMEYİ SIFIRLA", false);
    }

    @Override
    void update(float dt) {
        t += dt;
    }

    @Override
    void draw(Canvas c) {
        float u = g.u;
        float s = g.w / 1000f;
        Gfx.background(c, t, 0f);
        float lx = g.w / 2f, ly = g.h * 0.24f;
        float ang = (float) (-Math.PI / 2 + Math.sin(t * 0.6f) * 0.9f);
        Gfx.beam(c, lx, ly, s * 0.9f, ang, 0.28f, 0.55f, t);
        Gfx.lantern(c, lx, ly, s * 0.9f, t, 1f, true);
        Gfx.text(c, "SON FENER", g.w / 2f, g.h * 0.43f, 128f * u, Gfx.GOLD_SOFT, Paint.Align.CENTER, Gfx.SERIF);
        Gfx.text(c, "Işığın son bekçisi", g.w / 2f, g.h * 0.43f + 70f * u, 44f * u, Gfx.MUTED, Paint.Align.CENTER,
                Gfx.SERIF_ITALIC);
        for (Gfx.Button b : buttons) {
            if (b == reset) continue;
            Gfx.button(c, b, u, pressed() == b);
        }
        Gfx.text(c, reset.label, reset.r.centerX(), reset.r.centerY() + 12f * u, 32f * u,
                confirmReset ? Gfx.RED : Gfx.alpha(Gfx.MUTED, 0.8f), Paint.Align.CENTER, Gfx.SANS_MED);
        Gfx.vignette(c);
    }

    @Override
    void onTouch(MotionEvent e) {
        Gfx.Button b = handleButtons(e, buttons);
        if (b == null) return;
        if (b != reset && confirmReset) {
            confirmReset = false;
            onResize();
        }
        if (b == play) {
            g.play();
        } else if (b == endless) {
            g.startEndless();
        } else if (b == howto) {
            g.setScreen(new HowToScreen(g));
        } else if (b == sound) {
            g.setSound(!g.save.sound);
            g.sfx.click();
            onResize();
        } else if (b == reset) {
            if (confirmReset) {
                boolean snd = g.save.sound;
                g.save = new SaveData();
                g.save.sound = snd;
                g.persist();
                confirmReset = false;
            } else {
                confirmReset = true;
            }
            onResize();
        }
    }

    @Override
    void onBack() {
        // menüden geri tuşu uygulamadan çıkar (MainActivity yönetir)
    }
}
