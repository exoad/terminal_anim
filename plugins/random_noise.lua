math.randomseed(os.time())
local glyphs = { " ", ".", ":", "*", "+", "#", "%", "@" }
local colors = { "90", "37", "97", "32", "92", "36", "96", "35", "95" }
local function pick(list)
    return list[math.random(1, #list)]
end

plugin = {
    meta = {
        name = "random_noise",
        version = "1.0.0",
        author = "exoad",
        description = "random noise",
    },
    paint = function(ctx)
        local pixels = {}
        for y = 1, ctx.height do
            for x = 1, ctx.width do
                pixels[#pixels + 1] = {
                    x = x,
                    y = y,
                    ch = pick(glyphs),
                    color = pick(colors),
                }
            end
        end
        return pixels
    end,
}
