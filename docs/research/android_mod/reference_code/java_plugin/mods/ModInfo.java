package com.bluerebirth.mods;

import java.io.File;

public final class ModInfo {
    public String id;
    public String name;
    public String version;
    public String description;
    public String author;
    public String entry = "main.lua";
    public int loadOrder = 100;
    public String clientVersion;
    public boolean enabled = true;
    public File dir;

    public String displayName() {
        if (name != null && name.length() > 0) return name;
        return id;
    }
}
