package com.tigirer.sonfener.core;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public class SaveAndUpgradeTest {
    @Test
    public void saveRoundTrips() {
        SaveData d = new SaveData();
        d.unlocked = 3;
        d.sparks = 77;
        d.up.level[Upgrades.POWER] = 4;
        d.up.level[Upgrades.FLASH] = 2;
        d.completed = true;
        d.prologueSeen = true;
        d.sound = false;
        d.endlessBest = 123.5f;
        SaveData r = SaveData.parse(d.serialize());
        assertEquals(3, r.unlocked);
        assertEquals(77, r.sparks);
        assertEquals(4, r.up.level[Upgrades.POWER]);
        assertEquals(2, r.up.level[Upgrades.FLASH]);
        assertTrue(r.completed);
        assertTrue(r.prologueSeen);
        assertFalse(r.sound);
        assertEquals(123.5f, r.endlessBest, 0f);
    }

    @Test
    public void corruptSaveFallsBackToDefaults() {
        for (String bad : new String[]{null, "", "garbage", "v1;x;y;z", "v1;1;2;3,4;1;1;1;abc"}) {
            SaveData d = SaveData.parse(bad);
            assertEquals(0, d.unlocked);
            assertEquals(0, d.sparks);
        }
    }

    @Test
    public void outOfRangeValuesAreClamped() {
        SaveData d = SaveData.parse("v1;99;-5;9,9,9,9,9,9;0;0;1;-3.0");
        assertEquals(Levels.COUNT - 1, d.unlocked);
        assertEquals(0, d.sparks);
        assertEquals(Upgrades.MAX_LEVEL, d.up.level[0]);
        assertEquals(0f, d.endlessBest, 0f);
    }

    @Test
    public void buyingSpendsSparksAndStopsAtMaxLevel() {
        Upgrades u = new Upgrades();
        assertEquals(0, u.buy(Upgrades.POWER, 5));
        assertEquals(10, u.buy(Upgrades.POWER, 100));
        assertEquals(1, u.level[Upgrades.POWER]);
        for (int i = 0; i < 10; i++) u.buy(Upgrades.POWER, 1000);
        assertEquals(Upgrades.MAX_LEVEL, u.level[Upgrades.POWER]);
        assertEquals(-1, u.cost(Upgrades.POWER));
        assertFalse(u.canBuy(Upgrades.POWER, 1000));
    }
}
