package com.tigirer.sonfener;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.view.MotionEvent;

import com.tigirer.sonfener.core.Levels;
import com.tigirer.sonfener.core.SaveData;
import com.tigirer.sonfener.core.Upgrades;

import java.util.ArrayList;
import java.util.List;

/** Atölye: kıvılcımla fener geliştirme ve gece seçimi. */
final class ShopScreen extends Screen {
    private final Gfx.Button[] buy = new Gfx.Button[Upgrades.COUNT];
    private final Gfx.Button prev = new Gfx.Button();
    private final Gfx.Button next = new Gfx.Button();
    private final Gfx.Button start = new Gfx.Button();
    private final Gfx.Button menu = new Gfx.Button();
    private final List<Gfx.Button> buttons = new ArrayList<>();
    private int selected;
    private float t;
    private float rowTop, rowH;

    ShopScreen(Game g) {
        super(g);
        selected = g.save.completed ? Levels.COUNT - 1 : g.save.unlocked;
        for (int i = 0; i < buy.length; i++) {
            buy[i] = new Gfx.Button();
            buttons.add(buy[i]);
        }
        buttons.add(prev);
        buttons.add(next);
        buttons.add(start);
        buttons.add(menu);
    }

    @Override
    void onResize() {
        float u = g.u;
        SaveData s = g.save;
        menu.set(30f * u, 50f * u, 200f * u, 150f * u, "MENÜ", false);
        rowTop = 300f * u;
        rowH = Math.min(225f * u, (g.h - rowTop - 440f * u) / Upgrades.COUNT);
        for (int i = 0; i < buy.length; i++) {
            float top = rowTop + i * rowH;
            buy[i].set(g.w - 320f * u, top + rowH * 0.2f, g.w - 50f * u, top + rowH * 0.8f - 10f * u, "", true);
            int cost = s.up.cost(i);
            buy[i].enabled = s.up.canBuy(i, s.sparks);
            buy[i].label = cost < 0 ? "AZAMİ" : String.valueOf(cost);
            buy[i].primary = cost >= 0;
            if (cost < 0) buy[i].enabled = false;
        }
        float selY = rowTop + Upgrades.COUNT * rowH + 30f * u;
        prev.set(50f * u, selY, 190f * u, selY + 110f * u, "<", false);
        next.set(g.w - 190f * u, selY, g.w - 50f * u, selY + 110f * u, ">", false);
        prev.enabled = selected > 0;
        next.enabled = selected < s.unlocked || (s.completed && selected < Levels.COUNT - 1);
        if (!s.completed && selected > s.unlocked) selected = s.unlocked;
        start.set(60f * u, g.h - 210f * u, g.w - 60f * u, g.h - 70f * u,
                "GECEYE BAŞLA", true);
    }

    @Override
    void update(float dt) {
        t += dt;
    }

    @Override
    void draw(Canvas c) {
        float u = g.u;
        SaveData s = g.save;
        Gfx.background(c, t, 0f);
        Gfx.text(c, "ATÖLYE", g.w / 2f, 130f * u, 74f * u, Gfx.GOLD, Paint.Align.CENTER, Gfx.SANS_BOLD);
        Gfx.circleFill(c, g.w / 2f - 70f * u, 220f * u, 20f * u, Gfx.GOLD);
        Gfx.text(c, s.sparks + " kıvılcım", g.w / 2f - 38f * u, 235f * u, 48f * u, Gfx.GOLD_SOFT, Paint.Align.LEFT,
                Gfx.SANS_BOLD);
        Gfx.button(c, menu, u, pressed() == menu);

        for (int i = 0; i < Upgrades.COUNT; i++) {
            float top = rowTop + i * rowH;
            Gfx.panel(c, 40f * u, top + 6f * u, g.w - 40f * u, top + rowH - 6f * u, 26f * u, Gfx.PANEL, Gfx.PANEL_EDGE);
            Gfx.text(c, Upgrades.NAMES[i], 70f * u, top + rowH * 0.38f, 44f * u, Gfx.TEXT, Paint.Align.LEFT,
                    Gfx.SANS_BOLD);
            Gfx.text(c, Upgrades.DESCS[i], 70f * u, top + rowH * 0.62f, 27f * u, Gfx.MUTED, Paint.Align.LEFT,
                    Gfx.SANS_MED);
            for (int k = 0; k < Upgrades.MAX_LEVEL; k++) {
                Gfx.circleFill(c, 82f * u + k * 40f * u, top + rowH * 0.82f, 11f * u,
                        k < s.up.level[i] ? Gfx.GOLD : 0x44FFFFFF);
            }
            Gfx.button(c, buy[i], u, pressed() == buy[i]);
            if (s.up.cost(i) >= 0) {
                Gfx.circleFill(c, buy[i].r.centerX() - 62f * u, buy[i].r.centerY(), 13f * u,
                        buy[i].enabled ? Gfx.INK : 0x66FFC857);
            }
        }

        float selY = prev.r.top;
        Gfx.button(c, prev, u, pressed() == prev);
        Gfx.button(c, next, u, pressed() == next);
        String name = Levels.get(selected).name;
        Gfx.text(c, name, g.w / 2f, selY + 50f * u, 42f * u, Gfx.TEXT, Paint.Align.CENTER, Gfx.SANS_BOLD);
        boolean cleared = selected < s.unlocked || s.completed;
        Gfx.text(c, cleared ? "Tamamlandı · tekrar oynayabilirsin" : "Yeni gece", g.w / 2f, selY + 98f * u,
                30f * u, cleared ? Gfx.MUTED : Gfx.CYAN, Paint.Align.CENTER, Gfx.SANS_MED);
        Gfx.button(c, start, u, pressed() == start);
    }

    @Override
    void onTouch(MotionEvent e) {
        Gfx.Button b = handleButtons(e, buttons);
        if (b == null) return;
        SaveData s = g.save;
        if (b == menu) {
            g.showMenu();
        } else if (b == prev) {
            selected--;
            onResize();
        } else if (b == next) {
            selected++;
            onResize();
        } else if (b == start) {
            boolean intro = selected == s.unlocked && !s.completed;
            g.startNight(selected, intro);
        } else {
            for (int i = 0; i < buy.length; i++) {
                if (b == buy[i]) {
                    s.sparks -= s.up.buy(i, s.sparks);
                    g.persist();
                    onResize();
                }
            }
        }
    }
}
