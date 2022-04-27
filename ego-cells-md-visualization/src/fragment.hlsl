#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
// uniform ivec3 palette[colors];

// Output fragment color
out vec4 finalColor;

void main()
{
    // finalColor = fragColor + vec4(fragTexCoord.x, fragTexCoord.y, 0.0, 1.0);
    finalColor = vec4(0.0, 0.0, 0.0, 1.0);
}
