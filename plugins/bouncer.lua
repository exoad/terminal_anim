math.randomseed(os.time())
local x = 1
local y = 1
local vx = 1
local vy = 1

plugin = {
    meta = {
        name = "bouncer",
        version = "1.0.0",
        author = "exoad",
        description = "ball goes boing",
    },
    init = function(ctx)
        x = math.floor(ctx.width * 0.5)
        y = math.floor(ctx.height * 0.5)
        vx = (math.random() > 0.5) and 1 or -1
        vy = (math.random() > 0.5) and 1 or -1
    end,
    paint = function(ctx)
        x = x + vx
        y = y + vy
        if x <= 1 then
            x = 1
            vx = 1
        elseif x >= ctx.width then
            x = ctx.width
            vx = -1
        end
        if y <= 1 then
            y = 1
            vy = 1
        elseif y >= ctx.height then
            y = ctx.height
            vy = -1
        end
        local pixels = {}
        local tail = 7
        for i = 1, tail do
            local tx = x - vx * i
            local ty = y - vy * i
            if tx >= 1 and tx <= ctx.width and ty >= 1 and ty <= ctx.height then
                pixels[#pixels + 1] = {
                    x = tx,
                    y = ty,
                    ch = ".",
                    color = "36",
                }
            end
        end
        pixels[#pixels + 1] = {
            x = x,
            y = y,
            ch = "@",
            color = "93",
        }
        return pixels
    end,
}
