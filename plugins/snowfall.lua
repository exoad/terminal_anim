math.randomseed(os.time())
local flakes = {}
local function reset(width, height)
    flakes = {}
    local count = math.max(25, math.floor((width * height) / 30))
    for i = 1, count do
        flakes[i] = {
            x = math.random(1, width),
            y = math.random(1, height),
            speed = math.random() * 0.9 + 0.2,
            drift = math.random() * 0.8 - 0.4,
            glyph = (math.random() > 0.7) and "*" or ".",
        }
    end
end

plugin = {
    meta = {
        name = "snowfall",
        version = "1.0.0",
        author = "exoad",
        description = "just some snow lol",
    },
    init = function(ctx)
        reset(ctx.width, ctx.height)
    end,
    paint = function(ctx)
        if #flakes == 0 then
            reset(ctx.width, ctx.height)
        end
        local pixels = {}
        for i = 1, #flakes do
            local f = flakes[i]
            f.y = f.y + f.speed
            f.x = f.x + math.sin(ctx.time * 1.7 + i * 0.13) * 0.15 + f.drift * 0.05
            if f.y > ctx.height then
                f.y = 1
                f.x = math.random(1, ctx.width)
            end
            if f.x < 1 then
                f.x = ctx.width
            elseif f.x > ctx.width then
                f.x = 1
            end
            pixels[#pixels + 1] = {
                x = math.floor(f.x + 0.5),
                y = math.floor(f.y + 0.5),
                ch = f.glyph,
                color = (f.glyph == "*") and "97" or "37",
            }
        end
        return pixels
    end,
}
