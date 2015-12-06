
varying vec3  vNormal;
varying vec2  vTex;
varying float vElevator;
varying float vNoiser;

uniform float seed;
uniform float time;
uniform float temperature;
uniform vec3 light;

#define PI 3.1415926535897932384626433832795

vec3 random3(vec3 c) {
  float j = seed + 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
  vec3 r;
  r.z = fract(512.0*j);
  j *= .125;
  r.x = fract(512.0*j);
  j *= .125;
  r.y = fract(512.0*j);
  return r-0.5; }

const float F3 =  0.3333333;
const float G3 =  0.1666667;
float snoise(vec3 p) {
  vec3 s = floor(p + dot(p, vec3(F3)));
  vec3 x = p - s + dot(s, vec3(G3));
  vec3 e = step(vec3(0.0), x - x.yzx);
  vec3 i1 = e*(1.0 - e.zxy);
  vec3 i2 = 1.0 - e.zxy*(1.0 - e);
  vec3 x1 = x - i1 + G3;
  vec3 x2 = x - i2 + 2.0*G3;
  vec3 x3 = x - 1.0 + 3.0*G3;
  vec4 w, d;
  w.x = dot(x, x);
  w.y = dot(x1, x1);
  w.z = dot(x2, x2);
  w.w = dot(x3, x3);
  w = max(0.6 - w, 0.0);
  d.x = dot(random3(s), x);
  d.y = dot(random3(s + i1), x1);
  d.z = dot(random3(s + i2), x2);
  d.w = dot(random3(s + 1.0), x3);
  w *= w;
  w *= w;
  d *= w;
  return dot(d, vec4(52.0)); }

float shading(vec3 position){
  vec3 l = normalize(light);
  return max(0.015, dot(position, l)); }

float fnoise(vec3 position, const int octaves, float frequency, float persistence) {
   float total = 0.0;
   float maxAmplitude = 0.0;
   float amplitude = 1.0;
   total += snoise(position * frequency) * amplitude;
   frequency *= 2.0;
   maxAmplitude += amplitude;
   amplitude *= persistence;
   total += snoise(position * frequency) * amplitude;
   frequency *= 2.0;
   maxAmplitude += amplitude;
   amplitude *= persistence;
   total += snoise(position * frequency) * amplitude;
   frequency *= 2.0;
   maxAmplitude += amplitude;
   amplitude *= persistence;
   total += snoise(position * frequency) * amplitude;
   frequency *= 2.0;
   maxAmplitude += amplitude;
   amplitude *= persistence;
   total += snoise(position * frequency) * amplitude;
   frequency *= 2.0;
   maxAmplitude += amplitude;
   amplitude *= persistence;
   total += snoise(position * frequency) * amplitude;
   frequency *= 2.0;
   maxAmplitude += amplitude;
   amplitude *= persistence;
   return total / maxAmplitude; }

void main() {
  vNormal = normal;
  vTex    = uv;
  vElevator = max(
    fnoise(vNormal.xyz, 6,  0.1, 0.8),
    fnoise(vNormal.zyx, 5, -0.1, 0.79));
  vNoiser = fnoise(vNormal.xzy, 6,  0.1, 0.66);
  gl_Position = projectionMatrix * modelViewMatrix *
    vec4(position, 1.0) +
    vec4(vElevator*.3,.0,.0,.1); }
