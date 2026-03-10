math.randomseed(os.time())
local ramp = { " ", ".", ":", "~", "=" }
local function clamp(v, a, b)
    if v < a then
        return a
    elseif v > b then
        return b
    end
    return v
end

plugin = {
    meta = {
        name = "bottom_mist",
        version = "1.0.0",
        author = "exoad",
        description = "low fog at bottom",
    },
    paint = function(ctx)
        local pixels = {}
        local h = math.max(3, math.floor(ctx.height * 0.3))
        local y0 = ctx.height - h + 1
        for y = y0, ctx.height do
            local ny = (y - y0) / math.max(1, h - 1)
            local fade = ny ^ 1.6
            for x = 1, ctx.width do
                local n = 0
                n = n + math.sin(x * 0.10 + ctx.time * 0.8)
                n = n + math.sin(x * 0.05 - ctx.time * 0.5 + y * 0.12)
                n = n + math.cos(x * 0.03 + ctx.time * 0.35)
                n = n / 3
                local d = clamp((n + 1) * 0.5 * fade, 0, 1)
                local i = clamp(math.floor(d * (#ramp - 1) + 1.2), 1, #ramp)
                if i > 1 then
                    pixels[#pixels + 1] = {
                        x = x,
                        y = y,
                        ch = ramp[i],
                        color = (d > 0.65) and "37" or "90",
                    }
                end
            end
        end
        return pixels
    end,
}
