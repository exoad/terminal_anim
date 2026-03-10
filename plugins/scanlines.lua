math.randomseed(os.time())
local chars = {"-", "=", "~", "."}
local function pick()
    return chars[math.random(1, #chars)]
end

plugin = {
    meta = {
        name = "scanlines",
        version = "1.0.0",
        author = "exoad",
        description = "old screen vibes",
    },
    paint = function(ctx)
        local pixels = {}
        local sweep = (math.floor(ctx.time * 18) % math.max(1, ctx.height)) + 1
        for y = 1, ctx.height do
            local color = "90"
            if y % 2 == 0 then
                color = "2;100;100;100"
            end
            if math.abs(y - sweep) <= 1 then
                color = "97"
            end
            for x = 1, ctx.width do
                pixels[#pixels + 1] = {
                    x = x,
                    y = y,
                    ch = pick(),
                    color = color,
                }
            end
        end
        return pixels
    end,
}
