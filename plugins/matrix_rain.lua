math.randomseed(os.time())
local columns = {}
local glyphs = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@#$%&*"
local function random_glyph()
    local index = math.random(1, #glyphs)
    return glyphs:sub(index, index)
end
local function ensure_columns(width, height)
    if #columns == width then
        return
    end
    columns = {}
    for x = 1, width do
        columns[x] = {
            head = math.random(-height, height),
            speed = math.random(1, 3),
            tail = math.random(6, 18),
            tick = 0,
        }
    end
end

plugin = {
    meta = {
        name = "matrix_rain",
        version = "1.0.0",
        author = "exoad",
        description = "cool matrix",
    },
    init = function(ctx)
        ensure_columns(ctx.width, ctx.height)
    end,
    paint = function(ctx)
        ensure_columns(ctx.width, ctx.height)
        local pixels = {}
        for x = 1, ctx.width do
            local col = columns[x]
            col.tick = col.tick + 1
            if col.tick >= col.speed then
                col.tick = 0
                col.head = col.head + 1
                if col.head - col.tail > ctx.height then
                    col.head = math.random(-ctx.height, 0)
                    col.tail = math.random(6, 18)
                    col.speed = math.random(1, 3)
                end
            end
            for i = 0, col.tail do
                local y = col.head - i
                if y >= 1 and y <= ctx.height then
                    local color = "32"
                    local ch = random_glyph()
                    if i == 0 then
                        color = "97"
                    elseif i < 3 then
                        color = "92"
                    elseif i > math.floor(col.tail * 0.7) then
                        color = "2;0;100;0"
                        ch = "."
                    end
                    pixels[#pixels + 1] = {
                        x = x,
                        y = y,
                        ch = ch,
                        color = color,
                    }
                end
            end
        end
        return pixels
    end
}
