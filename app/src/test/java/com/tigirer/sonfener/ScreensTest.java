package com.tigirer.sonfener;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import android.app.Application;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.os.SystemClock;
import android.view.MotionEvent;

import com.tigirer.sonfener.core.Levels;
import com.tigirer.sonfener.core.Shadow;
import com.tigirer.sonfener.core.ShadowType;
import com.tigirer.sonfener.core.Story;
import com.tigirer.sonfener.core.World;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.GraphicsMode;

import java.io.File;
import java.io.FileOutputStream;

/**
 * Ekranları gerçek Canvas ile çizer (Robolectric native grafik), ekranlar arası akışı dener
 * ve PNG çıktısı üretir. Cihaz/emülatör olmadan çökme ve düzen hatalarını yakalamak içindir.
 */
@RunWith(RobolectricTestRunner.class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = 34)
public class ScreensTest {
    private static final int W = 1080, H = 2340;
    private final File out = new File(System.getProperty("shots.dir", "build/shots"));

    private Game newGame() {
        Application app = RuntimeEnvironment.getApplication();
        Game g = new Game(app);
        g.sfx.enabled = false;
        g.resize(W, H);
        return g;
    }

    private void shot(Game g, String name) throws Exception {
        Bitmap bmp = Bitmap.createBitmap(g.w, g.h, Bitmap.Config.ARGB_8888);
        g.screen.draw(new Canvas(bmp));
        out.mkdirs();
        try (FileOutputStream fo = new FileOutputStream(new File(out, name + ".png"))) {
            bmp.compress(Bitmap.CompressFormat.PNG, 100, fo);
        }
    }

    private void run(Game g, float seconds) {
        for (float t = 0; t < seconds; t += 1f / 30f) g.screen.update(1f / 30f);
    }

    private void tap(Game g, float x, float y) {
        long now = SystemClock.uptimeMillis();
        g.screen.onTouch(MotionEvent.obtain(now, now, MotionEvent.ACTION_DOWN, x, y, 0));
        g.screen.onTouch(MotionEvent.obtain(now, now + 50, MotionEvent.ACTION_UP, x, y, 0));
    }

    /** Hikâye sayfalarını sonuna kadar geçer (her sayfa: bir dokunuş göster, bir dokunuş ilerle). */
    private void skipStory(Game g) {
        int guard = 0;
        while (g.screen instanceof StoryScreen && guard++ < 40) {
            tap(g, 540, 1200);
        }
    }

    /** Basit bir oyuncu: en yakın gölgeyi hedefler, kalabalıkta parlama atar. */
    private void botPlay(Game g, PlayScreen p, float maxSeconds) {
        World w = p.world;
        for (float t = 0; t < maxSeconds && w.state == World.State.PLAYING; t += 1f / 30f) {
            Shadow best = null;
            float bestScore = Float.MAX_VALUE;
            int near = 0;
            for (Shadow s : w.shadows) {
                float d = s.dist() - s.type.radius;
                if (d < 300f) near++;
                float score = d / (s.type.speed + 40f);
                if (score < bestScore) {
                    bestScore = score;
                    best = s;
                }
            }
            if (best != null && !w.overheated) {
                w.setBeam(true, (float) Math.atan2(best.y, best.x));
            } else {
                w.setBeam(false, w.beamAngle);
            }
            if (near >= 4) w.flash();
            g.screen.update(1f / 30f);
        }
    }

    // ------------------------------------------------------------------ ekranlar

    @Test
    public void menuStoryHowtoAndShopRender() throws Exception {
        Game g = newGame();
        run(g, 1f);
        shot(g, "01_menu");
        g.setScreen(new HowToScreen(g));
        run(g, 0.5f);
        shot(g, "02_howto");
        g.setScreen(new StoryScreen(g, Story.PROLOGUE, () -> {
        }));
        run(g, 6f);
        shot(g, "03_story");
        g.save.sparks = 70;
        g.save.unlocked = 2;
        g.setScreen(new ShopScreen(g));
        run(g, 0.5f);
        shot(g, "04_shop");
        // ilk geliştirmeyi satın al: kıvılcım düşmeli, seviye artmalı
        tap(g, 900, 400);
        assertEquals(1, g.save.up.level[0]);
        assertEquals(60, g.save.sparks);
        shot(g, "05_shop_after_buy");
    }

    @Test
    public void everyStoryPageFitsOnScreen() throws Exception {
        Game g = newGame();
        java.util.List<String[]> all = new java.util.ArrayList<>();
        all.add(Story.PROLOGUE);
        all.add(Story.EPILOGUE);
        for (String[] s : Story.NIGHT_INTRO) all.add(s);
        for (String[] s : Story.NIGHT_OUTRO) all.add(s);
        for (String[] pages : all) {
            for (String page : pages) {
                java.util.List<String> lines = Gfx.wrap(page, 52f * g.u, Gfx.SERIF, g.w - 190f * g.u);
                // satır yüksekliği 52*1.55 ≈ 81 px; ekranın ~%55'ini aşmamalı
                assertTrue("sayfa çok uzun: " + page, lines.size() * 81f < H * 0.55f);
            }
        }
    }

    // ---------------------------------------------------------------------- akış

    @Test
    public void menuLeadsThroughStoryIntoTheFirstNight() throws Exception {
        Game g = newGame();
        tap(g, 540, 1370); // OYNA
        assertTrue("prolog bekleniyordu", g.screen instanceof StoryScreen);
        skipStory(g);
        assertTrue("gece 1 bekleniyordu: " + g.screen.getClass().getSimpleName(), g.screen instanceof PlayScreen);
        assertTrue(g.save.prologueSeen);
    }

    @Test
    public void winningANightAwardsSparksUnlocksTheNextAndShowsTheOutro() throws Exception {
        Game g = newGame();
        g.setScreen(new PlayScreen(g, 0, false));
        PlayScreen p = (PlayScreen) g.screen;
        botPlay(g, p, 120f);
        assertEquals(World.State.WON, p.world.state);
        run(g, 3f);
        shot(g, "42_won");
        assertEquals(1, g.save.unlocked);
        assertEquals(p.world.sparks + 15, g.save.sparks);

        tap(g, 540, 1470); // DEVAM
        assertTrue("çıkış hikâyesi bekleniyordu", g.screen instanceof StoryScreen);
        skipStory(g);
        assertTrue("atölye bekleniyordu", g.screen instanceof ShopScreen);

        // aynı geceyi yeniden kazanmak şafak bonusu vermez
        int before = g.save.sparks;
        g.setScreen(new PlayScreen(g, 0, false));
        PlayScreen again = (PlayScreen) g.screen;
        botPlay(g, again, 120f);
        assertEquals(World.State.WON, again.world.state);
        assertEquals(before + again.world.sparks, g.save.sparks);
    }

    @Test
    public void losingKeepsHalfTheSparksAndOffersARetry() throws Exception {
        Game g = newGame();
        g.setScreen(new PlayScreen(g, 0, false));
        PlayScreen p = (PlayScreen) g.screen;
        p.world.sparks = 9;
        p.world.oil = 0f;
        run(g, 3f);
        assertEquals(World.State.LOST, p.world.state);
        assertEquals(4, g.save.sparks);
        run(g, 2f);
        tap(g, 540, 1470); // TEKRAR DENE
        assertTrue(g.screen instanceof PlayScreen);
        assertTrue(g.screen != p);
    }

    @Test
    public void finalNightStoryPlaysOnlyOnTheFirstClear() {
        Game g = newGame();
        g.afterWin(Levels.COUNT - 1, true);
        assertTrue(g.screen instanceof StoryScreen);
        g.afterWin(Levels.COUNT - 1, false);
        assertTrue(g.screen instanceof ShopScreen);
    }

    @Test
    public void winningTheFinalNightMarksTheGameCompleted() {
        Game g = newGame();
        g.save.unlocked = Levels.COUNT - 1;
        g.setScreen(new PlayScreen(g, Levels.COUNT - 1, false));
        PlayScreen p = (PlayScreen) g.screen;
        p.world.bossDefeated = true; // boss öldü
        run(g, 0.2f);
        assertEquals(World.State.WON, p.world.state);
        assertTrue(g.save.completed);
    }

    @Test
    public void progressSurvivesRestart() {
        Game g = newGame();
        g.save.unlocked = 3;
        g.save.sparks = 123;
        g.save.up.level[2] = 4;
        g.save.completed = true;
        g.persist();
        Game again = new Game(RuntimeEnvironment.getApplication());
        assertEquals(3, again.save.unlocked);
        assertEquals(123, again.save.sparks);
        assertEquals(4, again.save.up.level[2]);
        assertTrue(again.save.completed);
    }

    @Test
    public void endlessModeUnlocksAfterCompletionAndRecordsBestTime() throws Exception {
        Game g = newGame();
        g.save.completed = true;
        g.setScreen(new MenuScreen(g));
        shot(g, "06_menu_completed");
        tap(g, 540, 1310 + 128 + 28 + 60); // SONSUZ GECE
        assertTrue(g.screen instanceof PlayScreen);
        PlayScreen p = (PlayScreen) g.screen;
        run(g, 12f);
        // duraklat, görüntüle, "BİTİR" ile sonlandır
        tap(g, 995, 90);
        shot(g, "50_pause");
        tap(g, 540, 2340 * 0.42f + 225f);
        run(g, 0.1f);
        assertEquals(World.State.LOST, p.world.state);
        assertTrue(g.save.endlessBest > 10f);
        shot(g, "43_endless_result");
    }

    // ------------------------------------------------------------------- oynanış

    @Test
    public void playsNightWithBeamAndFlash() throws Exception {
        Game g = newGame();
        g.setScreen(new PlayScreen(g, 0, false));
        PlayScreen p = (PlayScreen) g.screen;
        long now = SystemClock.uptimeMillis();
        g.screen.onTouch(MotionEvent.obtain(now, now, MotionEvent.ACTION_DOWN, 800, 400, 0));
        float[][] aims = {{800, 400}, {300, 700}, {200, 1500}, {900, 1700}};
        for (int i = 0; i < 40; i++) {
            float[] a = aims[(i / 5) % aims.length];
            g.screen.onTouch(MotionEvent.obtain(now, now + i * 20, MotionEvent.ACTION_MOVE, a[0], a[1], 0));
            run(g, 0.5f);
            if (i == 6) shot(g, "10_play_early");
            if (i == 20) {
                tap(g, 905, 2090);
                run(g, 0.2f);
                shot(g, "11_play_flash");
            }
        }
        shot(g, "12_play_late");
        assertNotNull(p);
    }

    @Test
    public void touchControlsAimTheBeamAndFlashButtonFires() {
        Game g = newGame();
        g.setScreen(new PlayScreen(g, 0, false));
        PlayScreen p = (PlayScreen) g.screen;
        long now = SystemClock.uptimeMillis();
        // fenerin sağına dokun: ışın doğuya (açı ≈ 0) dönmeli
        g.screen.onTouch(MotionEvent.obtain(now, now, MotionEvent.ACTION_DOWN, 900, 1170, 0));
        run(g, 0.6f);
        assertTrue(p.world.beamOn);
        assertEquals(0f, World.wrap(p.world.beamAngle), 0.05f);
        // parmağı kaldırınca ışın kapanır
        g.screen.onTouch(MotionEvent.obtain(now, now + 100, MotionEvent.ACTION_UP, 900, 1170, 0));
        run(g, 0.1f);
        assertFalse(p.world.beamOn);
        // parlama düğmesi
        assertEquals(0f, p.world.flashCd, 0f);
        tap(g, 905, 2090);
        assertTrue(p.world.flashCd > 0f);
    }

    @Test
    public void bossesRender() throws Exception {
        Game g = newGame();
        g.save.up.level[0] = 3;
        g.save.up.level[1] = 3;
        int i = 0;
        for (int night : new int[]{2, 4}) {
            g.setScreen(new PlayScreen(g, night, false));
            PlayScreen p = (PlayScreen) g.screen;
            ShadowType type = night == 2 ? ShadowType.CAPTAIN : ShadowType.MOTHER;
            Shadow boss = new Shadow(type, 150f, -330f, 1f, 0f);
            boss.hp = boss.maxHp * 0.6f;
            p.world.shadows.add(boss);
            p.world.shadows.add(new Shadow(ShadowType.ARMORED, -300f, 250f, 1f, 0f));
            p.world.shadows.add(new Shadow(ShadowType.SPLITTER, 260f, 330f, 1f, 0f));
            p.world.shadows.add(new Shadow(ShadowType.RUNNER, -250f, -200f, 1f, 0f));
            long now = SystemClock.uptimeMillis();
            g.screen.onTouch(MotionEvent.obtain(now, now, MotionEvent.ACTION_DOWN, 540 + 150, 1170 - 330, 0));
            run(g, 0.7f);
            shot(g, "21_boss_" + (++i));
        }
    }

    @Test
    public void bossNightHudCountsDownToTheBoss() throws Exception {
        Game g = newGame();
        g.setScreen(new PlayScreen(g, 2, false));
        PlayScreen p = (PlayScreen) g.screen;
        assertEquals(0f, p.world.progress(), 0.001f);
        p.world.time = p.world.level.bossAt * 0.5f;
        assertEquals(0.075f, p.world.progress(), 0.01f);
        shot(g, "22_boss_countdown");
    }

    @Test
    public void lanternHitFeedbackRenders() throws Exception {
        Game g = newGame();
        g.setScreen(new PlayScreen(g, 0, false));
        PlayScreen p = (PlayScreen) g.screen;
        p.world.shadows.add(new Shadow(ShadowType.CRAWLER, 0f, -60f, 1f, 0f));
        p.world.shadows.add(new Shadow(ShadowType.CRAWLER, 200f, 150f, 1f, 0f));
        float before = p.world.oil;
        run(g, 0.15f);
        assertTrue("fener darbe almalıydı", p.world.oil < before);
        shot(g, "13_hit_feedback");
    }

    @Test
    public void layoutFitsOtherScreenShapes() throws Exception {
        int[][] sizes = {{1080, 1920}, {720, 1280}, {800, 1280}, {1440, 3200}};
        for (int[] sz : sizes) {
            Application app = RuntimeEnvironment.getApplication();
            Game g = new Game(app);
            g.sfx.enabled = false;
            g.resize(sz[0], sz[1]);
            String tag = sz[0] + "x" + sz[1];
            g.save.sparks = 70;
            g.save.unlocked = 2;
            g.setScreen(new MenuScreen(g));
            run(g, 0.5f);
            shot(g, "60_menu_" + tag);
            g.setScreen(new ShopScreen(g));
            shot(g, "61_shop_" + tag);
            g.setScreen(new HowToScreen(g));
            shot(g, "62_howto_" + tag);
            g.setScreen(new StoryScreen(g, Story.NIGHT_INTRO[2], () -> {
            }));
            run(g, 8f);
            shot(g, "63_story_" + tag);
            g.setScreen(new PlayScreen(g, 2, false));
            PlayScreen p = (PlayScreen) g.screen;
            p.world.shadows.add(new Shadow(ShadowType.CAPTAIN, 120f, -300f, 1f, 0f));
            run(g, 1f);
            shot(g, "64_play_" + tag);
            p.world.oil = 0f;
            run(g, 3f);
            shot(g, "65_lost_" + tag);
        }
    }
}
