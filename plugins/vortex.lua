math.randomseed(os.time())
local shades = { ".", ":", "-", "=", "+", "*", "#", "%", "@" }

plugin = {
    meta = {
        name = "vortex",
        version = "1.0.0",
        author = "exoad",
        description = "spinny tunnel thang",
    },
    paint = function(ctx)
        local pixels = {}
        local cx = ctx.width * 0.5
        local cy = ctx.height * 0.5
        local t = ctx.time
        for y = 1, ctx.height do
            for x = 1, ctx.width do
                local dx = x - cx
                local dy = y - cy
                local d = math.sqrt(dx * dx + dy * dy)
                local a = math.atan(dy, dx)
                local v = math.sin(d * 0.35 - t * 7 + a * 3)
                local i = math.floor((v + 1) * 0.5 * (#shades - 1) + 1.5)
                if i < 1 then
                    i = 1
                elseif i > #shades then
                    i = #shades
                end
                pixels[#pixels + 1] = {
                    x = x,
                    y = y,
                    ch = shades[i],
                    color = (i > 6) and "96" or ((i > 3) and "36" or "34"),
                }
            end
        end
        return pixels
    end,
}
