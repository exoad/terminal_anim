math.randomseed(os.time())
local bars = {}
local function reset(width)
    bars = {}
    for x = 1, width do
        bars[x] = { h = 1, v = 0 }
    end
end

plugin = {
    meta = {
        name = "equalizer",
        version = "1.0.0",
        author = "exoad",
        description = "fake music bars",
    },
    init = function(ctx)
        reset(ctx.width)
    end,
    paint = function(ctx)
        if #bars ~= ctx.width then
            reset(ctx.width)
        end
        local pixels = {}
        for x = 1, ctx.width do
            local b = bars[x]
            local target = math.floor((math.sin(ctx.time * 2 + x * 0.23) + 1) * 0.5 * (ctx.height * 0.9))
            b.v = b.v * 0.72 + target * 0.28
            b.h = math.max(1, math.floor(b.v + 0.5))
            for y = ctx.height, ctx.height - b.h + 1, -1 do
                if y >= 1 then
                    pixels[#pixels + 1] = {
                        x = x,
                        y = y,
                        ch = "|",
                        color = (y < ctx.height * 0.35) and "91" or ((y < ctx.height * 0.65) and "93" or "92"),
                    }
                end
            end
        end
        return pixels
    end,
}
