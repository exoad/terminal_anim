math.randomseed(os.time())
local shades = { ".", ":", "-", "=", "+", "*", "#", "%", "@" }
local colors = { "34", "36", "96", "94", "95", "35" }
local function shade_for(v)
    local t = (v + 1) * 0.5
    local idx = math.floor(t * (#shades - 1) + 1.5)
    if idx < 1 then
        idx = 1
    elseif idx > #shades then
        idx = #shades
    end
    return shades[idx]
end
local function color_for(v)
    local t = (v + 1) * 0.5
    local idx = math.floor(t * (#colors - 1) + 1.5)
    if idx < 1 then
        idx = 1
    elseif idx > #colors then
        idx = #colors
    end
    return colors[idx]
end

plugin = {
    meta = {
        name = "plasma_wave",
        version = "69.69.69",
        author = "exoad",
        description = "flowing sine wave",
        fps = 30,
    },
    paint = function(ctx)
        local pixels = {}
        local t = ctx.time
        for y = 1, ctx.height do
            local ny = y / math.max(1, ctx.height)
            for x = 1, ctx.width do
                local nx = x / math.max(1, ctx.width)
                local v = math.sin(nx * 12 + t * 1.7)
                    + math.cos(ny * 9 - t * 1.2)
                    + math.sin((nx + ny) * 10 + t * 0.8)
                v = v / 3
                pixels[#pixels + 1] = {
                    x = x,
                    y = y,
                    ch = shade_for(v),
                    color = color_for(v),
                }
            end
        end
        return pixels
    end,
}
