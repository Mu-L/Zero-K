#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shader_storage_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

// Shader licensed under GNU GPL, v2 or later. Relicensed from MIT, preserving the notice "(c) Beherith (mysterme@gmail.com)".

#line 5000

layout (location = 0) in vec4 lengthwidthcornerheight;
layout (location = 1) in uint teamID;
layout (location = 2) in uint numvertices;
layout (location = 3) in vec4 parameters; // time start, animate, unused, unused
layout (location = 4) in vec4 uvoffsets; // this is optional, for using an Atlas
layout (location = 5) in uvec4 instData;

//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__
//__QUATERNIONDEFS__

struct SUniformsBuffer {
    uint composite; //     u8 drawFlag; u8 unused1; u16 id;
    
    uint unused2;
    uint unused3;
    uint unused4;

    float maxHealth;
    float health;
    float unused5;
    float unused6;
    
    vec4 drawPos;
    vec4 speed;
    vec4[4] userDefined; //can't use float[16] because float in arrays occupies 4 * float space
};

layout(std140, binding=1) readonly buffer UniformsBuffer {
    SUniformsBuffer uni[];
}; 

#define UNITID (uni[instData.y].composite >> 16)

#line 10000

uniform float addRadius = 0.0;
uniform float iconDistance = 20000.0;

out DataVS {
	uint v_numvertices;
	float v_rotationY;
	vec4 v_color;
	vec4 v_lengthwidthcornerheight;
	vec4 v_centerpos;
	vec4 v_uvoffsets;
	vec4 v_parameters;
	#if (FULL_ROTATION == 1)
		mat3 v_fullrotation;
	#endif
};

#if USEQUATERNIONS == 0
	layout(std140, binding=0) readonly buffer MatrixBuffer {
		mat4 UnitPieces[];
	};
#endif

bool vertexClipped(vec4 clipspace, float tolerance) {
  return any(lessThan(clipspace.xyz, -clipspace.www * tolerance)) ||
         any(greaterThan(clipspace.xyz, clipspace.www * tolerance));
}

void main()
{
	uint baseIndex = instData.x; // this tells us which unit matrix to find
	#if USEQUATERNIONS == 0
		mat4 modelMatrix = UnitPieces[baseIndex]; // This gives us the models  world pos and rot matrix
	#else
		Transform modelWorldTX = GetModelWorldTransform(instData.x);
		mat4 modelMatrix = TransformToMatrix(modelWorldTX);
	#endif

	gl_Position = cameraViewProj * vec4(modelMatrix[3].xyz, 1.0); // We transform this vertex into the center of the model
	v_rotationY = atan(modelMatrix[0][2], modelMatrix[0][0]); // we can get the euler Y rot of the model from the model matrix
	v_uvoffsets = uvoffsets;
	v_parameters = parameters;
	// 255: local selection color
	// 244: preselection color
	if (teamID == 255) v_color = vec4(0.1, 1.0, 0.2, 1.0);
	else if (teamID == 254) v_color = vec4(0.1, 1.0, 1.0, 1.0);
	else if (teamID == 253) v_color = vec4(1.0, 0.2, 0.1, 1.0);
	else if (teamID == 252) v_color = vec4(1.0, 1.0, 0.1, 1.0);
	else v_color = teamColor[teamID];
	v_centerpos = vec4( modelMatrix[3].xyz, 1.0); // We are going to pass the centerpoint to the GS
	v_lengthwidthcornerheight = lengthwidthcornerheight;
	#if (ANIMATION == 1)
		// No animation when parameters.y is 0
		float initial = clamp(((timeInfo.x + timeInfo.w) - parameters.x)/GROWTHRATE + INITIALSIZE, max(INITIALSIZE, float(1 - parameters.y)), 1.0);
		float breathe = (BREATHESIZE + sin((timeInfo.x)/BREATHERATE)*BREATHESIZE) * parameters.y;
		v_lengthwidthcornerheight.xy *= initial;
		v_lengthwidthcornerheight.xy += breathe;
	#endif
	POST_ANIM
	v_numvertices = numvertices;
	if (vertexClipped(gl_Position, CLIPTOLERANCE)) v_numvertices = 0; // Make no primitives on stuff outside of screen
	// TODO: take into account size of primitive before clipping

	// this sets the num prims to 0 for units further from cam than iconDistance
	float cameraDistance = length((cameraViewInv[3]).xyz - v_centerpos.xyz);
	if (cameraDistance > iconDistance) v_numvertices = 0;

	if (dot(v_centerpos.xyz, v_centerpos.xyz) < 1.0) v_numvertices = 0; // if the center pos is at (0,0,0) then we probably dont have the matrix yet for this unit, because it entered LOS but has not been drawn yet.

	v_centerpos.y += HEIGHTOFFSET; // Add some height to ensure above groundness
	v_centerpos.y += lengthwidthcornerheight.w; // Add per-instance height offset
	#if (FULL_ROTATION == 1)
		v_fullrotation = mat3(modelMatrix);
	#endif
	if ((uni[instData.y].composite & 0x00000003u) < 1u ) v_numvertices = 0u; // this checks the drawFlag of wether the unit is actually being drawn (this is ==1 when then unit is both visible and drawn as a full model (not icon)) 
	// TODO: allow overriding this check, to draw things even if unit (like a building) is not drawn
	POST_VERTEX
}