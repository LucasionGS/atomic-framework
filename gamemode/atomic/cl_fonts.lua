AddCSLuaFile()

local baseFont = {
    font = "Roboto-Black",
    size = 16,
    weight = 500,
    antialias = true,
    shadow = false,
    italic = false
}

local function Font(data) return table.Merge(table.Copy(baseFont), data) end

surface.CreateFont("AtomicNormal", Font({}))
surface.CreateFont("AtomicNormalItalics", Font({ font = "AtomicNormal", italic = true }))
surface.CreateFont("AtomicNormalBold", Font({ font = "AtomicNormal", weight = 700 }))
surface.CreateFont("AtomicNormalBoldItalics", Font({ font = "AtomicNormal", weight = 700, italic = true }))

surface.CreateFont("AtomicLarge", Font({ font = "AtomicNormal", size = 32 }))
surface.CreateFont("AtomicLargeItalics", Font({ font = "AtomicLarge", italic = true }))
surface.CreateFont("AtomicLargeBold", Font({ font = "AtomicLarge", weight = 700 }))
surface.CreateFont("AtomicLargeBoldItalics", Font({ font = "AtomicLarge", weight = 700, italic = true }))

surface.CreateFont("AtomicHud", Font({ font = "AtomicNormal", size = 24 }))