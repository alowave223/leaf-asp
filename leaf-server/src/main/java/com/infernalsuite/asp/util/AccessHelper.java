package com.infernalsuite.asp.util;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

/**
 * Helper to access private/final fields and methods in NMS classes
 * that cannot be made accessible via ATs without breaking existing Leaf patches.
 */
public class AccessHelper {

    // ServerLevel fields
    private static final Field serverLevel_entityDataController;
    private static final Field serverLevel_poiDataController;
    private static final Field serverLevel_chunkTaskScheduler;

    // ChunkEntitySlices field
    private static final Field chunkEntitySlices_entities;

    // MinecraftServer field
    private static final Field minecraftServer_commandStorage;

    // SerializableChunkData methods
    private static final Method serializableChunkData_makeBiomeCodec;
    private static final Method serializableChunkData_postLoadChunk;

    static {
        try {
            serverLevel_entityDataController = net.minecraft.server.level.ServerLevel.class.getDeclaredField("entityDataController");
            serverLevel_entityDataController.setAccessible(true);

            serverLevel_poiDataController = net.minecraft.server.level.ServerLevel.class.getDeclaredField("poiDataController");
            serverLevel_poiDataController.setAccessible(true);

            serverLevel_chunkTaskScheduler = net.minecraft.server.level.ServerLevel.class.getDeclaredField("chunkTaskScheduler");
            serverLevel_chunkTaskScheduler.setAccessible(true);

            chunkEntitySlices_entities = ca.spottedleaf.moonrise.patches.chunk_system.level.entity.ChunkEntitySlices.class.getDeclaredField("entities");
            chunkEntitySlices_entities.setAccessible(true);

            minecraftServer_commandStorage = net.minecraft.server.MinecraftServer.class.getDeclaredField("commandStorage");
            minecraftServer_commandStorage.setAccessible(true);

            serializableChunkData_makeBiomeCodec = net.minecraft.world.level.chunk.storage.SerializableChunkData.class.getDeclaredMethod("makeBiomeCodec", net.minecraft.core.Registry.class);
            serializableChunkData_makeBiomeCodec.setAccessible(true);

            serializableChunkData_postLoadChunk = net.minecraft.world.level.chunk.storage.SerializableChunkData.class.getDeclaredMethod("postLoadChunk", net.minecraft.server.level.ServerLevel.class, java.util.List.class, java.util.List.class);
            serializableChunkData_postLoadChunk.setAccessible(true);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException("Failed to initialize ASP AccessHelper", e);
        }
    }

    @SuppressWarnings("unchecked")
    public static void setEntityDataController(net.minecraft.server.level.ServerLevel level, Object controller) {
        try {
            serverLevel_entityDataController.set(level, controller);
        } catch (IllegalAccessException e) {
            throw new RuntimeException(e);
        }
    }

    @SuppressWarnings("unchecked")
    public static void setPoiDataController(net.minecraft.server.level.ServerLevel level, Object controller) {
        try {
            serverLevel_poiDataController.set(level, controller);
        } catch (IllegalAccessException e) {
            throw new RuntimeException(e);
        }
    }

    public static ca.spottedleaf.moonrise.patches.chunk_system.scheduling.ChunkTaskScheduler getChunkTaskScheduler(net.minecraft.server.level.ServerLevel level) {
        try {
            return (ca.spottedleaf.moonrise.patches.chunk_system.scheduling.ChunkTaskScheduler) serverLevel_chunkTaskScheduler.get(level);
        } catch (IllegalAccessException e) {
            throw new RuntimeException(e);
        }
    }

    @SuppressWarnings("unchecked")
    public static java.util.List<net.minecraft.world.entity.Entity> getEntities(ca.spottedleaf.moonrise.patches.chunk_system.level.entity.ChunkEntitySlices slices) {
        try {
            return (java.util.List<net.minecraft.world.entity.Entity>) chunkEntitySlices_entities.get(slices);
        } catch (IllegalAccessException e) {
            throw new RuntimeException(e);
        }
    }

    public static void setCommandStorage(net.minecraft.server.MinecraftServer server, net.minecraft.world.level.storage.CommandStorage storage) {
        try {
            minecraftServer_commandStorage.set(server, storage);
        } catch (IllegalAccessException e) {
            throw new RuntimeException(e);
        }
    }

    @SuppressWarnings("unchecked")
    public static <T> com.mojang.serialization.Codec<T> makeBiomeCodec(net.minecraft.core.Registry<?> registry) {
        try {
            return (com.mojang.serialization.Codec<T>) serializableChunkData_makeBiomeCodec.invoke(null, registry);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException(e);
        }
    }

    public static net.minecraft.world.level.chunk.LevelChunk.PostLoadProcessor postLoadChunk(net.minecraft.server.level.ServerLevel level, java.util.List<net.minecraft.nbt.CompoundTag> blockEntityTags, java.util.List<net.minecraft.nbt.CompoundTag> entityTags) {
        try {
            return (net.minecraft.world.level.chunk.LevelChunk.PostLoadProcessor) serializableChunkData_postLoadChunk.invoke(null, level, blockEntityTags, entityTags);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException(e);
        }
    }
}
