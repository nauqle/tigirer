package com.tigirer.sonfener;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;

import com.tigirer.sonfener.core.Levels;
import com.tigirer.sonfener.core.SaveData;
import com.tigirer.sonfener.core.Story;

/** Ekranlar arası ortak durum ve yönlendirme. */
final class Game {
    private static final String PREFS = "sonfener";
    private static final String KEY = "save";

    final Context ctx;
    final Sfx sfx = new Sfx();
    SaveData save;
    int w, h;
    /** Arayüz ölçeği: 1080 birimlik referans genişliğe göre. */
    float u = 1f;
    Screen screen;
    private final Vibrator vibrator;

    Game(Context ctx) {
        this.ctx = ctx;
        this.vibrator = (Vibrator) ctx.getSystemService(Context.VIBRATOR_SERVICE);
        this.save = SaveData.parse(prefs().getString(KEY, null));
        sfx.enabled = save.sound;
        screen = new MenuScreen(this);
    }

    private SharedPreferences prefs() {
        return ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    void persist() {
        prefs().edit().putString(KEY, save.serialize()).apply();
    }

    void setScreen(Screen s) {
        screen = s;
        s.onResize();
    }

    void resize(int w, int h) {
        this.w = w;
        this.h = h;
        this.u = Math.min(w / 1080f, h / 1920f);
        Gfx.resize(w, h);
        screen.onResize();
    }

    void buzz(int ms) {
        if (!save.sound || vibrator == null) return;
        try {
            if (Build.VERSION.SDK_INT >= 26) {
                vibrator.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE));
            } else {
                vibrator.vibrate(ms);
            }
        } catch (RuntimeException ignored) {
        }
    }

    void setSound(boolean on) {
        save.sound = on;
        sfx.enabled = on;
        persist();
    }

    // ------------------------------------------------------------- akış

    void showMenu() {
        setScreen(new MenuScreen(this));
    }

    /** "Oyna": ilk seferde prolog, sonra atölye. */
    void play() {
        if (!save.prologueSeen) {
            setScreen(new StoryScreen(this, Story.PROLOGUE, () -> {
                save.prologueSeen = true;
                persist();
                startNight(0, true);
            }));
        } else {
            setScreen(new ShopScreen(this));
        }
    }

    void startNight(int index, boolean withIntro) {
        Runnable go = () -> setScreen(new PlayScreen(this, index, false));
        if (withIntro && Story.NIGHT_INTRO[index].length > 0) {
            setScreen(new StoryScreen(this, Story.NIGHT_INTRO[index], go));
        } else {
            go.run();
        }
    }

    void startEndless() {
        setScreen(new PlayScreen(this, -1, true));
    }

    /** Gece kazanıldığında sonuç ekranından çağrılır. */
    void afterWin(int index, boolean firstClear) {
        if (index == Levels.COUNT - 1 && firstClear) {
            setScreen(new StoryScreen(this, Story.EPILOGUE, this::showMenu));
        } else if (firstClear && Story.NIGHT_OUTRO[index].length > 0) {
            setScreen(new StoryScreen(this, Story.NIGHT_OUTRO[index], () -> setScreen(new ShopScreen(this))));
        } else {
            setScreen(new ShopScreen(this));
        }
    }

    void onPause() {
        screen.onPause();
        persist();
    }

    void destroy() {
        sfx.release();
    }
}
