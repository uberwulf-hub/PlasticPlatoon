// A mark painted on a surface (a small square laid flat on it): bullet holes
// and explosion scorch. Everything is drawn procedurally - no textures.
// kind 0 = bullet hole (chipped crater), 1 = melted pock (plastic), 2 = scorch.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley;

uniform int kind = 0;
uniform float seed = 0.0;
uniform vec3 surface_color : source_color = vec3(0.6);
uniform float fade = 1.0;     // 1 = fresh, fades to 0 before the mark is removed

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 x) {
    vec2 i = floor(x); vec2 f = fract(x); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) { float a = 0.5, s = 0.0; for (int i = 0; i < 4; i++) { s += a * vnoise(p); p *= 2.1; a *= 0.5; } return s; }

void fragment() {
    vec2 p = (UV - 0.5) * 2.0;              // -1..1 across the square
    float ang = atan(p.y, p.x);
    float r = length(p);
    float n = fbm(p * 3.0 + seed * 7.0);
    float jag = fbm(vec2(ang * 2.5, seed * 3.0)) - 0.5;     // ragged rim
    vec3 col = surface_color;
    float a = 0.0;
    float rough = 0.8;
    if (kind == 0) {
        // Chipped crater: dark hole, a pale chipped ring, a faint dust halo.
        float hole = 1.0 - smoothstep(0.16, 0.22, r + jag * 0.08);
        float chip = (1.0 - smoothstep(0.3, 0.46, r + jag * 0.25)) * (1.0 - hole);
        float dust = (1.0 - smoothstep(0.4, 1.0, r + jag * 0.3)) * 0.35;
        col = mix(surface_color * 0.55, surface_color * 1.08, chip);
        col = mix(col, vec3(0.03), hole);
        a = max(max(hole, chip * 0.55), dust * (0.45 + n));
    } else if (kind == 1) {
        // Melted pock: a dark glossy crater with a raised, shiny lip.
        float pit = 1.0 - smoothstep(0.18, 0.3, r + jag * 0.1);
        float lip = smoothstep(0.2, 0.34, r) * (1.0 - smoothstep(0.34, 0.55, r + jag * 0.2));
        col = mix(surface_color * 0.45, surface_color * 0.15, pit);
        col = mix(col, surface_color * 0.8, lip * 0.6);
        a = max(pit, lip * 0.85);
        rough = 0.15;
    } else {
        // Scorch: sooty black centre fading out through brown, ragged edge.
        float burn = 1.0 - smoothstep(0.25, 0.95, r + (n - 0.5) * 0.55 + jag * 0.3);
        col = mix(vec3(0.3, 0.2, 0.1) * surface_color * 1.6, vec3(0.025, 0.022, 0.02), smoothstep(0.2, 0.75, burn));
        a = burn * (0.75 + 0.25 * n);
        rough = 0.95;
    }
    ALBEDO = col;
    ALPHA = clamp(a * fade, 0.0, 1.0);
    ROUGHNESS = rough;
}
