package com.tigirer.sonfener;

import android.content.Context;
import android.graphics.Canvas;
import android.view.MotionEvent;
import android.view.View;

/** Tek iş parçacıklı oyun döngüsü: güncelle, çiz, sonraki kareyi iste. */
final class GameView extends View {
    private final Game game;
    private long last;

    GameView(Context ctx) {
        super(ctx);
        game = new Game(ctx);
        setKeepScreenOn(true);
    }

    Game game() {
        return game;
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        if (w > 0 && h > 0) game.resize(w, h);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        long now = System.nanoTime();
        float dt = last == 0 ? 0f : Math.min(0.05f, (now - last) / 1e9f);
        last = now;
        if (game.w > 0) {
            game.screen.update(dt);
            game.screen.draw(canvas);
        }
        postInvalidateOnAnimation();
    }

    @Override
    public boolean onTouchEvent(MotionEvent e) {
        game.screen.onTouch(e);
        return true;
    }

    void resumed() {
        last = 0;
        invalidate();
    }
}
