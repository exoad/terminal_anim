math.randomseed(os.time())
local blips = {}
local function reset_blips(width, height)
    blips = {}
    local count = math.max(8, math.floor((width * height) / 180))
    for i = 1, count do
        blips[i] = {
            x = math.random(2, math.max(2, width - 1)),
            y = math.random(2, math.max(2, height - 1)),
            twinkle = math.random(),
        }
    end
end
plugin = {
    meta = {
        name = "radar_sweep",
        version = "1.0.0",
        author = "exoad",
        description = "radar",
    },
    init = function(ctx)
        reset_blips(ctx.width, ctx.height)
    end,
    paint = function(ctx)
        if #blips == 0 then
            reset_blips(ctx.width, ctx.height)
        end
        local pixels = {}
        local cx = math.floor(ctx.width * 0.5)
        local cy = math.floor(ctx.height * 0.5)
        local r = math.floor(math.min(ctx.width, ctx.height) * 0.42)
        local sweep = ctx.time * 1.8
        for y = 1, ctx.height do
            for x = 1, ctx.width do
                local dx = x - cx
                local dy = y - cy
                local d = math.sqrt(dx * dx + dy * dy)
                if d <= r then
                    local ch = " "
                    local color = "2;0;70;0"
                    if math.abs(d - r) < 0.7 then
                        ch = "."
                        color = "32"
                    elseif math.abs(d - r * 0.66) < 0.7 or math.abs(d - r * 0.33) < 0.7 then
                        ch = "."
                        color = "2;0;90;0"
                    end
                    local a = math.atan(dy, dx)
                    local diff = math.abs(math.atan(math.sin(a - sweep), math.cos(a - sweep)))
                    if diff < 0.06 and d <= r then
                        ch = "/"
                        color = "92"
                    elseif diff < 0.16 and d <= r then
                        ch = "."
                        color = "32"
                    end
                    pixels[#pixels + 1] = { x = x, y = y, ch = ch, color = color }
                end
            end
        end
        for _, b in ipairs(blips) do
            local dx = b.x - cx
            local dy = b.y - cy
            local d = math.sqrt(dx * dx + dy * dy)
            if d <= r then
                local a = math.atan(dy, dx)
                local diff = math.abs(math.atan(math.sin(a - sweep), math.cos(a - sweep)))
                local phase = (ctx.time * 4 + b.twinkle * 6.28)
                if diff < 0.15 then
                    pixels[#pixels + 1] = { x = b.x, y = b.y, ch = "*", color = "97" }
                elseif (math.sin(phase) + 0) * 0.5 > 0.85 then
                    pixels[#pixels + 1] = { x = b.x, y = b.y, ch = ".", color = "92" }
                end
            end
        end
        return pixels
    end,
}
