export default /* glsl */`
#ifdef USE_MAP
    vec4 texelColor = texture2D( map, vUv );
	texelColor = mapTexelToLinear( texelColor );
	float lum = texelColor.r + texelColor.g + texelColor.b;
	diffuseColor.rgb *= (texelColor.r * maskR + texelColor.g * maskG + texelColor.b * maskB) / lum;
#endif
`;