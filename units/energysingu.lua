return { energysingu = {
  name                          = [[Singularity Reactor]],
  description                   = [[Large Powerplant - HAZARDOUS]],
  activateWhenBuilt             = true,
  builder                       = false,
  buildingGroundDecalDecaySpeed = 30,
  buildingGroundDecalSizeX      = 9,
  buildingGroundDecalSizeY      = 9,
  buildingGroundDecalType       = [[energysingu_aoplane.dds]],
  buildPic                      = [[energysingu.png]],
  category                      = [[SINK UNARMED]],
  collisionVolumeOffsets        = [[0 0 0]],
  collisionVolumeScales         = [[120 120 120]],
  collisionVolumeType           = [[ellipsoid]],
  corpse                        = [[DEAD]],

  customParams                  = {
    pylonrange = 150,
    aimposoffset   = [[0 12 0]],
    midposoffset   = [[0 12 0]],
    modelradius    = [[60]],
    removewait     = 1,
    removestop     = 1,
    selectionscalemult = 1.15,

    stats_show_death_explosion = 1,

    outline_x = 200,
    outline_y = 200,
    outline_yoff = 55,
  },

  energyMake                    = 225,
  explodeAs                     = [[SINGULARITY]],
  footprintX                    = 7,
  footprintZ                    = 7,
  health                        = 4500,
  iconType                      = [[energysingu]],
  maxSlope                      = 18,
  maxWaterDepth                 = 0,
  metalCost                     = 4000,
  noAutoFire                    = false,
  objectName                    = [[fus.s3o]],
  onoffable                     = false,
  script                        = [[energysingu.lua]],
  selfDestructAs                = [[SINGULARITY]],
  sightDistance                 = 273,
  useBuildingGroundDecal        = true,
  yardMap                       = [[ooooooooooooooooooooooooooooooooooooooooooooooooo]],

  featureDefs                   = {

    DEAD = {
      blocking         = true,
      collisionVolumeScales  = [[100 36 100]],
      collisionVolumeOffsets = [[0 -33 0]],
      collisionVolumeType    = [[cylY]],
      featureDead      = [[HEAP]],
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[fus_dead.s3o]],
    },


    HEAP = {
      blocking         = false,
      footprintX       = 7,
      footprintZ       = 7,
      object           = [[debris4x4a.s3o]],
    },

  },

  weaponDefs = {
    SINGULARITY = {
      areaOfEffect       = 1280,
      craterMult         = 1,
      edgeEffectiveness  = 0,
      explosionGenerator = "custom:grav_danger_spikes",
      explosionSpeed     = 100000,
      impulseBoost       = 100,
      impulseFactor      = -10,
      name               = "Naked Singularity",
      soundHit           = "explosion/ex_ultra1",
      damage = {
        default = 9500,
      },
    },
  },
} }
