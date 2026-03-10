math.randomseed(os.time())
local verts = {
    { -1, -1, -1 },
    { 1,  -1, -1 },
    { 1,  1,  -1 },
    { -1, 1,  -1 },
    { -1, -1, 1 },
    { 1,  -1, 1 },
    { 1,  1,  1 },
    { -1, 1,  1 },
}
local edges = {
    { 1, 2 },
    { 2, 3 },
    { 3, 4 },
    { 4, 1 },
    { 5, 6 },
    { 6, 7 },
    { 7, 8 },
    { 8, 5 },
    { 1, 5 },
    { 2, 6 },
    { 3, 7 },
    { 4, 8 },
}

local function project(v, ax, ay, az, scale, cx, cy)
    local sx = math.sin(ax)
    local cxr = math.cos(ax)
    local sy = math.sin(ay)
    -- not sure?
    local cyr = math.cos(ay)
    local sz = math.sin(az)
    local czr = math.cos(az)
    local y1 = v[2] * cxr - v[3] * sx
    local z1 = v[2] * sx + v[3] * cxr
    local x2 = v[1] * cyr + z1 * sy
    local z2 = -v[1] * sy + z1 * cyr
    local f = scale / (z2 + 4)
    return math.floor(cx + (x2 * czr - y1 * sz) * f + 0.5), math.floor(cy + (x2 * sz + y1 * czr) * f + 0.5)
end

local function line(x1, y1, x2, y2, color, out, w, h)
    local dx = math.abs(x2 - x1)
    local sx = (x1 < x2) and 1 or -1
    local dy = -math.abs(y2 - y1)
    local sy = (y1 < y2) and 1 or -1
    local err = dx + dy
    while true do
        if x1 >= 1 and x1 <= w and y1 >= 1 and y1 <= h then
            out[#out + 1] = { x = x1, y = y1, ch = "#", color = color }
        end
        if x1 == x2 and y1 == y2 then -- LMAO
            break
        end
        local e2 = 2 * err
        if e2 >= dy then
            err = err + dy
            x1 = x1 + sx
        end
        if e2 <= dx then
            err = err + dx
            y1 = y1 + sy
        end
    end
end

plugin = {
    meta = {
        name = "cube_3d",
        version = "1.0.0",
        author = "exoad",
        description = "spinning cube thing",
    },
    paint = function(ctx)
        local pixels = {}
        local pts = {}
        for i = 1, #verts do
            pts[i] = {
                project(
                    verts[i],
                    ctx.time * 0.9,
                    ctx.time * 1.1,
                    ctx.time * 0.5,
                    math.max(6, math.min(ctx.width, ctx.height) * 1.8),
                    ctx.width * 0.5,
                    ctx.height * 0.5
                ),
            }
        end
        for i = 1, #edges do
            line(
                pts[edges[i][1]][1],
                pts[edges[i][1]][2],
                pts[edges[i][2]][1],
                pts[edges[i][2]][2],
                (i <= 8) and "96" or "36", -- didnt know lua was chill like this
                pixels,
                ctx.width,
                ctx.height
            )
        end
        return pixels
    end,
}
