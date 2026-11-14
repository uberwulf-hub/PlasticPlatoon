// The sky with drifting clouds (used by scripts/weather.gd).
// coverage: 0 = clear, 1 = overcast. flash: lightning brightening.
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.35, 0.5, 0.8);
uniform vec3 horizon_color : source_color = vec3(0.75, 0.8, 0.85);
uniform vec3 ground_color : source_color = vec3(0.3, 0.3, 0.3);
uniform vec3 cloud_color : source_color = vec3(1.0);
uniform vec3 sun_dir = vec3(0.3, 0.6, 0.3);
uniform float coverage = 0.4;
uniform float drift = 0.0;
uniform float flash = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 x) {
    vec2 i = floor(x); vec2 f = fract(x); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
    float a = 0.5, s = 0.0;
    for (int i = 0; i < 5; i++) { s += a * vnoise(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; }
    return s;
}

void sky() {
    vec3 d = EYEDIR;
    float h = d.y;
    vec3 col = mix(horizon_color, top_color, smoothstep(0.0, 0.55, h));
    if (h < 0.0) {
        col = mix(horizon_color, ground_color, smoothstep(0.0, -0.3, h));
    }
    // A soft sun glow (the clouds cover it).
    float sun = max(dot(d, normalize(sun_dir)), 0.0);
    col += vec3(1.0, 0.9, 0.7) * pow(sun, 64.0) * 0.6;
    if (h > 0.0 && coverage > 0.01) {
        // Project onto a high flat layer: clouds stretch out toward the horizon.
        vec2 uv = d.xz / (h + 0.12) * 1.4 + vec2(drift * 0.012, drift * 0.004);
        float n = fbm(uv);
        float c = smoothstep(1.0 - coverage * 0.95, 1.12 - coverage * 0.6, n + 0.15);
        float shade = mix(0.72, 1.0, smoothstep(0.3, 0.9, fbm(uv * 1.7 + 4.0)));
        c *= smoothstep(0.0, 0.12, h);          // fade into the horizon haze
        col = mix(col, cloud_color * shade, c * 0.95);
    }
    col += vec3(0.75, 0.8, 0.95) * flash * 0.9;
    COLOR = col;
}
