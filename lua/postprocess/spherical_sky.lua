
local shaderName = "SphericalSky"

local r_sky_spherical               = CreateClientConVar( "r_sky_spherical", "0", true, false, "Enable Spherical Sky.", 0, 1 )
local r_sky_spherical_adaptation    = CreateClientConVar( "r_sky_spherical_adaptation", "1", true, false, "Enable Spherical Sky only if map.", 0, 1 )
local r_sky_spherical_brightness    = CreateClientConVar( "r_sky_spherical_brightness", "1", true, false, "Spherical Sky brightness.", 0, 16 )

local mat_full = Material("sky/sky_main_full")
local mat_half = Material("sky/sky_main_half")

local sky_textures = {} -- use ConfigSphericalSky hook to add sky to this table. Check spherical_sky_config.lua
for name_hook, func in pairs(hook.GetTable()["ConfigSphericalSky"] or {}) do
    table.Merge(sky_textures, func())
end

local addons = engine.GetAddons()

for k = 1, #addons do
    local addon = addons[k]
    local id = addon.wsid
    local mounted = addon.mounted

    if !mounted then continue end

    if id == "1572289906" then -- DOOM 2016 Skydome
        for i = 1,22 do
            local n = i < 10 and "0"..i or i
            sky_textures[#sky_textures + 1] = "models/kss/doom/skyboxes/doom_sky".. n
        end
    end

    if id == "2392795426" then -- BF1 Skydomes
        for i = 1,22 do
            local n = i < 10 and "0"..i or i
            sky_textures[#sky_textures + 1] = "models/dishonored 2/skybox/bf1_sky".. n
        end
    end

    if id == "2924967056" then -- Infinite Stratos Skydome (Prop)
        sky_textures[#sky_textures + 1] = "models/InfiniteStratos/other/Skydom/arena_1_sky_sun"
        sky_textures[#sky_textures + 1] = "models/InfiniteStratos/other/Skydom/arena_5_sky_red"
        sky_textures[#sky_textures + 1] = "models/InfiniteStratos/other/Skydom/arena_7_sky_night"
    end
end

local r_sky_spherical_tex = CreateClientConVar( "r_sky_spherical_tex", "0", true, false, "Spherical Sky texture.", 0, 1 )

if IsMounted("vietnam") then -- Military Conflict: Vietnam https://store.steampowered.com/app/1012110/Military_Conflict_Vietnam/
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_airbase"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_bridge"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_camp"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_depot"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_embassy"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_factory"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_hospital"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_mansion"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_outpost"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_port"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_ricefield"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_ruins"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_saigon"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_siege"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_tower"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_training"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_usns_card"
    sky_textures[#sky_textures + 1] = "sky/sky_mcv_warehouse"
    sky_textures[#sky_textures + 1] = "sky/stars" -- текстура в MCV, материал в аддоне
end

local half_sky = false

local function GetSkyMaterial()
    return half_sky and mat_half or mat_full
end

local function SetSkyMaterial(texture, brightness)
    if !brightness then brightness = r_sky_spherical_brightness:GetFloat() end

    local ref_mat = Material(texture)
    if ref_mat:IsError() or !ref_mat then
        ref_mat = Material(sky_textures[1])
    end

    -- нужно определять формат текстуры чтением HEX через file
    local aspect = ref_mat:Height() / ref_mat:Width()
    -- 0.25 half spherical sky
    -- 0.5  full size spherical sky
    -- переопределяем материал

    half_sky = aspect == 0.25
    mat_half:SetFloat("$c0_x", brightness)
    mat_full:SetFloat("$c0_x", brightness)

    local basetexture   = ref_mat:GetTexture("$basetexture")
    mat_half:SetTexture("$basetexture", basetexture)
    mat_full:SetTexture("$basetexture", basetexture)
end

list.Set( "PostProcess", "#r_sky_spherical.name", {
    ["icon"] = "gui/postprocess/spherical_sky.jpg",
    ["convar"] = r_sky_spherical:GetName(),
    ["category"] = "#shaders_pp",
    ["cpanel"] = function( panel )
        panel:Help( "#r_sky_spherical.info" )

        panel:AddControl( "ComboBox", {
            ["MenuButton"] = 1,
            ["Folder"] = "sky_spherical",
            ["sky_textures"] = {
                [ "#preset.default" ] = {
                    [ r_sky_spherical:GetName() ] = r_sky_spherical:GetDefault(),
                    [ r_sky_spherical_brightness:GetName() ] = r_sky_spherical_brightness:GetDefault(),
                    [ r_sky_spherical_adaptation:GetName() ] = r_sky_spherical_adaptation:GetDefault(),
                }
            },
            ["CVars"] = {
                r_sky_spherical:GetName(),
                r_sky_spherical_brightness:GetName(),
                r_sky_spherical_adaptation:GetName(),
            }
        } )

        panel:AddControl( "CheckBox", { Label = "#r_sky_spherical.enable", Command = r_sky_spherical:GetName() } )
        panel:AddControl( "CheckBox", { Label = "#r_sky_spherical.adaptation", Command = r_sky_spherical_adaptation:GetName(), Help = true } )

        panel:AddControl( "Slider", {
            ["Label"] = "#r_sky_spherical.brightness",
            ["Command"] = r_sky_spherical_brightness:GetName(),
            ["Min"] = tostring( r_sky_spherical_brightness:GetMin() ),
            ["Max"] = tostring( r_sky_spherical_brightness:GetMax() ),
            ["Type"] = "Float",
        } )

        local matselect = panel:MatSelect( r_sky_spherical_tex:GetName(), sky_textures, nil, 256, 64 )

        function matselect:OnSelect( material, pnl )
            SetSkyMaterial(material)
        end

        panel:Help( "#r_sky_spherical.notify" )
        panel:Help( "#r_sky_spherical.notify_creator" )
        panel:Help( "#r_sky_spherical.notify_mapper" )
    end
} )

-- GShader library matrix functions
local t00_10    = {0,0,-1,0}
local t0001     = {0,0, 0,1}
local t0011     = {0,0, 1,1}

local function GetViewMatrix(pos, ang)
    local D = -ang:Forward()
    local R = ang:Right()
    local U = -ang:Up()
    local P = -pos

    local mFirst = Matrix({
        {R.x,   R.y,    R.z,    0},
        {U.x,   U.y,    U.z,    0},
        {D.x,   D.y,    D.z,    0},
        t0001,
    })

    local mSecond = Matrix({
        {1,     0,      0,      P.x},
        {0,     1,      0,      P.y},
        {0,     0,      1,      P.z},
        t0001,
    })

    mFirst:Mul(mSecond)

    return mFirst
end

local function GetProjMatrix(viewSetup) --Perspective projection matrix
    local fov = viewSetup.fov
    fov = 1/math.tan( math.rad(fov * 0.5)  )
    local aspect = viewSetup.aspect or 1

    local mProj = Matrix({
        {   fov,  0,            0,              0,          },
        {   0,  fov*aspect,     0,              0,          },
        t0011,
        t00_10
    })

    return mProj
end

local function GetViewProjMatrix(viewSetup)
    local pos, ang = viewSetup.origin, viewSetup.angles
    local mView = GetViewMatrix(pos, ang)

    local mProj = GetProjMatrix(viewSetup)
    mProj:Mul(mView)

    return mProj
end

local function InitSphereSky()
    hook.Add("PostDraw2DSkyBox", shaderName, function()
        local viewSetup = render.GetViewSetup()
        if !util.IsSkyboxVisibleFromPoint( viewSetup.origin ) then return end

        viewSetup.origin = vector_origin
        viewSetup.angles = EyeAngles() -- _rt_waterreflection adaptation

        local aspect = viewSetup.aspect

        local mat = GetSkyMaterial()
        local ViewProj = GetViewProjMatrix(viewSetup):GetInverse()
        mat:SetMatrix("$viewprojmat", ViewProj)

        render.SetMaterial( mat )
        render.DrawScreenQuad()
    end)
end

cvars.AddChangeCallback( r_sky_spherical_adaptation:GetName(), function( convar_name, _, identifier )
    local enable = identifier == "1"

    if enable and IsValid(ENV_SKY) then
        SetSkyMaterial( ENV_SKY_MAT, ENV_SKY_BRIGNTNESS )
        InitSphereSky()
    else 
        if r_sky_spherical:GetBool() then return end
        hook.Remove("PostDraw2DSkyBox", shaderName)
    end
end, shaderName )

cvars.AddChangeCallback( r_sky_spherical:GetName(), function( convar_name, _, identifier )
    local enable = identifier == "1"

    if enable then
        InitSphereSky()
    else 
        if r_sky_spherical_adaptation:GetBool() and IsValid(ENV_SKY) then return end
        hook.Remove("PostDraw2DSkyBox", shaderName)
    end
end, shaderName )

cvars.AddChangeCallback( r_sky_spherical_tex:GetName(), function( convar_name, _, identifier )
    SetSkyMaterial(identifier)
end, shaderName )

cvars.AddChangeCallback( r_sky_spherical_brightness:GetName(), function( convar_name, _, identifier )
    mat_full:SetFloat("$c0_x", identifier)
    mat_half:SetFloat("$c0_x", identifier)
end, shaderName )

SetSkyMaterial( r_sky_spherical_tex:GetString(), r_sky_spherical_brightness:GetFloat() )

hook.Add("InitPostEntity", shaderName, function()
    -- Hammer entity support
    ENV_SKY = ents.FindByClass("env_sky")[1] or ents.FindByClass("env_atmosphere")[1]
    -- env_sky is a DX9 entity of MC:V, env_atmosphere will be a new entity of MC:V on DX11
    if IsValid(ENV_SKY) then
        ENV_SKY_MAT = ENV_SKY:GetNWString("staticskytexpath")
        ENV_SKY_BRIGNTNESS = ENV_SKY:GetNWFloat("brightness", 1)
        SetSkyMaterial( ENV_SKY_MAT, ENV_SKY_BRIGNTNESS )

        if r_sky_spherical_adaptation:GetBool() then
            InitSphereSky()
        end
        return
    end
    
    if !r_sky_spherical:GetBool() then return end
    InitSphereSky()
end)

