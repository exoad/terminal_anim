math.randomseed(os.time())
local points = {}
local function reset(width, height)
    points = {}
    for i = 1, 4 do
        points[i] = {
            x = math.random(1, width),
            y = math.random(1, height),
            s = math.random() * 0.8 + 0.6,
        }
    end
end

plugin = {
    meta = {
        name = "ripples",
        version = "1.0.0",
        author = "exoad",
        description = "water rings??",
    },
    init = function(ctx)
        reset(ctx.width, ctx.height)
    end,
    paint = function(ctx)
        if #points == 0 then
            reset(ctx.width, ctx.height)
        end
        local pixels = {}
        for y = 1, ctx.height do
            for x = 1, ctx.width do
                local v = 0
                for i = 1, #points do
                    local p = points[i]
                    local dx = x - p.x
                    local dy = y - p.y
                    v = v + math.sin(math.sqrt(dx * dx + dy * dy) * 0.7 - ctx.time * 5 * p.s)
                end
                v = v / #points
                local ch = "."
                local color = "34"
                if v > 0.55 then
                    ch = "@"
                    color = "96"
                elseif v > 0.2 then
                    ch = "*"
                    color = "36"
                elseif v > -0.1 then
                    ch = ":"
                    color = "94"
                end
                pixels[#pixels + 1] = { x = x, y = y, ch = ch, color = color }
            end
        end
        return pixels
    end,
}
