export default /* glsl */`
#ifdef USE_MAP
    vec4 texelColor = texture2D( map, vUv );
	texelColor = mapTexelToLinear( texelColor );
	diffuseColor.r *= texelColor.r * maskR;
	diffuseColor.g *= texelColor.g * maskG;
	diffuseColor.b *= texelColor.b * maskB;
#endif
`;