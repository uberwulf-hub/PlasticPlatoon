// Damage drawn INTO the soldier's plastic (an overlay pass on the same mesh,
// so it always follows the body - nothing is stuck on top).
// style 0 = stress whitening, 1 = scorch, 2 = melt.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx;

uniform int style = 0;
uniform vec3 base_color : source_color = vec3(0.27, 0.48, 0.17);
uniform vec4 hits[8];          // xyz = hit point (world), w = size
uniform int hit_count = 0;
uniform float wear = 0.0;      // 0..1 overall damage

varying vec3 wpos;
varying vec3 wnrm;

float hash(vec3 p) {
    p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float vnoise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i + vec3(0,0,0)), hash(i + vec3(1,0,0)), f.x),
                   mix(hash(i + vec3(0,1,0)), hash(i + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash(i + vec3(0,0,1)), hash(i + vec3(1,0,1)), f.x),
                   mix(hash(i + vec3(0,1,1)), hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}
float fbm(vec3 p) {
    float a = 0.5, s = 0.0;
    for (int i = 0; i < 4; i++) { s += a * vnoise(p); p *= 2.03; a *= 0.5; }
    return s;
}

void vertex() {
    wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    // How damaged this spot is: near a hit, with a ragged noisy edge.
    float m = 0.0;
    float edge = 0.0;
    for (int i = 0; i < 8; i++) {
        if (i >= hit_count) break;
        vec3 d = wpos - hits[i].xyz;
        float r = hits[i].w;
        if (style == 2 && d.y < 0.0) d.y *= 0.45;         // melt runs downhill
        float dist = length(d) + (fbm(wpos * 9.0 + float(i)) - 0.5) * r * 0.9;
        float s = 1.0 - smoothstep(r * 0.45, r, dist);
        m = max(m, s);
        edge = max(edge, s * (1.0 - s) * 4.0);
    }
    // Overall wear adds faint scattered patches everywhere.
    m = max(m, wear * 0.6 * smoothstep(0.58, 0.72, fbm(wpos * 4.0 + 7.0)));

    vec3 col = base_color;
    float a = 0.0;
    float rough = 0.4;
    float spec = 0.5;
    if (style == 0) {
        // Stress whitening: pale, chalky plastic with crease lines.
        float crease = 1.0 - smoothstep(0.0, 0.05, abs(fbm(wpos * 16.0) - 0.5));
        vec3 pale = mix(base_color, vec3(0.86, 0.9, 0.8), 0.7);
        col = pale;
        a = m * (0.45 + 0.55 * crease);
        rough = 0.85;
        spec = 0.2;
    } else if (style == 1) {
        // Scorch: sooty black centre, brown singed rim.
        float soot = fbm(wpos * 12.0);
        col = mix(vec3(0.33, 0.22, 0.1), vec3(0.03, 0.028, 0.025), smoothstep(0.25, 0.85, m));
        a = m * (0.7 + 0.3 * soot);
        rough = 0.95;
        spec = 0.1;
    } else {
        // Melt: deeper, glossy, wet-looking plastic with darker runs.
        col = mix(base_color * 0.42, base_color * 0.2, edge);
        a = m * 0.92;
        rough = 0.02;
        spec = 1.0;
    }
    ALBEDO = col;
    ALPHA = clamp(a, 0.0, 1.0);
    ROUGHNESS = rough;
    SPECULAR = spec;
}
