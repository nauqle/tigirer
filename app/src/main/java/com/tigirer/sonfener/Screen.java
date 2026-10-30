package com.tigirer.sonfener;

import android.graphics.Canvas;
import android.view.MotionEvent;

import java.util.List;

abstract class Screen {
    final Game g;

    Screen(Game g) {
        this.g = g;
    }

    void onResize() {
    }

    void update(float dt) {
    }

    abstract void draw(Canvas c);

    void onTouch(MotionEvent e) {
    }

    private Gfx.Button pressedBtn;

    Gfx.Button pressed() {
        return pressedBtn;
    }

    /** Basma/bırakma ile düğme tıklamasını izler; bırakıldığında tıklanan düğmeyi döndürür. */
    Gfx.Button handleButtons(MotionEvent e, List<Gfx.Button> list) {
        float x = e.getX(), y = e.getY();
        switch (e.getActionMasked()) {
            case MotionEvent.ACTION_DOWN:
                pressedBtn = null;
                for (Gfx.Button b : list) if (b.hit(x, y)) pressedBtn = b;
                break;
            case MotionEvent.ACTION_MOVE:
                if (pressedBtn != null && !pressedBtn.hit(x, y)) pressedBtn = null;
                break;
            case MotionEvent.ACTION_UP:
                Gfx.Button b = pressedBtn;
                pressedBtn = null;
                if (b != null && b.hit(x, y)) {
                    g.sfx.click();
                    return b;
                }
                break;
            case MotionEvent.ACTION_CANCEL:
                pressedBtn = null;
                break;
            default:
                break;
        }
        return null;
    }

    void onBack() {
        g.showMenu();
    }

    void onPause() {
    }
}
