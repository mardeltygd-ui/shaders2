// ---------------------------------------------------------------
//  Soft Warm Shaders - settings (low defaults for weak PCs)
// ---------------------------------------------------------------

#define SHADOWS                       // Soft block shadows (sun by day, moon by night)
#define SHADOW_QUALITY 0              // [0 1]
#define SHADOW_RES 512                // [128 256 512 768 1024 1536 2048]
#define SHADOW_DIST 24.0              // [16.0 24.0 32.0 48.0 64.0 96.0]
#define SKY_RAYS                      // Sun rays in the sky (never block the view)
//#define LITE                        // set by the lite build: no shadow pass at all
#define WARMTH 1.0                    // [0.0 0.5 1.0 1.5]

const int   shadowMapResolution = SHADOW_RES;
const float shadowDistance      = SHADOW_DIST;
const float sunPathRotation     = -25.0;
const bool  shadowtex1Nearest   = true;
