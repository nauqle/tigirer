package com.tigirer.sonfener.core;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public class WorldTest {
    private static final float DT = 1f / 60f;

    private static World newWorld(int night) {
        return new World(Levels.get(night), new Upgrades(), 2.1f, 1L);
    }

    @Test
    public void idlePlayerLosesTheFirstNight() {
        World w = newWorld(0);
        for (int i = 0; i < 60 * 120 && w.state == World.State.PLAYING; i++) w.update(DT);
        assertEquals(World.State.LOST, w.state);
        assertEquals(0f, w.oil, 0f);
    }

    @Test
    public void beamDamagesOnlyShadowsInsideTheCone() {
        World w = newWorld(0);
        Shadow inside = new Shadow(ShadowType.CRAWLER, 0f, -300f, 1f, 0f);
        Shadow outside = new Shadow(ShadowType.CRAWLER, 300f, 0f, 1f, 0f);
        w.shadows.add(inside);
        w.shadows.add(outside);
        w.setBeam(true, (float) (-Math.PI / 2));
        w.update(DT);
        assertTrue(inside.lit);
        assertTrue(inside.hp < inside.maxHp);
        assertFalse(outside.lit);
        assertEquals(outside.maxHp, outside.hp, 0f);
    }

    @Test
    public void shadowsBeyondBeamRangeAreNotHit() {
        World w = newWorld(0);
        Shadow far = new Shadow(ShadowType.CRAWLER, 0f, -(World.BEAM_RANGE + 200f), 1f, 0f);
        w.shadows.add(far);
        w.setBeam(true, (float) (-Math.PI / 2));
        w.update(DT);
        assertFalse(far.lit);
    }

    @Test
    public void overheatingShutsTheBeamUntilEnergyRecovers() {
        World w = newWorld(0);
        w.setBeam(true, w.beamAngle);
        int guard = 0;
        while (!w.overheated && guard++ < 60 * 10) w.update(DT);
        assertTrue(w.overheated);
        assertFalse(w.beamOn);
        w.setBeam(false, w.beamAngle);
        guard = 0;
        while (w.overheated && guard++ < 60 * 10) w.update(DT);
        assertFalse(w.overheated);
        assertTrue(w.energy >= w.up.maxEnergy() * World.RECOVER_FRACTION - 1f);
    }

    @Test
    public void shadowReachingTheLanternCostsOilAndDropsNoSparks() {
        World w = newWorld(0);
        w.shadows.add(new Shadow(ShadowType.CRAWLER, 0f, -(World.LANTERN_R + 5f), 1f, 0f));
        float before = w.oil;
        w.update(DT);
        assertEquals(before - ShadowType.CRAWLER.damage, w.oil, 0.001f);
        assertEquals(0, w.sparks);
        assertEquals(0, w.kills);
        // yalnızca bu karede kenardan doğan yeni gölge kalmış olmalı
        assertEquals(1, w.shadows.size());
        assertTrue(w.shadows.get(0).dist() > 400f);
    }

    @Test
    public void flashHurtsPushesAndRespectsCooldown() {
        World w = newWorld(0);
        Shadow s = new Shadow(ShadowType.ARMORED, 0f, -200f, 1f, 0f);
        w.shadows.add(s);
        assertTrue(w.flash());
        assertEquals(s.maxHp - w.up.flashDamage(), s.hp, 0.001f);
        assertTrue(s.dist() > 200f);
        assertFalse(w.flash());
        assertTrue(w.flashCd > 0f);
    }

    @Test
    public void flashIgnoresArmorWhileBeamDoesNot() {
        World w = newWorld(0);
        Shadow armored = new Shadow(ShadowType.ARMORED, 0f, -300f, 1f, 0f);
        w.shadows.add(armored);
        w.setBeam(true, (float) (-Math.PI / 2));
        w.update(1f);
        float beamLoss = armored.maxHp - armored.hp;
        assertEquals(w.up.beamDps() * ShadowType.ARMORED.beamFactor, beamLoss, 1.5f);
    }

    @Test
    public void splitterBreaksIntoTwoSplitlings() {
        World w = newWorld(3);
        Shadow s = new Shadow(ShadowType.SPLITTER, 0f, -300f, 1f, 0f);
        s.hp = 0f;
        w.shadows.add(s);
        w.update(DT);
        int splitlings = 0;
        for (Shadow o : w.shadows) if (o.type == ShadowType.SPLITLING) splitlings++;
        assertEquals(2, splitlings);
        assertEquals(1, w.kills);
        assertEquals(ShadowType.SPLITTER.sparks, w.sparks);
    }

    @Test
    public void bossNightIsWonOnlyWhenTheBossDies() {
        World w = newWorld(2);
        w.setBeam(false, 0f);
        // zaman dolsa bile boss yaşıyorsa gece bitmez
        w.time = w.level.duration + 10f;
        w.update(DT);
        assertNotNull(w.boss);
        assertEquals(World.State.PLAYING, w.state);
        w.boss.hp = 0f;
        w.update(DT);
        assertEquals(World.State.WON, w.state);
        assertTrue(w.sparks >= ShadowType.CAPTAIN.sparks);
    }

    @Test
    public void normalNightIsWonAtDawnAndShadowsVanish() {
        World w = newWorld(0);
        w.time = w.level.duration;
        w.shadows.add(new Shadow(ShadowType.CRAWLER, 0f, -400f, 1f, 0f));
        w.update(DT);
        assertEquals(World.State.WON, w.state);
        assertTrue(w.shadows.isEmpty());
    }

    @Test
    public void beamTurnsAtLimitedSpeed() {
        World w = newWorld(0);
        float start = w.beamAngle;
        w.setBeam(true, start + 3f);
        w.update(DT);
        assertEquals(World.TURN_SPEED * DT, Math.abs(World.wrap(w.beamAngle - start)), 1e-4f);
    }

    @Test
    public void wrapKeepsAnglesWithinPi() {
        assertEquals(-Math.PI + 0.1, World.wrap((float) (Math.PI + 0.1)), 1e-4);
        assertEquals(0.5f, World.wrap(0.5f + (float) (Math.PI * 4)), 1e-3f);
    }

    @Test
    public void endlessNightNeverEndsByTimeAndSpawnsBosses() {
        World w = new World(Levels.endless(), new Upgrades().copy(), 2.1f, 3L);
        w.oil = 1e9f;
        for (int i = 0; i < 60 * 80; i++) w.update(DT);
        assertEquals(World.State.PLAYING, w.state);
        assertTrue(w.bossSpawned);
    }
}
