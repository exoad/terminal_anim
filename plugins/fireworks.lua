math.randomseed(os.time())
local bursts = {}
local palette = {
    "91",
    "93",
    "95",
    "96",
    "92",
    "94",
    "31",
    "33",
    "36",
}
local function rnd(min, max)
    return min + math.random() * (max - min)
end
local function spawn_burst(width, height)
    local count = math.random(18, 36)
    local particles = {}
    local origin_x = rnd(width * 0.2, width * 0.8)
    local origin_y = rnd(height * 0.2, height * 0.65)
    local color = palette[math.random(1, #palette)]
    for i = 1, count do
        local a = rnd(0, math.pi * 2)
        local speed = rnd(0.8, 2.2)
        particles[i] = {
            x = origin_x,
            y = origin_y,
            vx = math.cos(a) * speed,
            vy = math.sin(a) * speed,
            life = rnd(0.8, 1.8),
            ttl = rnd(0.8, 1.8),
            glyph = (math.random() > 0.5) and "*" or "+",
        }
    end
    bursts[#bursts + 1] = {
        color = color,
        particles = particles,
    }
end

plugin = {
    meta = {
        name = "fireworks",
        version = "69.69.69",
        author = "exoad",
        description = "cool radial spark bursts with gravity and fadeout",
    },
    init = function(ctx)
        bursts = {}
        for _ = 1, 3 do
            spawn_burst(ctx.width, ctx.height)
        end
    end,
    paint = function(ctx)
        local dt = 1 / 30
        local gravity = 0.07
        if math.random() > 0.9 and #bursts < 7 then
            spawn_burst(ctx.width, ctx.height)
        end
        local pixels = {}
        local alive_bursts = {}
        for _, burst in ipairs(bursts) do
            local alive_particles = {}
            for _, p in ipairs(burst.particles) do
                p.life = p.life - dt
                if p.life > 0 then
                    p.x = p.x + p.vx
                    p.y = p.y + p.vy
                    p.vy = p.vy + gravity
                    p.vx = p.vx * 0.995
                    if p.x >= 1 and p.x <= ctx.width and p.y >= 1 and p.y <= ctx.height then
                        local fade = p.life / p.ttl
                        local color = burst.color
                        local ch = p.glyph
                        if fade < 0.5 then
                            ch = "."
                        end
                        if fade < 0.25 then
                            color = "37"
                        end
                        pixels[#pixels + 1] = {
                            x = math.floor(p.x + 0.5),
                            y = math.floor(p.y + 0.5),
                            ch = ch,
                            color = color,
                        }
                    end
                    alive_particles[#alive_particles + 1] = p
                end
            end
            if #alive_particles > 0 then
                burst.particles = alive_particles
                alive_bursts[#alive_bursts + 1] = burst
            end
        end
        bursts = alive_bursts
        if #bursts == 0 then
            spawn_burst(ctx.width, ctx.height)
        end
        return pixels
    end,
}
