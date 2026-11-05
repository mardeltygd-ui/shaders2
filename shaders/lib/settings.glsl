// ---------------------------------------------------------------
//  Soft Warm Shaders - settings (shared by every stage)
// ---------------------------------------------------------------

#define SHADOWS                       // Soft block shadows (sun by day, moon by night)
#define SHADOW_QUALITY 1              // [0 1]
#define SHADOW_RES 1024               // [512 768 1024 1536 2048]
#define SHADOW_DIST 64.0              // [32.0 48.0 64.0 96.0 128.0]
#define GODRAYS                       // Cheap light shafts
#define GODRAY_STRENGTH 0.35          // [0.10 0.20 0.35 0.50 0.70]
#define RAY_SAMPLES 8                 // [4 6 8 12]
#define WARMTH 1.0                    // [0.0 0.5 1.0 1.5]
#define VIGNETTE                      // Soft vignette

const int   shadowMapResolution = SHADOW_RES;
const float shadowDistance      = SHADOW_DIST;
const float sunPathRotation     = -25.0;
const bool  shadowtex1Nearest   = true;
