package com.tigirer.sonfener;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.view.MotionEvent;

import java.util.ArrayList;
import java.util.List;

/** Dokunarak ilerlenen, harf harf beliren hikâye sayfaları. */
final class StoryScreen extends Screen {
    private static final float CHARS_PER_SEC = 55f;

    private final String[] pages;
    private final Runnable done;
    private final List<List<String>> lines = new ArrayList<>();
    private int page;
    private float reveal;
    private float t;
    private boolean finished;

    StoryScreen(Game g, String[] pages, Runnable done) {
        super(g);
        this.pages = pages;
        this.done = done;
    }

    @Override
    void onResize() {
        lines.clear();
        for (String p : pages) lines.add(Gfx.wrap(p, 52f * g.u, Gfx.SERIF, g.w - 190f * g.u));
    }

    private int totalChars(int pg) {
        int n = 0;
        for (String l : lines.get(pg)) n += l.length() + 1;
        return n;
    }

    @Override
    void update(float dt) {
        t += dt;
        reveal += dt * CHARS_PER_SEC;
    }

    @Override
    void draw(Canvas c) {
        Gfx.background(c, t, 0f);
        float s = g.w / 1000f;
        Gfx.lantern(c, g.w / 2f, g.h * 0.16f, s * 0.55f, t, 0.8f, false);

        List<String> ls = lines.get(page);
        float size = 52f * g.u, lh = size * 1.55f;
        float y = Math.max(g.h * 0.30f, g.h * 0.5f - ls.size() * lh / 2f + size);
        int left = (int) reveal;
        for (String line : ls) {
            if (left <= 0) break;
            String shown = line.length() <= left ? line : line.substring(0, left);
            left -= line.length() + 1;
            Gfx.text(c, shown, g.w / 2f, y, size, Gfx.TEXT, Paint.Align.CENTER, Gfx.SERIF);
            y += lh;
        }

        float dotY = g.h - 190f * g.u;
        for (int i = 0; i < pages.length; i++) {
            float x = g.w / 2f + (i - (pages.length - 1) / 2f) * 36f * g.u;
            Gfx.circleFill(c, x, dotY, 9f * g.u, i == page ? Gfx.GOLD : 0x55FFFFFF);
        }
        boolean complete = reveal >= totalChars(page);
        float a = complete ? 0.55f + 0.45f * (float) Math.sin(t * 4f) : 0.25f;
        Gfx.text(c, complete ? "Devam için dokun" : "Dokun: hepsini göster", g.w / 2f, g.h - 110f * g.u,
                38f * g.u, Gfx.alpha(Gfx.MUTED, a), Paint.Align.CENTER, Gfx.SERIF_ITALIC);
        Gfx.vignette(c);
    }

    @Override
    void onTouch(MotionEvent e) {
        if (e.getActionMasked() != MotionEvent.ACTION_DOWN || finished) return;
        if (reveal < totalChars(page)) {
            reveal = totalChars(page);
            return;
        }
        g.sfx.click();
        if (page + 1 < pages.length) {
            page++;
            reveal = 0f;
        } else {
            finished = true;
            done.run();
        }
    }

    @Override
    void onBack() {
        if (finished) return;
        finished = true;
        done.run();
    }
}
