package com.infernalsuite.asp.config;

import io.papermc.paper.configuration.Configurations;
import io.papermc.paper.configuration.PaperConfigurations;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.server.MinecraftServer;
import net.minecraft.world.level.GameRules;
import org.galemc.gale.configuration.GaleWorldConfiguration;
import org.spigotmc.SpigotWorldConfig;

import java.nio.file.Path;

public class SlimeGaleWorldConfig {

    private static final ResourceLocation FAKE_WORLD_KEY = ResourceLocation.fromNamespaceAndPath("infernalsuite", "asp-slimeworld");
    public static GaleWorldConfiguration cachedSlimeWorldConfig;

    private SlimeGaleWorldConfig() {}

    public static GaleWorldConfiguration initializeOrGet() {
        if (cachedSlimeWorldConfig != null)
            return cachedSlimeWorldConfig;

        initialize(MinecraftServer.getServer());
        return cachedSlimeWorldConfig;
    }

    private static void initialize(MinecraftServer server) {
        SpigotWorldConfig spigotWorldConfig = new SpigotWorldConfig("asp-slimeworld");

        GameRules gameRules = new GameRules(server.worldLoader.dataConfiguration().enabledFeatures());

        Configurations.ContextMap contextMap = PaperConfigurations.createWorldContextMap(
                Path.of("config", "advancedslimepaper"),
                "asp-slimeworld",
                FAKE_WORLD_KEY,
                spigotWorldConfig,
                server.registryAccess(),
                gameRules
        );
        cachedSlimeWorldConfig = server.galeConfigurations.createWorldConfig(contextMap);
    }
}
