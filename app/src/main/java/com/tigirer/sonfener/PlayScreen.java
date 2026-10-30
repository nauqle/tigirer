package com.tigirer.sonfener;

import android.graphics.Canvas;
import android.graphics.Paint;
import android.view.MotionEvent;

import com.tigirer.sonfener.core.LevelDef;
import com.tigirer.sonfener.core.Levels;
import com.tigirer.sonfener.core.SaveData;
import com.tigirer.sonfener.core.Shadow;
import com.tigirer.sonfener.core.World;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/** Asıl oyun: bir gece. night = -1 ve endless=true ise Sonsuz Gece. */
final class PlayScreen extends Screen implements World.Listener {
    private static final int MAX_PARTICLES = 320;

    private final int night;
    private final boolean endless;
    final World world;
    private final Random fx = new Random();
    private final boolean firstClear;

    // parçacıklar (dünya koordinatları)
    private final float[] px = new float[MAX_PARTICLES], py = new float[MAX_PARTICLES];
    private final float[] vx = new float[MAX_PARTICLES], vy = new float[MAX_PARTICLES];
    private final float[] life = new float[MAX_PARTICLES], size = new float[MAX_PARTICLES];
    private final int[] kind = new int[MAX_PARTICLES];
    private int pn;

    private float t;
    private float shake, hitFx, dawnT, endT;
    private float banner;
    private String bannerText = "";
    private boolean paused;
    private boolean finished;
    private int earnedTotal, earnedBonus;
    private boolean newBest;

    private int beamPointer = -1, flashPointer = -1;
    private float flashPress;

    private final Gfx.Button pauseBtn = new Gfx.Button();
    private final Gfx.Button resume = new Gfx.Button();
    private final Gfx.Button quit = new Gfx.Button();
    private final Gfx.Button primary = new Gfx.Button();
    private final Gfx.Button shop = new Gfx.Button();
    private final Gfx.Button menu = new Gfx.Button();
    private final List<Gfx.Button> buttons = new ArrayList<>();
    private float flashX, flashY, flashR;

    PlayScreen(Game g, int night, boolean endless) {
        super(g);
        this.night = night;
        this.endless = endless;
        LevelDef def = endless ? Levels.endless() : Levels.get(night);
        float aspect = g.h > 0 && g.w > 0 ? g.h / (float) g.w : 2f;
        this.world = new World(def, g.save.up.copy(), aspect, System.nanoTime());
        this.world.setListener(this);
        SaveData s = g.save;
        this.firstClear = !endless && night >= s.unlocked && !(night == Levels.COUNT - 1 && s.completed);
        buttons.add(pauseBtn);
        buttons.add(resume);
        buttons.add(quit);
        buttons.add(primary);
        buttons.add(shop);
        buttons.add(menu);
    }

    @Override
    void onResize() {
        float u = g.u;
        pauseBtn.set(g.w - 135f * u, 40f * u, g.w - 35f * u, 140f * u, "II", false);
        flashR = 105f * u;
        flashX = g.w - 175f * u;
        flashY = g.h - 250f * u;
        float bw = 330f * u;
        resume.set(g.w / 2f - bw, g.h * 0.42f, g.w / 2f + bw, g.h * 0.42f + 130f * u, "DEVAM", true);
        quit.set(g.w / 2f - bw, g.h * 0.42f + 160f * u, g.w / 2f + bw, g.h * 0.42f + 290f * u,
                "ÇIK", false);
        float y = g.h * 0.60f;
        primary.set(g.w / 2f - bw, y, g.w / 2f + bw, y + 130f * u, "", true);
        shop.set(g.w / 2f - bw, y + 160f * u, g.w / 2f + bw, y + 290f * u, "ATÖLYE", false);
        menu.set(g.w / 2f - bw, y + 320f * u, g.w / 2f + bw, y + 450f * u, "MENÜ", false);
    }

    // ------------------------------------------------------------ dünya olayları

    @Override
    public void onKill(Shadow s) {
        g.sfx.kill();
        int n = Math.min(8, 2 + s.type.sparks / 2 + (s.type.isBoss() ? 12 : 0));
        for (int i = 0; i < n; i++) {
            float a = fx.nextFloat() * 6.283f, v = 90f + fx.nextFloat() * 220f;
            addParticle(0, s.x, s.y, (float) Math.cos(a) * v, (float) Math.sin(a) * v, 1.6f, 7f);
        }
        for (int i = 0; i < 5; i++) {
            float a = fx.nextFloat() * 6.283f, v = 40f + fx.nextFloat() * 80f;
            addParticle(1, s.x, s.y, (float) Math.cos(a) * v, (float) Math.sin(a) * v, 0.5f, s.type.radius * 0.5f);
        }
        if (s.type.isBoss()) {
            banner = 3f;
            bannerText = s.type.label + " dağıldı!";
        }
    }

    @Override
    public void onLanternHit(float damage) {
        shake = 0.35f;
        hitFx = 0.6f;
        g.sfx.hurt();
        g.buzz(35);
    }

    @Override
    public void onFlash() {
        g.sfx.flash();
        g.buzz(20);
    }

    @Override
    public void onBossSpawn(Shadow boss) {
        banner = 3.2f;
        bannerText = boss.type.label.toUpperCase(java.util.Locale.forLanguageTag("tr-TR")) + " YAKLAŞIYOR!";
        g.sfx.boss();
        g.buzz(80);
    }

    @Override
    public void onOverheat() {
        g.sfx.overheat();
    }

    @Override
    public void onDawn() {
        g.sfx.dawn();
    }

    private void addParticle(int k, float x, float y, float dx, float dy, float l, float sz) {
        if (pn >= MAX_PARTICLES) return;
        px[pn] = x;
        py[pn] = y;
        vx[pn] = dx;
        vy[pn] = dy;
        life[pn] = l;
        size[pn] = sz;
        kind[pn] = k;
        pn++;
    }

    // ------------------------------------------------------------------ güncelle

    @Override
    void update(float dt) {
        t += dt;
        if (flashPress > 0f) flashPress -= dt;
        if (banner > 0f) banner -= dt;
        if (shake > 0f) shake -= dt;
        if (hitFx > 0f) hitFx -= dt;
        if (paused) return;

        updateParticles(dt);
        if (world.state == World.State.PLAYING) {
            world.update(dt);
            if (world.state == World.State.LOST) g.sfx.lose();
            if (world.state != World.State.PLAYING) finishRun();
        } else {
            endT += dt;
            if (world.state == World.State.WON) dawnT = Math.min(1f, dawnT + dt / 2.2f);
        }
        if (world.beamOn) {
            for (Shadow sh : world.shadows) {
                if (sh.lit) {
                    g.sfx.hit();
                    break;
                }
            }
        }
    }

    private void updateParticles(float dt) {
        for (int i = pn - 1; i >= 0; i--) {
            life[i] -= dt;
            boolean dead = life[i] <= 0f;
            if (kind[i] == 0) {
                float d = (float) Math.sqrt(px[i] * px[i] + py[i] * py[i]);
                if (life[i] < 1.2f && d > 1f) {
                    float pull = 900f * dt;
                    vx[i] += -px[i] / d * pull;
                    vy[i] += -py[i] / d * pull;
                }
                vx[i] *= 1f - 1.5f * dt;
                vy[i] *= 1f - 1.5f * dt;
                if (d < World.LANTERN_R) dead = true;
            }
            px[i] += vx[i] * dt;
            py[i] += vy[i] * dt;
            if (dead) {
                pn--;
                px[i] = px[pn];
                py[i] = py[pn];
                vx[i] = vx[pn];
                vy[i] = vy[pn];
                life[i] = life[pn];
                size[i] = size[pn];
                kind[i] = kind[pn];
            }
        }
    }

    /** Koşu bittiğinde bir kez: ödülleri hesapla ve kaydet. */
    private void finishRun() {
        if (finished) return;
        finished = true;
        SaveData s = g.save;
        boolean won = world.state == World.State.WON;
        if (endless) {
            earnedTotal = world.sparks;
            if (world.time > s.endlessBest) {
                s.endlessBest = world.time;
                newBest = true;
            }
        } else if (won) {
            earnedBonus = firstClear ? 15 * (night + 1) : 0;
            earnedTotal = world.sparks + earnedBonus;
            if (night < Levels.COUNT - 1 && night + 1 > s.unlocked) s.unlocked = night + 1;
            if (night == Levels.COUNT - 1) s.completed = true;
        } else {
            earnedTotal = world.sparks / 2;
        }
        s.sparks += earnedTotal;
        g.persist();
    }

    // ------------------------------------------------------------------- çizim

    @Override
    void draw(Canvas c) {
        float u = g.u;
        float s = g.w / 1000f;
        float cx = g.w / 2f, cy = g.h / 2f;
        float prog = world.progress();
        Gfx.background(c, t, Math.max(dawnT, prog * prog * 0.2f));

        c.save();
        if (shake > 0f) {
            float m = shake * 22f * u;
            c.translate((fx.nextFloat() - 0.5f) * m, (fx.nextFloat() - 0.5f) * m);
        }
        float energy01 = world.state == World.State.WON ? 1f : world.energy / world.up.maxEnergy();
        Gfx.lanternGlow(c, cx, cy, s, t, energy01, world.beamOn);
        if (world.beamOn) {
            Gfx.beam(c, cx, cy, s, world.beamAngle, world.up.beamHalfAngle(), 1f, t);
        }
        for (Shadow sh : world.shadows) Gfx.shadow(c, sh, cx, cy, s, t);
        drawParticles(c, cx, cy, s);
        Gfx.lanternBody(c, cx, cy, s, energy01);
        Gfx.ring(c, cx, cy, 98f * s, 7f * s, energy01, world.overheated ? Gfx.RED : Gfx.CYAN, 0x22FFFFFF);
        if (world.flashFx > 0f) Gfx.flashRing(c, cx, cy, s, 1f - world.flashFx / 0.5f);
        if (world.overheated) {
            Gfx.text(c, "ISINDI", cx, cy + 165f * s, 36f * u, Gfx.alpha(Gfx.RED, 0.75f + 0.25f * (float) Math.sin(t * 14f)),
                    Paint.Align.CENTER, Gfx.SANS_BOLD);
        }
        c.restore();

        if (hitFx > 0f) Gfx.hitFlash(c, hitFx / 0.6f);
        Gfx.vignette(c);
        drawHud(c, u);

        if (banner > 0f) {
            float a = Math.min(1f, banner);
            Gfx.text(c, bannerText, g.w / 2f, g.h * 0.2f, 58f * u, Gfx.alpha(Gfx.GOLD_SOFT, a), Paint.Align.CENTER,
                    Gfx.SANS_BOLD);
        }
        drawHint(c, u);
        if (paused) drawPause(c, u);
        else if (world.state != World.State.PLAYING && endT > (world.state == World.State.WON ? 2.0f : 1.2f)) {
            drawResult(c, u);
        }
    }

    private void drawParticles(Canvas c, float cx, float cy, float s) {
        for (int i = 0; i < pn; i++) {
            float x = cx + px[i] * s, y = cy + py[i] * s;
            if (kind[i] == 0) {
                Gfx.glow(c, x, y, size[i] * s * 3f, 0.8f);
                Gfx.circleFill(c, x, y, size[i] * s * 0.7f, Gfx.GOLD_SOFT);
            } else {
                float k = Math.max(0f, life[i] / 0.5f);
                Gfx.circleFill(c, x, y, size[i] * s * (1.6f - k), Gfx.alpha(0xFF39406B, k * 0.7f));
            }
        }
    }

    private void drawHud(Canvas c, float u) {
        float m = 40f * u;
        LevelDef lv = world.level;
        Gfx.text(c, lv.name, m, 85f * u, 36f * u, Gfx.alpha(Gfx.TEXT, 0.85f), Paint.Align.LEFT, Gfx.SANS_BOLD);
        if (endless) {
            Gfx.text(c, clock(world.time), m, 135f * u, 44f * u, Gfx.GOLD_SOFT, Paint.Align.LEFT, Gfx.SANS_BOLD);
        } else {
            boolean boss = lv.boss != null;
            Gfx.bar(c, m, 112f * u, g.w - 170f * u, 130f * u, world.progress(),
                    boss ? 0xFFD04CFF : Gfx.GOLD, 0x44FFFFFF);
            String lbl;
            if (!boss) lbl = "Şafağa " + Math.max(0, (int) Math.ceil(lv.duration - world.time)) + " sn";
            else if (world.boss != null) lbl = world.boss.type.label;
            else lbl = lv.boss.label + " geliyor · " + Math.max(0, (int) Math.ceil(lv.bossAt - world.time)) + " sn";
            Gfx.text(c, lbl, m, 175f * u, 28f * u, Gfx.MUTED, Paint.Align.LEFT, Gfx.SANS_MED);
        }
        Gfx.button(c, pauseBtn, u, pressed() == pauseBtn);

        // yağ ve enerji
        float bx = m, bw = 540f * u;
        float oy = g.h - 190f * u, ey = g.h - 120f * u;
        Gfx.text(c, "Yağ", bx, oy - 12f * u, 28f * u, Gfx.MUTED, Paint.Align.LEFT, Gfx.SANS_MED);
        float oil01 = world.oil / world.up.maxOil();
        Gfx.bar(c, bx + 110f * u, oy - 34f * u, bx + bw, oy - 8f * u, oil01,
                oil01 < 0.3f ? Gfx.RED : 0xFFFF9F43, 0x44FFFFFF);
        Gfx.text(c, "Enerji", bx, ey - 12f * u, 28f * u, Gfx.MUTED, Paint.Align.LEFT, Gfx.SANS_MED);
        Gfx.bar(c, bx + 110f * u, ey - 34f * u, bx + bw, ey - 8f * u, world.energy / world.up.maxEnergy(),
                world.overheated ? Gfx.RED : Gfx.CYAN, 0x44FFFFFF);
        Gfx.circleFill(c, bx + 14f * u, g.h - 260f * u, 14f * u, Gfx.GOLD);
        Gfx.text(c, String.valueOf(world.sparks), bx + 44f * u, g.h - 247f * u, 40f * u, Gfx.GOLD_SOFT,
                Paint.Align.LEFT, Gfx.SANS_BOLD);

        // parlama düğmesi
        boolean ready = world.flashCd <= 0f;
        float r = flashR * (flashPress > 0f ? 0.92f : 1f);
        Gfx.circleFill(c, flashX, flashY, r, ready ? Gfx.alpha(Gfx.GOLD, 0.92f) : 0xAA121A33);
        Gfx.ring(c, flashX, flashY, r, 9f * u,
                ready ? 1f : 1f - world.flashCd / world.up.flashCooldown(), ready ? Gfx.GOLD_SOFT : Gfx.CYAN);
        Gfx.text(c, "PARLAMA", flashX, flashY + 12f * u, 29f * u, ready ? Gfx.INK : Gfx.MUTED, Paint.Align.CENTER,
                Gfx.SANS_BOLD);
    }

    private void drawHint(Canvas c, float u) {
        String hint = null;
        if (night == 0 && !endless) {
            if (world.time < 9f) hint = "Parmağını ekranda kaydır: ışık o yöne döner";
            else if (world.time < 17f) hint = "Işın enerji harcar. Enerji çubuğuna dikkat et";
        } else if (night == 2 && world.time < 8f) {
            hint = "Zırhlı gölgeler için PARLAMA'yı kullan";
        }
        if (hint != null && world.state == World.State.PLAYING && !paused) {
            Gfx.text(c, hint, g.w / 2f, g.h * 0.82f - 140f * u, 38f * u, Gfx.alpha(Gfx.TEXT, 0.8f),
                    Paint.Align.CENTER, Gfx.SERIF_ITALIC);
        }
    }

    private void dim(Canvas c, float a) {
        c.drawRect(0, 0, g.w, g.h, Gfx.fill(Gfx.alpha(0xFF02040A, a)));
    }

    private void drawPause(Canvas c, float u) {
        dim(c, 0.72f);
        Gfx.text(c, "DURAKLATILDI", g.w / 2f, g.h * 0.32f, 76f * u, Gfx.GOLD, Paint.Align.CENTER, Gfx.SANS_BOLD);
        Gfx.button(c, resume, u, pressed() == resume);
        quit.label = endless ? "BİTİR" : "ÇIK";
        Gfx.button(c, quit, u, pressed() == quit);
    }

    private void drawResult(Canvas c, float u) {
        boolean won = world.state == World.State.WON;
        dim(c, won ? 0.5f : 0.7f);
        float cx = g.w / 2f;
        String title = won ? "ŞAFAK!" : "FENER SÖNDÜ";
        Gfx.text(c, title, cx, g.h * 0.24f, 100f * u, won ? Gfx.GOLD : Gfx.RED, Paint.Align.CENTER, Gfx.SANS_BOLD);
        float y = g.h * 0.31f;
        float lh = 58f * u;
        if (endless) {
            y = line(c, "Dayandığın süre: " + clock(world.time), cx, y, lh, u, Gfx.TEXT);
            y = line(c, newBest ? "Yeni rekor!" : "En iyi: " + clock(g.save.endlessBest), cx, y, lh, u,
                    newBest ? Gfx.GOLD_SOFT : Gfx.MUTED);
        } else if (won) {
            y = line(c, "Kalan yağ: %" + Math.round(world.oil / world.up.maxOil() * 100f), cx, y, lh, u, Gfx.TEXT);
        } else {
            y = line(c, "Sis bu gece kazandı, ama ışık hâlâ seninle.", cx, y, lh, u, Gfx.MUTED);
        }
        y = line(c, "Dağıtılan gölge: " + world.kills, cx, y, lh, u, Gfx.TEXT);
        String spark = "Kazanılan kıvılcım: " + earnedTotal;
        if (earnedBonus > 0) spark += "  (şafak bonusu +" + earnedBonus + ")";
        else if (!won && !endless) spark += "  (yarısı)";
        line(c, spark, cx, y, lh, u, Gfx.GOLD_SOFT);

        primary.label = endless ? "TEKRAR DENE" : (won ? "DEVAM" : "TEKRAR DENE");
        Gfx.button(c, primary, u, pressed() == primary);
        shop.enabled = true;
        Gfx.button(c, shop, u, pressed() == shop);
        Gfx.button(c, menu, u, pressed() == menu);
    }

    private float line(Canvas c, String s, float cx, float y, float lh, float u, int color) {
        Gfx.text(c, s, cx, y, 42f * u, color, Paint.Align.CENTER, Gfx.SANS_MED);
        return y + lh;
    }

    static String clock(float sec) {
        int s = (int) sec;
        return String.format(java.util.Locale.US, "%d:%02d", s / 60, s % 60);
    }

    // ------------------------------------------------------------------- girdi

    @Override
    void onTouch(MotionEvent e) {
        boolean overlay = paused || (world.state != World.State.PLAYING
                && endT > (world.state == World.State.WON ? 2.0f : 1.2f));
        if (overlay) {
            clickOverlay(handleButtons(e, buttons));
            return;
        }
        int action = e.getActionMasked();
        if (world.state != World.State.PLAYING) return;

        // duraklatma düğmesi yalnızca ilk parmakla
        if (action == MotionEvent.ACTION_DOWN && pauseBtn.hit(e.getX(), e.getY())) {
            paused = true;
            releaseBeam();
            return;
        }
        switch (action) {
            case MotionEvent.ACTION_DOWN:
            case MotionEvent.ACTION_POINTER_DOWN: {
                int i = e.getActionIndex();
                int id = e.getPointerId(i);
                float x = e.getX(i), y = e.getY(i);
                float dx = x - flashX, dy = y - flashY;
                float reach = flashR * 1.25f;
                if (dx * dx + dy * dy <= reach * reach) {
                    flashPointer = id;
                    flashPress = 0.12f;
                    world.flash();
                } else if (beamPointer < 0) {
                    beamPointer = id;
                    aim(x, y);
                }
                break;
            }
            case MotionEvent.ACTION_MOVE:
                for (int i = 0; i < e.getPointerCount(); i++) {
                    if (e.getPointerId(i) == beamPointer) aim(e.getX(i), e.getY(i));
                }
                break;
            case MotionEvent.ACTION_POINTER_UP:
            case MotionEvent.ACTION_UP: {
                int id = e.getPointerId(e.getActionIndex());
                if (id == beamPointer) releaseBeam();
                if (id == flashPointer) flashPointer = -1;
                break;
            }
            case MotionEvent.ACTION_CANCEL:
                releaseBeam();
                flashPointer = -1;
                break;
            default:
                break;
        }
    }

    private void aim(float x, float y) {
        float dx = x - g.w / 2f, dy = y - g.h / 2f;
        if (dx * dx + dy * dy < (40f * g.u) * (40f * g.u)) {
            world.setBeam(true, world.beamAngle);
            return;
        }
        world.setBeam(true, (float) Math.atan2(dy, dx));
    }

    private void releaseBeam() {
        beamPointer = -1;
        world.setBeam(false, world.beamAngle);
    }

    private void clickOverlay(Gfx.Button b) {
        if (b == null) return;
        if (paused) {
            if (b == resume) {
                paused = false;
            } else if (b == quit) {
                if (endless) {
                    paused = false;
                    world.forfeit();
                    finishRun();
                    endT = 5f;
                } else {
                    g.showMenu();
                }
            }
            return;
        }
        boolean won = world.state == World.State.WON;
        if (b == primary) {
            if (endless) g.startEndless();
            else if (won) g.afterWin(night, firstClear);
            else g.setScreen(new PlayScreen(g, night, false));
        } else if (b == shop) {
            g.setScreen(new ShopScreen(g));
        } else if (b == menu) {
            g.showMenu();
        }
    }

    @Override
    void onBack() {
        if (world.state != World.State.PLAYING) {
            g.showMenu();
        } else {
            paused = !paused;
            releaseBeam();
        }
    }

    @Override
    void onPause() {
        if (world.state == World.State.PLAYING) {
            paused = true;
            releaseBeam();
        }
    }
}
