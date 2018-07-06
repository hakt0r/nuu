uniform sampler2D tex0;
uniform sampler2D star_spectrum;
uniform float seed;
uniform float time;
uniform float temperature;
uniform vec3 light;
varying vec3 vNormal;
varying vec2 vTex;


void main(void){
  vec3 l = normalize( light -  vNormal.xyz ) * .2;
  float d = abs(length(vTex-vec2(.5,.5)) * 2.);
  d = d > .5 ? 0. : max(0.,d-1.)*100.;
  float c = d;
  gl_FragColor.rgba = vec4(c,c,c,d);
}
