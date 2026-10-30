package com.tigirer.sonfener;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.view.MotionEvent;

import com.tigirer.sonfener.core.Story;

import java.util.ArrayList;
import java.util.List;

final class HowToScreen extends Screen {
    private final Gfx.Button back = new Gfx.Button();
    private final List<Gfx.Button> buttons = new ArrayList<>();
    private final List<List<String>> lines = new ArrayList<>();
    private float t;

    HowToScreen(Game g) {
        super(g);
        buttons.add(back);
    }

    @Override
    void onResize() {
        float u = g.u;
        back.set(g.w / 2f - 330f * u, g.h - 250f * u, g.w / 2f + 330f * u, g.h - 110f * u, "GERİ", true);
        lines.clear();
        for (String s : Story.HOW_TO) lines.add(Gfx.wrap(s, 40f * u, Gfx.SANS_MED, g.w - 250f * u));
    }

    @Override
    void update(float dt) {
        t += dt;
    }

    @Override
    void draw(Canvas c) {
        float u = g.u;
        Gfx.background(c, t, 0f);
        Gfx.text(c, "NASIL OYNANIR", g.w / 2f, 190f * u, 78f * u, Gfx.GOLD, Paint.Align.CENTER, Gfx.SANS_BOLD);
        float y = 300f * u;
        for (int i = 0; i < lines.size(); i++) {
            List<String> ls = lines.get(i);
            float lh = 52f * u;
            float h = ls.size() * lh + 50f * u;
            Gfx.panel(c, 60f * u, y, g.w - 60f * u, y + h, 28f * u, Gfx.PANEL, Gfx.PANEL_EDGE);
            Gfx.circleFill(c, 105f * u, y + 52f * u, 22f * u, Gfx.GOLD);
            Gfx.text(c, String.valueOf(i + 1), 105f * u, y + 52f * u + 14f * u, 36f * u, Gfx.INK,
                    Paint.Align.CENTER, Gfx.SANS_BOLD);
            float ty = y + 55f * u;
            for (String l : ls) {
                Gfx.text(c, l, 150f * u, ty, 40f * u, Gfx.TEXT, Paint.Align.LEFT, Gfx.SANS_MED);
                ty += lh;
            }
            y += h + 22f * u;
        }
        Gfx.button(c, back, u, pressed() == back);
    }

    @Override
    void onTouch(MotionEvent e) {
        if (handleButtons(e, buttons) == back) g.showMenu();
    }
}
