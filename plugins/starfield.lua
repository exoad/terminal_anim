math.randomseed(os.time())
local stars = {}
local last_w = 0
local last_h = 0
local function spawn_star(width, height)
    return {
        x = math.random() * width,
        y = math.random() * height,
        z = math.random() * 1.0 + 0.1,
    }
end
local function reset_stars(width, height)
    stars = {}
    local count = math.max(80, math.floor((width * height) / 9))
    for i = 1, count do
        stars[i] = spawn_star(width, height)
    end
    last_w = width
    last_h = height
end

plugin = {
    meta = {
        name = "starfield",
        version = "1.0.0",
        author = "exoad",
        description = "its in the name",
    },
    init = function(ctx)
        reset_stars(ctx.width, ctx.height)
    end,
    paint = function(ctx)
        if #stars == 0 or ctx.width ~= last_w or ctx.height ~= last_h then
            reset_stars(ctx.width, ctx.height)
        end
        local pixels = {}
        local cx = ctx.width * 0.5
        local cy = ctx.height * 0.5
        for i = 1, #stars do
            local s = stars[i]
            s.z = s.z - 0.018
            if s.z <= 0.02 then
                stars[i] = spawn_star(ctx.width, ctx.height)
                s = stars[i]
            end
            local sx = math.floor(((s.x - cx) / s.z) + cx + 0.5)
            local sy = math.floor(((s.y - cy) / s.z) + cy + 0.5)
            if sx < 1 or sx > ctx.width or sy < 1 or sy > ctx.height then
                stars[i] = spawn_star(ctx.width, ctx.height)
                s = stars[i]
                sx = math.floor(((s.x - cx) / s.z) + cx + 0.5)
                sy = math.floor(((s.y - cy) / s.z) + cy + 0.5)
            end
            local ch = "."
            local color = "90"
            if s.z < 0.45 then
                ch = "+"
                color = "37"
            end
            if s.z < 0.22 then
                ch = "*"
                color = "97"
            end
            pixels[#pixels + 1] = {
                x = sx,
                y = sy,
                ch = ch,
                color = color,
            }
        end
        return pixels
    end,
}
