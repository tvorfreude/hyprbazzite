-- Internal ONEXPLAYER / Laptop Displays
hl.monitor({ 
    output = "desc:Thermotrex Corporation TL134ADXP01-0", 
    mode = "2560x1600@165.0", 
    position = "auto", 
    scale = 1.6 
})

hl.monitor({ 
    output = "desc:Samsung Display Corp. ATNA40HQ01-0", 
    mode = "2880x1800@120.0", 
    position = "auto", 
    scale = 1.6 
})

-- External Gigabyte M27F (Right side, HDR, VRR)
hl.monitor({ 
    output = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. M27F A 23073B000294", 
    mode = "1920x1080@164.92", 
    position = "auto-right", 
    scale = 1, 
    vrr = 2,
    cm = "auto",
    sdrbrightness = 2.4,
    sdrsaturation = 1.02,
    max_luminance = 400,
    max_avg_luminance = 300,
    sdr_max_luminance = 150
})

-- External Gigabyte M27U (Left side, 4K, 10-bit, HDR, VRR)
hl.monitor({ 
    output = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. M27U 23433B000697", 
    mode = "3840x2160@120.0", 
    position = "auto-left", 
    scale = 1.875, 
    vrr = 2,
    cm = "auto",
    sdrbrightness = 2.8,
    sdrsaturation = 1.05,
    max_luminance = 600,
    max_avg_luminance = 400,
    sdr_max_luminance = 180
})

-- External LG (Above)
hl.monitor({ 
    output = "desc:LG Electronics LG FULL HD 0x01010101", 
    mode = "1920x1080@75.0", 
    position = "auto-up", 
    scale = 1.0 
})

-- External Samsung 4K (Above)
hl.monitor({ 
    output = "desc:Samsung Electric Company U28H75x HTPK700191", 
    mode = "3840x2160@60.0", 
    position = "auto-up", 
    scale = 1.5 
})

-- Fallback rule for any other display
hl.monitor({ 
    output = "", 
    mode = "preferred", 
    position = "auto", 
    scale = 1 
})
