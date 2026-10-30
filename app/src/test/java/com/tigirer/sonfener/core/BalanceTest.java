package com.tigirer.sonfener.core;

import static org.junit.Assert.assertTrue;

import org.junit.Test;

/** Bot oyuncuyla zorluk eğrisinin bozulmadığını doğrular (geniş eşikler). */
public class BalanceTest {
    private static int wins(int night, int[] levels, int runs) {
        int w = 0;
        for (int seed = 1; seed <= runs; seed++) {
            Upgrades u = new Upgrades();
            System.arraycopy(levels, 0, u.level, 0, Upgrades.COUNT);
            if (new Bot(night, u, seed, 0.35f, 2.1f, 200f).result == World.State.WON) w++;
        }
        return w;
    }

    @Test
    public void earlyNightsAreWinnableWithoutUpgrades() {
        assertTrue(wins(0, new int[]{0, 0, 0, 0, 0, 0}, 10) >= 9);
        assertTrue(wins(1, new int[]{0, 0, 0, 0, 0, 0}, 10) >= 9);
    }

    @Test
    public void lateNightsDemandUpgrades() {
        int[] none = {0, 0, 0, 0, 0, 0};
        assertTrue(wins(2, none, 10) <= 2);
        assertTrue(wins(3, none, 10) <= 3);
        assertTrue(wins(4, none, 10) == 0);
    }

    @Test
    public void everyNightIsWinnableWithEnoughUpgrades() {
        int[] strong = {3, 3, 3, 3, 3, 3};
        for (int n = 0; n < Levels.COUNT; n++) {
            assertTrue("gece " + (n + 1), wins(n, strong, 10) >= 8);
        }
    }

    @Test
    public void finalNightIsOutOfReachForAModestBuild() {
        assertTrue(wins(4, new int[]{2, 2, 1, 1, 1, 0}, 10) <= 2);
    }
}
