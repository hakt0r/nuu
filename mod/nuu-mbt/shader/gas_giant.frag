uniform sampler2D tex0;
uniform sampler2D star_spectrum;
uniform float seed;
uniform float time;
uniform float temperature;
uniform vec3 light;
varying vec3 vNormal;
varying vec2 vTex;

#define PI 3.1415926535897932384626433832795

vec3 random3(vec3 c) {
	float j = seed + 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}

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

float snoise(vec3 uv, float res){
  const vec3 s = vec3(1e0, 1e2, 1e4);
  uv *= res;
  vec3 uv0 = floor(mod(uv, res))*s;
  vec3 uv1 = floor(mod(uv+vec3(1.), res))*s;
  vec3 f = fract(uv); f = f*f*(3.0-2.0*f);
  vec4 v = vec4(uv0.x+uv0.y+uv0.z, uv1.x+uv0.y+uv0.z, uv0.x+uv1.y+uv0.z, uv1.x+uv1.y+uv0.z);
  vec4 r = fract(sin(v*1e-3)*1e5);
  float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
  r = fract(sin((v + uv1.z - uv0.z)*1e-3)*1e5);
  float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
  return mix(r0, r1, f.z)*2.-1.; }

float snoiseFractal(vec3 m) {
  return 0.5333333 *
    snoise(m,2.) +
    0.2666667 * snoise(2.0*m,2.) +
    0.1333333 * snoise(4.0*m,2.) +
    0.0666667 * snoise(8.0*m,2.); }

float freqs[4];

vec4 baseColor(){
  float u = (temperature - 800.0) / 29200.0;
  return texture2D(star_spectrum, vec2(u,0)); }

float shading(vec3 position){
  vec3 l = normalize(light);
  return max(0.015, dot(position, l)); }

vec4 fineNoise(vec2 p){
  float xx = snoise(vec3(p*4.,0.), 100.);
  float yy = snoise(vec3(p*4.,0.), 100.);
  float zz = snoise(vec3(p*4.,0.), 100.);
  float x = xx + snoise(vec3(p*20.,10.), 64.);
  float y = yy + snoise(vec3(p*20.,10.), 64.);
  float z = zz + snoise(vec3(p*20.,10.), 64.);
  return vec4(x,x,x,time); }

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

float rnoise(vec3 position, const int octaves, float frequency, float persistence) {
  float total = 0.0;
  float maxAmplitude = 0.0;
  float amplitude = 1.0;
  total += ((1.0 - abs(snoise(position * frequency))) * 2.0 - 1.0) * amplitude;
  frequency *= 2.0;
  maxAmplitude += amplitude;
  amplitude *= persistence;
  total += ((1.0 - abs(snoise(position * frequency))) * 2.0 - 1.0) * amplitude;
  frequency *= 2.0;
  maxAmplitude += amplitude;
  amplitude *= persistence;
  total += ((1.0 - abs(snoise(position * frequency))) * 2.0 - 1.0) * amplitude;
  frequency *= 2.0;
  maxAmplitude += amplitude;
  amplitude *= persistence;
  total += ((1.0 - abs(snoise(position * frequency))) * 2.0 - 1.0) * amplitude;
  frequency *= 2.0;
  maxAmplitude += amplitude;
  amplitude *= persistence;
  total += ((1.0 - abs(snoise(position * frequency))) * 2.0 - 1.0) * amplitude;
  frequency *= 2.0;
  maxAmplitude += amplitude;
  amplitude *= persistence;
  return total / maxAmplitude; }

float u_k = .1;
vec4 plasma(vec2 p){
  float t = time / 10.;
  float v = 0.0;
  vec2 c = vec2(p.y,0.) * u_k - u_k/2.0;
  v += sin((c.x+t));
  v += sin((c.y+t)/2.0);
  v += sin((c.x+c.y+t)/2.0);
  c += u_k/2.0 * vec2(sin(t/3.0), cos(t/2.0));
  v += sin(sqrt(c.x*c.x+c.y*c.y+1.0)+t);
  v = v/2.0;
  vec3 col = vec3(1, sin(PI*v), cos(PI*v));
  return vec4(col, 1); }

float computeDiffuse(vec3 normal) {
    return dot( normal, vec3(1.) ); }

vec4 colorAt(vec2 p){
  return plasma(p * 100.) * .5 + plasma(p * 1000.); }

void main() {
  vec2 p = vTex;
  float n1 = fnoise(vNormal.xyz, 6, 0.1, 0.8) * 0.01;
  float n2 = rnoise(vNormal.xyz, 5, 5.8, 0.75) * 0.015 - 0.01;

  // c = vec4(.1);
  float s = 0.6;
  float t1 = snoise( vNormal.xyz * 2.0   ) - s;
  float t2 = snoise((vNormal.xyz + 800.0 ) * 2.0) - s;
  float t3 = snoise((vNormal.xyz + 1600.0) * 2.0) - s;
  float threshold = max(t1 * t2 * t3, 0.0);
  float n3 = sin( snoise(vNormal.xyz * 0.2) ) * threshold;
  p.y += n1 * 3. + n2 * 1. + n3;

  vec4 c = colorAt(p);
  // c += vec4(threshold * 3.0, 0.0, 0.0, 0.0);
  gl_FragColor = vec4( c.xyz * shading(vNormal.xyz), 1.);}
