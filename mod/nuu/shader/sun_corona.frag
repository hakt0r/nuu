
uniform sampler2D star_spectrum;
uniform float seed;
uniform vec4 temperature;
uniform float time;
uniform vec3 light;

varying vec3 vNormal;
varying vec2 vTex;

void main(void){
  vec3 color = temperature.rgb;
  float d = length(vTex-vec2(.5,.5)) * 4.0;
  float b = (1.0 / (d * d) - 0.1) * .7;
  float c = 1.-min(1.,d);
  d = max(.5,d-.3);
  gl_FragColor = vec4(color,1.) * vec4(c,c,c,d);
}
