local Library
do
    local existing = getgenv and getgenv().Library
    if existing and existing.Exit then
        pcall(function()
            existing:Exit()
        end)
    end

    cloneref = cloneref or function(Object)
        return Object
    end

    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local HttpService = game:GetService("HttpService")
    local TweenService = game:GetService("TweenService")
    local GuiService = game:GetService("GuiService")
    local Stats = game:GetService("Stats")
    local CoreGui = cloneref(game:GetService("CoreGui"))

    gethui = gethui or function()
        return CoreGui
    end

    local LocalPlayer = Players.LocalPlayer
    local IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

    local function safeCallResult(fn, ...)
        if type(fn) ~= "function" then
            return false, nil
        end
        local ok, res = pcall(fn, ...)
        return ok, res
    end

    local function safeIsFolder(path)
        local ok, res = safeCallResult(isfolder, path)
        return ok and res == true
    end

    local function safeMakeFolder(path)
        safeCallResult(makefolder, path)
    end

    local function safeIsFile(path)
        local ok, res = safeCallResult(isfile, path)
        return ok and res == true
    end

    local function safeWriteFile(path, data)
        return safeCallResult(writefile, path, data)
    end

    local function safeReadFile(path)
        local ok, res = safeCallResult(readfile, path)
        return ok and res or nil
    end

    local function safeDelFile(path)
        return safeCallResult(delfile, path)
    end

    local function safeListFiles(path)
        local ok, res = safeCallResult(listfiles, path)
        return (ok and type(res) == "table") and res or {}
    end

    local function safeHttpGet(url)
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)
        return ok and res or nil
    end

    Library = {
        Flags = {},
        MenuKeybind = tostring(Enum.KeyCode.RightShift),

        Directory = "Radiance",
        Folders = {
            Assets = "/Assets",
            Configs = "/Configs",
        },

        FontSize = 12,
        Scale = 1,

        Animation = {
            Time = 0.18,
            Style = "Cubic",
            Direction = "Out",
        },

        ZIndexOrder = {
            ["KeybindWindow"] = 15,
            ["OptionHolder"] = 20,
            ["ColorpickerWindow"] = 25,
            ["Notification"] = 50,
        },

        Theme = nil,
        ThemeOrder = {
            "Accent",
            "Background",
            "Inline",
            "Content",
            "Hovered Element",
            "Text",
            "Inactive Text",
            "Outline 1",
            "Outline 2",
            "Outline 3",
            "Outline 4",
        },

        Threads = {},
        Connections = {},
        SetFlags = {},

        ThemingStuff = {},
        ThemeMap = {},
        DestroyedInstances = setmetatable({}, { __mode = "k" }),

        OpenFrames = {},
        ActiveDragLock = false,
        IsPickingKeybind = false,

        Holder = nil,
        UnusedHolder = nil,
        NotifHolder = nil,
        WindowScale = nil,

        Font = nil,
        BoldFont = nil,
    }
    Library.__index = Library

    local Flags = Library.Flags
    local SetFlags = Library.SetFlags
    local ConfigsFolder = Library.Directory .. Library.Folders.Configs .. "/"
    local AssetsFolder = Library.Directory .. Library.Folders.Assets .. "/"
    local AutoloadFile = ConfigsFolder .. "_autoload.txt"

    local RestTransparencies = setmetatable({}, { __mode = "k" })
    local FadeTokens = setmetatable({}, { __mode = "k" })
    local ActiveFading = setmetatable({}, { __mode = "k" })

    local KeyDisplayMap = {
        Unknown = "None",
        Backspace = "None",
        Tab = "Tab",
        Clear = "Clear",
        Return = "Enter",
        Pause = "Pause",
        Escape = "Esc",
        Space = "Space",
        QuotedDouble = '"',
        Hash = "#",
        Dollar = "$",
        Percent = "%",
        Ampersand = "&",
        Quote = "'",
        LeftParenthesis = "(",
        RightParenthesis = ")",
        Asterisk = "*",
        Plus = "+",
        Comma = ",",
        Minus = "-",
        Period = ".",
        Slash = "/",
        BackSlash = "\\",
        Colon = ":",
        Semicolon = ";",
        LessThan = "<",
        GreaterThan = ">",
        Question = "?",
        Equals = "=",
        At = "@",
        LeftBracket = "[",
        RightBracket = "]",
        Caret = "^",
        Underscore = "_",
        Backquote = "`",
        LeftCurly = "{",
        Pipe = "|",
        RightCurly = "}",
        Tilde = "~",
        Delete = "Del",
        End = "End",
        Insert = "Ins",
        Home = "Home",
        PageUp = "PgUp",
        PageDown = "PgDn",
        CapsLock = "Caps",
        RightShift = "RShift",
        LeftShift = "LShift",
        RightControl = "RCtrl",
        LeftControl = "LCtrl",
        LeftAlt = "LAlt",
        RightAlt = "RAlt",
        KeypadZero = "Num0",
        KeypadOne = "Num1",
        KeypadTwo = "Num2",
        KeypadThree = "Num3",
        KeypadFour = "Num4",
        KeypadFive = "Num5",
        KeypadSix = "Num6",
        KeypadSeven = "Num7",
        KeypadEight = "Num8",
        KeypadNine = "Num9",
        KeypadPeriod = "Num.",
        KeypadDivide = "Num/",
        KeypadMultiply = "Num*",
        KeypadMinus = "Num-",
        KeypadPlus = "Num+",
        KeypadEnter = "NumEnt",
        KeypadEquals = "Num=",
        MouseButton1 = "MB1",
        MouseButton2 = "MB2",
        MouseButton3 = "MB3",
        Zero = "0",
        One = "1",
        Two = "2",
        Three = "3",
        Four = "4",
        Five = "5",
        Six = "6",
        Seven = "7",
        Eight = "8",
        Nine = "9",
    }

    if not safeIsFolder(Library.Directory) then
        safeMakeFolder(Library.Directory)
    end
    for _, Folder in pairs(Library.Folders) do
        local fullPath = Library.Directory .. Folder
        if not safeIsFolder(fullPath) then
            safeMakeFolder(fullPath)
        end
    end

    local ThemePresets = {
        ["Radiance Blue"] = {
            ["Background"] = Color3.fromRGB(22, 22, 24),
            ["Inline"] = Color3.fromRGB(19, 19, 21),
            ["Content"] = Color3.fromRGB(17, 17, 19),
            ["Text"] = Color3.fromRGB(212, 214, 219),
            ["Outline 1"] = Color3.fromRGB(40, 40, 45),
            ["Outline 2"] = Color3.fromRGB(28, 28, 31),
            ["Outline 3"] = Color3.fromRGB(13, 13, 15),
            ["Outline 4"] = Color3.fromRGB(8, 8, 9),
            ["Inactive Text"] = Color3.fromRGB(130, 133, 140),
            ["Accent"] = Color3.fromRGB(126, 192, 255),
            ["Hovered Element"] = Color3.fromRGB(30, 32, 38),
        },
        ["Midnight Violet"] = {
            ["Background"] = Color3.fromRGB(21, 20, 25),
            ["Inline"] = Color3.fromRGB(18, 17, 22),
            ["Content"] = Color3.fromRGB(16, 15, 20),
            ["Text"] = Color3.fromRGB(214, 212, 222),
            ["Outline 1"] = Color3.fromRGB(42, 39, 50),
            ["Outline 2"] = Color3.fromRGB(28, 26, 35),
            ["Outline 3"] = Color3.fromRGB(13, 12, 16),
            ["Outline 4"] = Color3.fromRGB(8, 7, 11),
            ["Inactive Text"] = Color3.fromRGB(132, 129, 145),
            ["Accent"] = Color3.fromRGB(166, 142, 255),
            ["Hovered Element"] = Color3.fromRGB(32, 30, 42),
        },
        ["Abyss Cyan"] = {
            ["Background"] = Color3.fromRGB(19, 22, 24),
            ["Inline"] = Color3.fromRGB(17, 19, 21),
            ["Content"] = Color3.fromRGB(15, 17, 19),
            ["Text"] = Color3.fromRGB(208, 216, 220),
            ["Outline 1"] = Color3.fromRGB(35, 42, 46),
            ["Outline 2"] = Color3.fromRGB(24, 30, 33),
            ["Outline 3"] = Color3.fromRGB(11, 14, 16),
            ["Outline 4"] = Color3.fromRGB(7, 9, 11),
            ["Inactive Text"] = Color3.fromRGB(126, 139, 145),
            ["Accent"] = Color3.fromRGB(88, 214, 245),
            ["Hovered Element"] = Color3.fromRGB(28, 35, 39),
        },
        ["Crimson"] = {
            ["Background"] = Color3.fromRGB(23, 21, 22),
            ["Inline"] = Color3.fromRGB(20, 18, 19),
            ["Content"] = Color3.fromRGB(18, 16, 17),
            ["Text"] = Color3.fromRGB(214, 208, 210),
            ["Outline 1"] = Color3.fromRGB(44, 36, 38),
            ["Outline 2"] = Color3.fromRGB(30, 25, 26),
            ["Outline 3"] = Color3.fromRGB(14, 12, 13),
            ["Outline 4"] = Color3.fromRGB(9, 7, 8),
            ["Inactive Text"] = Color3.fromRGB(138, 130, 132),
            ["Accent"] = Color3.fromRGB(235, 88, 102),
            ["Hovered Element"] = Color3.fromRGB(36, 29, 31),
        },
        ["Emerald"] = {
            ["Background"] = Color3.fromRGB(20, 23, 21),
            ["Inline"] = Color3.fromRGB(18, 20, 19),
            ["Content"] = Color3.fromRGB(16, 18, 17),
            ["Text"] = Color3.fromRGB(206, 214, 208),
            ["Outline 1"] = Color3.fromRGB(35, 42, 38),
            ["Outline 2"] = Color3.fromRGB(25, 30, 27),
            ["Outline 3"] = Color3.fromRGB(12, 15, 13),
            ["Outline 4"] = Color3.fromRGB(8, 10, 9),
            ["Inactive Text"] = Color3.fromRGB(128, 138, 132),
            ["Accent"] = Color3.fromRGB(98, 216, 148),
            ["Hovered Element"] = Color3.fromRGB(29, 36, 32),
        },
        ["Slate Mono"] = {
            ["Background"] = Color3.fromRGB(22, 22, 23),
            ["Inline"] = Color3.fromRGB(19, 19, 20),
            ["Content"] = Color3.fromRGB(17, 17, 18),
            ["Text"] = Color3.fromRGB(218, 218, 220),
            ["Outline 1"] = Color3.fromRGB(42, 42, 45),
            ["Outline 2"] = Color3.fromRGB(30, 30, 32),
            ["Outline 3"] = Color3.fromRGB(14, 14, 15),
            ["Outline 4"] = Color3.fromRGB(9, 9, 10),
            ["Inactive Text"] = Color3.fromRGB(136, 136, 140),
            ["Accent"] = Color3.fromRGB(198, 206, 218),
            ["Hovered Element"] = Color3.fromRGB(34, 34, 37),
        },
    }

    Library.ThemePresets = ThemePresets
    Library.Theme = {}
    for Key, Color in pairs(ThemePresets["Radiance Blue"]) do
        Library.Theme[Key] = Color
    end

    local function loadCustomFont(Name, Weight, Style, Data, FallbackEnum)
        local fallback = Font.fromEnum(FallbackEnum or Enum.Font.SourceSans)
        if type(getcustomasset) ~= "function" then
            return fallback
        end

        local ok, loaded = pcall(function()
            local ttfPath = AssetsFolder .. Data.Id .. ".ttf"
            local sourcePath = ttfPath
            if safeIsFile(Data.Id) then
                sourcePath = Data.Id
            elseif not safeIsFile(ttfPath) then
                local body = safeHttpGet(Data.Url)
                if not body or #body < 128 then
                    return fallback
                end
                safeWriteFile(ttfPath, body)
            end

            local manifest = {
                name = Name,
                faces = {
                    {
                        name = Name,
                        weight = Weight,
                        style = Style,
                        assetId = getcustomasset(sourcePath),
                    },
                },
            }

            local fontPath = AssetsFolder .. Name .. ".font"
            safeWriteFile(fontPath, HttpService:JSONEncode(manifest))
            return Font.new(getcustomasset(fontPath))
        end)

        return (ok and loaded) and loaded or fallback
    end

    Library.Font = loadCustomFont("WindowsXPTAHOMA", 400, "Regular", {
        Id = "WindowsXPTAHOMA",
        Url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/windows-xp-tahoma.ttf",
    }, Enum.Font.SourceSans)

    Library.BoldFont = loadCustomFont("Tahoma8PTBOLD", 700, "Regular", {
        Id = "Tahoma8PTBOLD",
        Url = "https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/TAHOMA-8PT-BOLD-WINDOWS-XP.TTF",
    }, Enum.Font.SourceSansBold)

    local TRANSPARENCY_PROPS = {
        "BackgroundTransparency",
        "TextTransparency",
        "ImageTransparency",
        "ScrollBarImageTransparency",
        "Transparency",
    }

    local function recordRestTransparency(InstanceObj)
        local map = RestTransparencies[InstanceObj]
        if not map then
            map = {}
            RestTransparencies[InstanceObj] = map
        end
        local props = Library:GetTweenProperty(InstanceObj)
        if props then
            for _, prop in ipairs(props) do
                if map[prop] == nil then
                    map[prop] = InstanceObj[prop]
                end
            end
        end
        return map
    end

    local function setRestTransparency(InstanceObj, Prop, Value)
        local map = RestTransparencies[InstanceObj]
        if not map then
            map = {}
            RestTransparencies[InstanceObj] = map
        end
        map[Prop] = Value
    end

    local function getTweenInfo(Info)
        if Info then
            return Info
        end
        local okStyle, style = pcall(function()
            return Enum.EasingStyle[Library.Animation.Style]
        end)
        local okDir, dir = pcall(function()
            return Enum.EasingDirection[Library.Animation.Direction]
        end)
        return TweenInfo.new(
            math.max(0, tonumber(Library.Animation.Time) or 0.18),
            okStyle and style or Enum.EasingStyle.Cubic,
            okDir and dir or Enum.EasingDirection.Out
        )
    end

    local function getViewportSize()
        local holderInst = Library.Holder and Library.Holder.Instance
        if holderInst and holderInst.AbsoluteSize.X > 0 and holderInst.AbsoluteSize.Y > 0 then
            return holderInst.AbsoluteSize
        end
        local cam = workspace.CurrentCamera
        if cam and cam.ViewportSize.X > 0 and cam.ViewportSize.Y > 0 then
            return cam.ViewportSize
        end
        return Vector2.new(1920, 1080)
    end

    local function getHolderOrigin()
        local holderInst = Library.Holder and Library.Holder.Instance
        if holderInst then
            return holderInst.AbsolutePosition
        end
        return Vector2.new(0, 0)
    end

    local function getPointerPosition(Input)
        if Input and Input.UserInputType == Enum.UserInputType.Touch then
            local inset = GuiService:GetGuiInset()
            return Vector2.new(Input.Position.X, Input.Position.Y + inset.Y)
        end
        return UserInputService:GetMouseLocation()
    end

    local function formatKeyDisplay(EnumItem)
        if not EnumItem then
            return "None"
        end
        local name = typeof(EnumItem) == "EnumItem" and EnumItem.Name or tostring(EnumItem)
        name = string.gsub(name, "Enum%.KeyCode%.", "")
        name = string.gsub(name, "Enum%.UserInputType%.", "")
        return KeyDisplayMap[name] or name
    end

    local function setPopupZIndex(Root, ZBase)
        local descendants = Root:GetDescendants()
        table.insert(descendants, Root)
        for _, obj in ipairs(descendants) do
            if obj:IsA("GuiObject") then
                local offset = obj:GetAttribute("ZOffset") or 0
                obj.ZIndex = ZBase + offset
            end
        end
    end

    local function placePopup(PopupInst, AnchorInst, FallbackWidth, FallbackHeight)
        local vp = getViewportSize()
        local origin = getHolderOrigin()
        local anchorPos = AnchorInst.AbsolutePosition - origin
        local anchorSize = AnchorInst.AbsoluteSize

        local w = PopupInst.AbsoluteSize.X > 0 and PopupInst.AbsoluteSize.X or (FallbackWidth or 200)
        local h = PopupInst.AbsoluteSize.Y > 0 and PopupInst.AbsoluteSize.Y or (FallbackHeight or 160)

        local x = anchorPos.X
        local y = anchorPos.Y + anchorSize.Y + 4

        if x + w > vp.X - 8 then
            x = math.max(8, vp.X - w - 8)
        end
        if x < 8 then
            x = 8
        end

        if y + h > vp.Y - 8 and (anchorPos.Y - h - 4) >= 8 then
            y = anchorPos.Y - h - 4
        elseif y + h > vp.Y - 8 then
            y = math.max(8, vp.Y - h - 8)
        end

        return x, y
    end

    function Library:Exit()
        if self.TargetIndicatorList then
            for _, ind in ipairs(self.TargetIndicatorList) do
                if ind and ind.ResetConnection then
                    pcall(function()
                        ind:ResetConnection()
                    end)
                end
            end
        end

        for _, Connection in ipairs(self.Connections) do
            if Connection and Connection.Connected then
                Connection:Disconnect()
            end
        end
        table.clear(self.Connections)

        for _, Thread in ipairs(self.Threads) do
            pcall(coroutine.close, Thread)
        end
        table.clear(self.Threads)

        if self.Holder and self.Holder.Instance then
            self.Holder.Instance:Destroy()
        end

        if self.UnusedHolder and self.UnusedHolder.Instance then
            self.UnusedHolder.Instance:Destroy()
        end

        if getgenv then
            getgenv().Library = nil
        end
    end

    function Library:Create(Class, Properties)
        Properties = Properties or {}
        local inst = Instance.new(Class)
        local Data = {
            Class = Class,
            Properties = Properties,
            Instance = inst,
        }

        if inst:IsA("GuiObject") then
            inst.BorderSizePixel = 0
        end

        if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
            inst.FontFace = Library.Font
            inst.TextSize = Library.FontSize
        end

        if inst:IsA("TextButton") then
            inst.AutoButtonColor = false
        end

        for Index, Value in pairs(Properties) do
            if Index == "Name" then
                inst.Name = Value == "\0" and "\0" or tostring(Value)
            elseif Index == "FontFace" then
                inst.FontFace = Value or Library.Font
            elseif Index == "TextSize" then
                inst.TextSize = Value or Library.FontSize
            elseif Class == "TextButton" and Index == "AutoButtonColor" then
                inst.AutoButtonColor = false
            else
                inst[Index] = Value
            end
        end

        recordRestTransparency(inst)
        inst.Destroying:Once(function()
            Library.DestroyedInstances[inst] = true
        end)

        return setmetatable(Data, Library)
    end

    function Library:AddTextStroke(TextObj)
        local inst = TextObj.Instance or TextObj
        return Library:Create("UIStroke", {
            Name = "\0",
            Parent = inst,
            Thickness = 1,
            Color = Color3.fromRGB(0, 0, 0),
            Transparency = 0.15,
        })
    end

    function Library:AddBorderStrokes(Target, Levels)
        local inst = Target.Instance or Target
        local list = Levels or {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        }
        local strokes = {}
        for _, cfg in ipairs(list) do
            local stroke = Library:Create("UIStroke", {
                Name = "\0",
                Parent = inst,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Color = Library.Theme[cfg.Theme],
                BorderOffset = (cfg.Offset and cfg.Offset > 0) and UDim.new(0, cfg.Offset) or UDim.new(0, 0),
            }):AddToTheme({ Color = cfg.Theme })
            table.insert(strokes, stroke)
        end
        return strokes
    end

    function Library:AddSurfaceShade(Target, TopColor, BottomColor, Rotation)
        local inst = Target.Instance or Target
        return Library:Create("UIGradient", {
            Name = "\0",
            Parent = inst,
            Rotation = Rotation or 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, TopColor or Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, BottomColor or Color3.fromRGB(215, 215, 222)),
            }),
        })
    end

    local AccentHairlines = {}

    local function makeAccentSequence(phase)
        local accent = Library.Theme["Accent"]
        local deep = accent:Lerp(Library.Theme["Background"], 0.65)
        local bright = accent:Lerp(Color3.fromRGB(255, 255, 255), 0.42)
        local p = phase or 0
        local keypoints = {}
        local stops = { 0, 0.25, 0.5, 0.75, 1 }
        for i = 1, #stops do
            local u = stops[i]
            local w = 0.5 + 0.5 * math.cos((u - p) * math.pi * 2)
            local col
            if w < 0.5 then
                col = deep:Lerp(accent, w * 2)
            else
                col = accent:Lerp(bright, (w - 0.5) * 2)
            end
            keypoints[i] = ColorSequenceKeypoint.new(u, col)
        end
        return ColorSequence.new(keypoints)
    end

    function Library:AddAccentHairline(Target, ZIndex, Position, Size, Visible)
        local inst = Target.Instance or Target
        local z = ZIndex or 4

        local line = Library:Create("Frame", {
            Name = "\0",
            Parent = inst,
            Position = Position or UDim2.new(0, 0, 0, 0),
            Size = Size or UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Visible = Visible ~= false,
            ZIndex = z,
        })

        local grad = Library:Create("UIGradient", {
            Name = "\0",
            Parent = line.Instance,
            Color = makeAccentSequence(0),
        })

        table.insert(AccentHairlines, { Line = line.Instance, Grad = grad.Instance })
        return line
    end

    local function createChevron(ParentInst, ZIndex)
        local holder = Library:Create("Frame", {
            Name = "\0",
            Parent = ParentInst,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -7, 0.5, 0),
            Size = UDim2.new(0, 7, 0, 4),
            BackgroundTransparency = 1,
            ZIndex = ZIndex or 2,
        })

        local bars = {}
        local widths = { 7, 5, 3, 1 }
        for i = 1, 4 do
            local bar = Library:Create("Frame", {
                Name = "\0",
                Parent = holder.Instance,
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(0.5, 0, 0, i - 1),
                Size = UDim2.new(0, widths[i], 0, 1),
                BackgroundColor3 = Library.Theme["Inactive Text"],
                ZIndex = ZIndex or 2,
            }):AddToTheme({ BackgroundColor3 = "Inactive Text" })
            bars[i] = bar
        end

        local controller = { Holder = holder, Bars = bars }
        function controller:SetOpen(isOpen)
            for i = 1, 4 do
                local y = isOpen and (4 - i) or (i - 1)
                bars[i].Instance.Position = UDim2.new(0.5, 0, 0, y)
                local themeKey = isOpen and "Accent" or "Inactive Text"
                bars[i]:ChangeItemTheme({ BackgroundColor3 = themeKey })
                bars[i]:Tween({ BackgroundColor3 = Library.Theme[themeKey] })
            end
        end
        function controller:SetHovered(hovered, isOpen)
            if isOpen then
                return
            end
            local themeKey = hovered and "Text" or "Inactive Text"
            for i = 1, 4 do
                bars[i]:ChangeItemTheme({ BackgroundColor3 = themeKey })
                bars[i]:Tween({ BackgroundColor3 = Library.Theme[themeKey] })
            end
        end

        return controller
    end

    function Library:Thread(Function)
        local NewThread = task.spawn(Function)
        table.insert(Library.Threads, NewThread)
        return NewThread
    end

    function Library:Connect(SignalOrName, Callback)
        local Connection

        if self and self.Instance and type(SignalOrName) == "string" then
            if IsMobile and SignalOrName == "MouseButton1Down" then
                Connection = self.Instance.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Callback(Input)
                    end
                end)
            else
                Connection = self.Instance[SignalOrName]:Connect(Callback)
            end
        elseif self and self.Instance and typeof(SignalOrName) == "RBXScriptSignal" then
            Connection = SignalOrName:Connect(Callback)
        else
            Connection = SignalOrName:Connect(Callback)
        end

        if Connection then
            table.insert(Library.Connections, Connection)
        end
        return Connection
    end

    Library:Connect(RunService.RenderStepped, function()
        if #AccentHairlines == 0 then
            return
        end
        local phase = (os.clock() * 0.45) % 1
        local seq = makeAccentSequence(phase)
        local writeIdx = 1
        for i = 1, #AccentHairlines do
            local entry = AccentHairlines[i]
            if entry and entry.Line and not Library.DestroyedInstances[entry.Line] then
                if entry.Line.Visible then
                    entry.Grad.Color = seq
                end
                AccentHairlines[writeIdx] = entry
                writeIdx = writeIdx + 1
            end
        end
        for i = writeIdx, #AccentHairlines do
            AccentHairlines[i] = nil
        end
    end)

    function Library:Tween(Properties, Info, IsRawItem, FromFade)
        local Object = (self and self.Instance) or IsRawItem
        if not Object then
            return nil
        end

        if not FromFade then
            local restMap = RestTransparencies[Object]
            if not restMap then
                restMap = recordRestTransparency(Object)
            end
            for _, prop in ipairs(TRANSPARENCY_PROPS) do
                if Properties[prop] ~= nil then
                    restMap[prop] = Properties[prop]
                end
            end
        end

        local tweenInfo = getTweenInfo(Info)
        if tweenInfo.Time <= 0.005 then
            for k, v in pairs(Properties) do
                Object[k] = v
            end
            if (Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox")) and Properties.TextTransparency ~= nil then
                local stroke = Object:FindFirstChildOfClass("UIStroke")
                if stroke then
                    local strokeRest = RestTransparencies[stroke]
                    local strokeAlpha = strokeRest and strokeRest.Transparency or 0.15
                    stroke.Transparency = Properties.TextTransparency >= 1 and 1 or math.max(strokeAlpha, Properties.TextTransparency)
                end
            end
            return nil
        end

        local NewTween = TweenService:Create(Object, tweenInfo, Properties)
        NewTween:Play()

        if (Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox")) and Properties.TextTransparency ~= nil then
            local Stroke = Object:FindFirstChildOfClass("UIStroke")
            if Stroke then
                if not FromFade then
                    local strokeMap = RestTransparencies[Stroke] or recordRestTransparency(Stroke)
                    strokeMap.Transparency = math.max(0.15, Properties.TextTransparency)
                end
                TweenService:Create(Stroke, tweenInfo, {
                    Transparency = Properties.TextTransparency >= 1 and 1 or math.max(0.15, Properties.TextTransparency),
                }):Play()
            end
        end

        return NewTween
    end

    function Library:GetTweenProperty(IsRawItem)
        local Object = (self and self.Instance) or IsRawItem
        if not Object then
            return {}
        end

        if Object:IsA("Frame") then
            return { "BackgroundTransparency" }
        elseif Object:IsA("TextLabel") or Object:IsA("TextButton") then
            return { "TextTransparency", "BackgroundTransparency" }
        elseif Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
            return { "BackgroundTransparency", "ImageTransparency" }
        elseif Object:IsA("ScrollingFrame") then
            return { "BackgroundTransparency", "ScrollBarImageTransparency" }
        elseif Object:IsA("TextBox") then
            return { "TextTransparency", "BackgroundTransparency" }
        elseif Object:IsA("UIStroke") then
            return { "Transparency" }
        end

        return {}
    end

    function Library:FadeDescendants(Visibility, Callback)
        local root = self and self.Instance
        if not root then
            if Callback then Callback() end
            return
        end

        local token = (FadeTokens[root] or 0) + 1
        FadeTokens[root] = token

        local objects = root:GetDescendants()
        table.insert(objects, root)

        local tweenInfo = getTweenInfo()

        if Visibility then
            local wasVisible = root.Visible
            root.Visible = true
            for _, obj in ipairs(objects) do
                local props = Library:GetTweenProperty(obj)
                if #props > 0 then
                    local restMap = RestTransparencies[obj] or recordRestTransparency(obj)
                    local targetProps = {}
                    local hasChange = false
                    for _, prop in ipairs(props) do
                        local restVal = restMap[prop]
                        if restVal ~= nil then
                            if not wasVisible and not ActiveFading[obj] and restVal < 1 and tweenInfo.Time > 0.005 then
                                obj[prop] = 1
                            end
                            targetProps[prop] = restVal
                            if obj[prop] ~= restVal then
                                hasChange = true
                            end
                        end
                    end
                    ActiveFading[obj] = nil
                    if hasChange then
                        Library:Tween(targetProps, tweenInfo, obj, true)
                    end
                end
            end

            if tweenInfo.Time <= 0.005 then
                if Callback then Callback() end
            else
                task.delay(tweenInfo.Time, function()
                    if FadeTokens[root] ~= token then
                        return
                    end
                    if Callback then Callback() end
                end)
            end
        else
            for _, obj in ipairs(objects) do
                local props = Library:GetTweenProperty(obj)
                if #props > 0 then
                    if not ActiveFading[obj] then
                        local restMap = RestTransparencies[obj] or recordRestTransparency(obj)
                        RestTransparencies[obj] = restMap
                    end
                    ActiveFading[obj] = true

                    local targetProps = {}
                    local hasChange = false
                    for _, prop in ipairs(props) do
                        if obj[prop] < 1 then
                            targetProps[prop] = 1
                            hasChange = true
                        end
                    end
                    if hasChange then
                        Library:Tween(targetProps, tweenInfo, obj, true)
                    end
                end
            end

            local function finalizeHide()
                if FadeTokens[root] ~= token then
                    return
                end
                root.Visible = false
                for _, obj in ipairs(objects) do
                    local restMap = RestTransparencies[obj]
                    if restMap then
                        for prop, val in pairs(restMap) do
                            obj[prop] = val
                        end
                    end
                    ActiveFading[obj] = nil
                end
                if Callback then Callback() end
            end

            if tweenInfo.Time <= 0.005 then
                finalizeHide()
            else
                task.delay(tweenInfo.Time, finalizeHide)
            end
        end
    end

    function Library:MakeDraggable(DragHandle, TopClamp)
        local Gui = self and self.Instance
        if not Gui then
            return
        end

        local Handle = (DragHandle and DragHandle.Instance) or DragHandle or Gui
        local Dragging = false
        local DragStart
        local StartRelPos
        local InputChangedConn

        local function updatePosition(Input)
            local pointer = getPointerPosition(Input)
            local delta = pointer - DragStart
            local parentInst = Gui.Parent
            if not parentInst then
                return
            end

            local screenSize = parentInst.AbsoluteSize
            local guiSize = Gui.AbsoluteSize
            local minY = TopClamp or 0
            local maxX = math.max(0, screenSize.X - guiSize.X)
            local maxY = math.max(minY, screenSize.Y - guiSize.Y)

            local newX = math.clamp(StartRelPos.X + delta.X, 0, maxX)
            local newY = math.clamp(StartRelPos.Y + delta.Y, minY, maxY)

            Gui.Position = UDim2.fromOffset(math.floor(newX + 0.5), math.floor(newY + 0.5))
        end

        Library.Connect({ Instance = Handle }, "InputBegan", function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                if Library.ActiveDragLock then
                    return
                end

                local parentInst = Gui.Parent
                if not parentInst then
                    return
                end

                Dragging = true
                DragStart = getPointerPosition(Input)

                local relPos = Gui.AbsolutePosition - parentInst.AbsolutePosition
                if Gui.AnchorPoint ~= Vector2.new(0, 0) then
                    Gui.AnchorPoint = Vector2.new(0, 0)
                    Gui.Position = UDim2.fromOffset(math.floor(relPos.X + 0.5), math.floor(relPos.Y + 0.5))
                end
                StartRelPos = relPos

                if InputChangedConn then
                    InputChangedConn:Disconnect()
                end
                InputChangedConn = Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                        if InputChangedConn then
                            InputChangedConn:Disconnect()
                            InputChangedConn = nil
                        end
                    end
                end)
            end
        end)

        Library:Connect(UserInputService.InputChanged, function(Input)
            if not Dragging then
                return
            end
            if Library.ActiveDragLock then
                Dragging = false
                return
            end
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                updatePosition(Input)
            end
        end)
    end

    function Library:MakeResizeable(Minimum, TopClamp)
        local Gui = self and self.Instance
        if not Gui then
            return
        end

        Minimum = Minimum or Vector2.new(440, 340)
        local Resizing = false
        local CurrentSide = nil
        local StartMouse = nil
        local StartPosition = nil
        local StartSize = nil
        local EdgeThickness = 4

        local function getScale()
            local uiScale = Gui:FindFirstChildOfClass("UIScale")
            return (uiScale and uiScale.Scale > 0) and uiScale.Scale or 1
        end

        local function makeEdge(Position, Size, Side)
            local Button = Library:Create("TextButton", {
                Name = "\0",
                Size = Size,
                Position = Position,
                BackgroundColor3 = Library.Theme["Accent"],
                BackgroundTransparency = 1,
                Text = "",
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Parent = Gui,
                ZIndex = 12,
            }):AddToTheme({ BackgroundColor3 = "Accent" })

            return { Button = Button, Side = Side }
        end

        local Edges = {
            makeEdge(UDim2.new(0, 0, 0, 0), UDim2.new(0, EdgeThickness, 1, 0), "L"),
            makeEdge(UDim2.new(1, -EdgeThickness, 0, 0), UDim2.new(0, EdgeThickness, 1, 0), "R"),
            makeEdge(UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, EdgeThickness), "T"),
            makeEdge(UDim2.new(0, 0, 1, -EdgeThickness), UDim2.new(1, 0, 0, EdgeThickness), "B"),
            makeEdge(UDim2.new(1, -10, 1, -10), UDim2.new(0, 10, 0, 10), "BR"),
        }

        local GripFrame = Library:Create("Frame", {
            Name = "\0",
            Parent = Gui,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -3, 1, -3),
            Size = UDim2.new(0, 6, 0, 6),
            BackgroundTransparency = 1,
            ZIndex = 11,
        })
        for i = 0, 2 do
            Library:Create("Frame", {
                Name = "\0",
                Parent = GripFrame.Instance,
                Position = UDim2.new(0, 5 - i * 2, 0, i * 2),
                Size = UDim2.new(0, 1 + i * 2, 0, 1),
                BackgroundColor3 = Library.Theme["Outline 1"],
                ZIndex = 11,
            }):AddToTheme({ BackgroundColor3 = "Outline 1" })
        end

        local function beginResize(Side, Input)
            Resizing = true
            CurrentSide = Side
            Library.ActiveDragLock = true

            if Gui.AnchorPoint ~= Vector2.new(0, 0) then
                local parentInst = Gui.Parent
                local rel = Gui.AbsolutePosition - (parentInst and parentInst.AbsolutePosition or Vector2.new(0, 0))
                Gui.AnchorPoint = Vector2.new(0, 0)
                Gui.Position = UDim2.fromOffset(math.floor(rel.X + 0.5), math.floor(rel.Y + 0.5))
            end

            local scale = getScale()
            StartMouse = getPointerPosition(Input)
            StartPosition = Vector2.new(Gui.AbsolutePosition.X - getHolderOrigin().X, Gui.AbsolutePosition.Y - getHolderOrigin().Y)
            StartSize = Gui.AbsoluteSize / scale

            for _, edge in ipairs(Edges) do
                if edge.Side ~= "BR" then
                    edge.Button.Instance.BackgroundTransparency = (edge.Side == Side) and 0.45 or 1
                end
            end
        end

        local function endResize()
            if not Resizing then
                return
            end
            Resizing = false
            CurrentSide = nil
            Library.ActiveDragLock = false
            for _, edge in ipairs(Edges) do
                edge.Button.Instance.BackgroundTransparency = 1
            end
        end

        for _, edge in ipairs(Edges) do
            edge.Button:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    beginResize(edge.Side, Input)
                end
            end)
        end

        Library:Connect(UserInputService.InputEnded, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                endResize()
            end
        end)

        Library:Connect(RunService.RenderStepped, function()
            if not Resizing or not CurrentSide then
                return
            end

            local scale = getScale()
            local vp = getViewportSize()
            local mousePos = UserInputService:GetMouseLocation()
            local dx = (mousePos.X - StartMouse.X) / scale
            local dy = (mousePos.Y - StartMouse.Y) / scale

            local x, y = StartPosition.X, StartPosition.Y
            local w, h = StartSize.X, StartSize.Y
            local minY = TopClamp or 0

            if CurrentSide == "L" then
                local newW = math.max(Minimum.X, StartSize.X - dx)
                x = StartPosition.X + (StartSize.X - newW) * scale
                if x < 0 then
                    newW = newW + x / scale
                    x = 0
                end
                w = math.max(Minimum.X, newW)
            elseif CurrentSide == "R" then
                local maxW = math.max(Minimum.X, (vp.X - x) / scale)
                w = math.clamp(StartSize.X + dx, Minimum.X, maxW)
            elseif CurrentSide == "T" then
                local newH = math.max(Minimum.Y, StartSize.Y - dy)
                y = StartPosition.Y + (StartSize.Y - newH) * scale
                if y < minY then
                    newH = newH - (minY - y) / scale
                    y = minY
                end
                h = math.max(Minimum.Y, newH)
            elseif CurrentSide == "B" then
                local maxH = math.max(Minimum.Y, (vp.Y - y) / scale)
                h = math.clamp(StartSize.Y + dy, Minimum.Y, maxH)
            elseif CurrentSide == "BR" then
                local maxW = math.max(Minimum.X, (vp.X - x) / scale)
                local maxH = math.max(Minimum.Y, (vp.Y - y) / scale)
                w = math.clamp(StartSize.X + dx, Minimum.X, maxW)
                h = math.clamp(StartSize.Y + dy, Minimum.Y, maxH)
            end

            Gui.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
            Gui.Size = UDim2.fromOffset(math.floor(w + 0.5), math.floor(h + 0.5))
        end)
    end

    function Library:IsMouseOverFrame()
        local Object = self and self.Instance
        if not Object or not Object.Visible or Object.Parent == Library.UnusedHolder.Instance then
            return false
        end

        local MousePosition = UserInputService:GetMouseLocation()
        local absPos = Object.AbsolutePosition
        local absSize = Object.AbsoluteSize

        return MousePosition.X >= absPos.X
            and MousePosition.X <= absPos.X + absSize.X
            and MousePosition.Y >= absPos.Y
            and MousePosition.Y <= absPos.Y + absSize.Y
    end

    function Library:SafeCall(Function, ...)
        if type(Function) ~= "function" then
            return false
        end
        local Arguments = { ... }
        local Success, Result = pcall(Function, table.unpack(Arguments))
        if not Success then
            warn("[UI]", Result)
            return false, Result
        end
        return true, Result
    end

    function Library:Round(Number, Step)
        if Step == nil or Step <= 0 then
            Step = 1
        end
        local Multiplier = 1 / Step
        local rounded = math.floor(Number * Multiplier + 0.5) / Multiplier
        if Step < 1 then
            local formatted = tonumber(string.format("%.6g", rounded))
            if formatted then
                rounded = formatted
            end
        end
        return rounded
    end

    function Library:GetConfig()
        local Config = {}
        local Success, Result = Library:SafeCall(function()
            for Index, Value in pairs(Library.Flags) do
                if type(Value) == "table" and Value.Key then
                    Config[Index] = { Key = tostring(Value.Key), Mode = Value.Mode }
                elseif type(Value) == "table" and Value.Color then
                    Config[Index] = { Color = "#" .. Value.HexValue, Alpha = Value.Alpha }
                else
                    Config[Index] = Value
                end
            end
        end)

        if not Success then
            warn("Failed to get config:\n" .. tostring(Result))
            return "{}"
        end

        return HttpService:JSONEncode(Config)
    end

    function Library:LoadConfig(Config)
        local okDecode, Decoded = pcall(function()
            return HttpService:JSONDecode(Config)
        end)
        if not okDecode or type(Decoded) ~= "table" then
            return false, "invalid json"
        end

        local Success, Result = Library:SafeCall(function()
            for Index, Value in pairs(Decoded) do
                local SetFunction = Library.SetFlags[Index]
                if SetFunction then
                    if type(Value) == "table" and Value.Key then
                        SetFunction(Value)
                    elseif type(Value) == "table" and Value.Color then
                        SetFunction(Value.Color, Value.Alpha)
                    else
                        SetFunction(Value)
                    end
                end
            end
        end)

        return Success, Result
    end

    function Library:GetConfigsList(Element)
        local List = safeListFiles(Library.Directory .. Library.Folders.Configs)
        local ReturnList = {}

        for _, File in ipairs(List) do
            if File:sub(-5) == ".json" then
                local fileName = File:match("([^/\\]+)%.json$")
                if fileName then
                    table.insert(ReturnList, fileName)
                end
            end
        end

        table.sort(ReturnList)
        if Element and Element.Refresh then
            Element:Refresh(ReturnList)
        end
        return ReturnList
    end

    function Library:AddToTheme(Properties)
        local Object = self.Instance
        local ThemeData = {
            Item = Object,
            Properties = Properties,
        }

        for Property, Value in pairs(ThemeData.Properties) do
            if type(Value) == "string" then
                Object[Property] = Library.Theme[Value] or Value
            elseif type(Value) == "function" then
                Object[Property] = Value()
            end
        end

        table.insert(Library.ThemingStuff, ThemeData)
        Library.ThemeMap[Object] = ThemeData
        return self
    end

    function Library:ChangeItemTheme(Properties)
        local Object = self.Instance
        if not Library.ThemeMap[Object] then
            return
        end
        Library.ThemeMap[Object].Properties = Properties
    end

    function Library:ChangeTheme(ThemeName, Color)
        Library.Theme[ThemeName] = Color

        local writeIdx = 1
        for i = 1, #Library.ThemingStuff do
            local Item = Library.ThemingStuff[i]
            if Item and Item.Item and not Library.DestroyedInstances[Item.Item] then
                for Property, Value in pairs(Item.Properties) do
                    if type(Value) == "string" and Value == ThemeName then
                        Item.Item[Property] = Color
                    elseif type(Value) == "function" then
                        Item.Item[Property] = Value()
                    end
                end
                Library.ThemingStuff[writeIdx] = Item
                writeIdx = writeIdx + 1
            elseif Item and Item.Item then
                Library.ThemeMap[Item.Item] = nil
            end
        end
        for i = writeIdx, #Library.ThemingStuff do
            Library.ThemingStuff[i] = nil
        end
    end

    function Library:ApplyThemePreset(PresetName)
        local preset = ThemePresets[PresetName]
        if not preset then
            return
        end
        for Key, Color in pairs(preset) do
            Library:ChangeTheme(Key, Color)
            if Library.SetFlags[Key] then
                Library.SetFlags[Key](Color, 0)
            end
        end
    end

    function Library:OnHover(OnHoverEnter, OnHoverLeave)
        local Object = self and self.Instance
        if not Object then
            return
        end
        Library:Connect(Object.MouseEnter, OnHoverEnter)
        Library:Connect(Object.MouseLeave, OnHoverLeave)
    end

    Library.Holder = Library:Create("ScreenGui", {
        Parent = gethui(),
        IgnoreGuiInset = true,
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false,
    })

    Library.UnusedHolder = Library:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        Enabled = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false,
    })

    Library.NotifHolder = Library:Create("Frame", {
        Name = "\0",
        Parent = Library.Holder.Instance,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 12),
        Size = UDim2.new(0, 320, 1, -24),
        BorderSizePixel = 0,
    })

    Library:Create("UIListLayout", {
        Name = "\0",
        Parent = Library.NotifHolder.Instance,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    })

    local function createHudPanel(Params)
        Params = Params or {}
        local width = Params.Width or 194
        local titleText = Params.Title or "panel"
        local position = Params.Position or UDim2.new(0, 20, 0.5, 0)
        local itemsKey = Params.ItemsKey or "Panel"

        local Items = {}
        Items[itemsKey] = Library:Create("Frame", {
            Name = "\0",
            Parent = Library.Holder.Instance,
            Position = position,
            Size = UDim2.new(0, width, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Library.Theme["Background"],
        }):AddToTheme({ BackgroundColor3 = "Background" })

        Items[itemsKey]:MakeDraggable()

        Library:AddBorderStrokes(Items[itemsKey], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
            { Theme = "Outline 2", Offset = 2 },
            { Theme = "Outline 4", Offset = 3 },
        })

        Items["AccentLine"] = Library:AddAccentHairline(Items[itemsKey], 3)

        Items["Title"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items[itemsKey].Instance,
            Position = UDim2.new(0, 0, 0, 1),
            Size = UDim2.new(1, 0, 0, 19),
            BackgroundColor3 = Library.Theme["Inline"],
        }):AddToTheme({ BackgroundColor3 = "Inline" })
        Library:AddSurfaceShade(Items["Title"], Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 220, 226))

        Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Title"].Instance,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Library.Theme["Outline 1"],
        }):AddToTheme({ BackgroundColor3 = "Outline 1" })

        Items["Text"] = Library:Create("TextLabel", {
            Name = "\0",
            FontFace = Library.BoldFont,
            TextSize = Library.FontSize,
            Parent = Items["Title"].Instance,
            RichText = true,
            TextColor3 = Library.Theme["Text"],
            Text = titleText,
            TextXAlignment = Enum.TextXAlignment.Left,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 7, 0.5, 0),
            Size = UDim2.new(1, -46, 0, 14),
            BackgroundTransparency = 1,
        }):AddToTheme({ TextColor3 = "Text" })
        Library:AddTextStroke(Items["Text"])

        Items["Badge"] = Library:Create("TextLabel", {
            Name = "\0",
            FontFace = Library.Font,
            TextSize = Library.FontSize - 1,
            Parent = Items["Title"].Instance,
            RichText = true,
            TextColor3 = Library.Theme["Inactive Text"],
            Text = "",
            TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -7, 0.5, 0),
            Size = UDim2.new(0, 40, 0, 14),
            BackgroundTransparency = 1,
        }):AddToTheme({ TextColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["Badge"])

        Items["Content"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items[itemsKey].Instance,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 20),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        })

        Library:Create("UIPadding", {
            Name = "\0",
            Parent = Items["Content"].Instance,
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 7),
            PaddingRight = UDim.new(0, 7),
        })

        Library:Create("UIListLayout", {
            Name = "\0",
            Parent = Items["Content"].Instance,
            Padding = UDim.new(0, 3),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        return Items
    end

    function Library:CreateColorpicker(Data)
        local Colorpicker = {
            Hue = 0,
            Saturation = 0,
            Value = 1,
            Alpha = Data.Alpha or 0,

            Color = Color3.fromRGB(255, 255, 255),
            HexValue = "FFFFFF",

            Flag = Data.Flag,
            IsOpen = false,
            Items = {},
        }

        local Items = {}
        Items["ColorpickerButton"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Data.Parent.Instance,
            Text = "",
            Size = UDim2.new(0, 18, 0, 9),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })
        Library:AddSurfaceShade(Items["ColorpickerButton"], Color3.fromRGB(255, 255, 255), Color3.fromRGB(200, 200, 205))

        Items["ButtonCheckers"] = Library:Create("ImageLabel", {
            Name = "\0",
            Parent = Items["ColorpickerButton"].Instance,
            ScaleType = Enum.ScaleType.Tile,
            TileSize = UDim2.new(0, 5, 0, 5),
            Image = "http://www.roblox.com/asset/?id=18274452449",
            BackgroundTransparency = 1,
            ImageTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
        })

        Library:AddBorderStrokes(Items["ColorpickerButton"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        })

        Items["ColorpickerWindow"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Library.UnusedHolder.Instance,
            Visible = false,
            Text = "",
            Position = UDim2.new(0, 400, 0, 200),
            Size = UDim2.new(0, 204, 0, 198),
            BackgroundColor3 = Library.Theme["Background"],
        }):AddToTheme({ BackgroundColor3 = "Background" })

        Library:AddBorderStrokes(Items["ColorpickerWindow"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
            { Theme = "Outline 2", Offset = 2 },
        })

        Items["Hue"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Items["ColorpickerWindow"].Instance,
            Text = "",
            Position = UDim2.new(0, 7, 0, 7),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(0, 12, 0, 140),
        })

        Library:AddBorderStrokes(Items["Hue"], {
            { Theme = "Outline 1", Offset = 0 },
        })

        Library:Create("UIGradient", {
            Name = "\0",
            Parent = Items["Hue"].Instance,
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            }),
        })

        Items["HueDragger"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Hue"].Instance,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(1, 0, 0, 2),
        })
        Items["HueDragger"].Instance:SetAttribute("ZOffset", 2)
        Library:Create("UIStroke", {
            Name = "\0",
            Parent = Items["HueDragger"].Instance,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            LineJoinMode = Enum.LineJoinMode.Miter,
            Color = Color3.fromRGB(6, 7, 7),
        })

        Items["Palette"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Items["ColorpickerWindow"].Instance,
            Text = "",
            Position = UDim2.new(0, 26, 0, 7),
            Size = UDim2.new(1, -33, 0, 140),
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        })

        Library:AddBorderStrokes(Items["Palette"], {
            { Theme = "Outline 1", Offset = 0 },
        })

        Items["Saturation"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Palette"].Instance,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })
        Items["Saturation"].Instance:SetAttribute("ZOffset", 1)
        Library:Create("UIGradient", {
            Name = "\0",
            Parent = Items["Saturation"].Instance,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
        })

        Items["Value"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Palette"].Instance,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        })
        Items["Value"].Instance:SetAttribute("ZOffset", 2)
        Library:Create("UIGradient", {
            Name = "\0",
            Parent = Items["Value"].Instance,
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
        })

        Items["PaletteDragger"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Palette"].Instance,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 5, 0, 5),
            BackgroundTransparency = 1,
        })
        Items["PaletteDragger"].Instance:SetAttribute("ZOffset", 3)
        Library:Create("UIStroke", {
            Name = "\0",
            Parent = Items["PaletteDragger"].Instance,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            LineJoinMode = Enum.LineJoinMode.Miter,
            Color = Color3.fromRGB(255, 255, 255),
        })

        Items["CurrentColor"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["ColorpickerWindow"].Instance,
            Position = UDim2.new(0, 7, 0, 154),
            Size = UDim2.new(0, 12, 0, 12),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })
        Library:AddBorderStrokes(Items["CurrentColor"], {
            { Theme = "Outline 1", Offset = 0 },
        })

        Items["Checkers"] = Library:Create("ImageLabel", {
            Name = "\0",
            Parent = Items["CurrentColor"].Instance,
            ScaleType = Enum.ScaleType.Tile,
            ImageTransparency = 1,
            TileSize = UDim2.new(0, 6, 0, 6),
            Image = "http://www.roblox.com/asset/?id=18274452449",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
        })
        Items["Checkers"].Instance:SetAttribute("ZOffset", 1)

        Items["Alpha"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Items["ColorpickerWindow"].Instance,
            Text = "",
            Position = UDim2.new(0, 26, 0, 154),
            Size = UDim2.new(1, -33, 0, 12),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })
        Library:AddBorderStrokes(Items["Alpha"], {
            { Theme = "Outline 1", Offset = 0 },
        })

        Items["CheckersAlpha"] = Library:Create("ImageLabel", {
            Name = "\0",
            Parent = Items["Alpha"].Instance,
            ScaleType = Enum.ScaleType.Tile,
            TileSize = UDim2.new(0, 6, 0, 6),
            Image = "http://www.roblox.com/asset/?id=18274452449",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
        })
        Items["CheckersAlpha"].Instance:SetAttribute("ZOffset", 1)
        Library:Create("UIGradient", {
            Name = "\0",
            Parent = Items["CheckersAlpha"].Instance,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
        })

        Items["AlphaDragger"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Alpha"].Instance,
            Size = UDim2.new(0, 2, 1, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        })
        Items["AlphaDragger"].Instance:SetAttribute("ZOffset", 2)
        Library:Create("UIStroke", {
            Name = "\0",
            Parent = Items["AlphaDragger"].Instance,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            LineJoinMode = Enum.LineJoinMode.Miter,
            Color = Color3.fromRGB(6, 7, 7),
        })

        Items["HexBox"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["ColorpickerWindow"].Instance,
            Position = UDim2.new(0, 7, 0, 173),
            Size = UDim2.new(1, -14, 0, 18),
            BackgroundColor3 = Library.Theme["Content"],
        }):AddToTheme({ BackgroundColor3 = "Content" })
        Library:AddBorderStrokes(Items["HexBox"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        })

        Items["HexInput"] = Library:Create("TextBox", {
            Name = "\0",
            Parent = Items["HexBox"].Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -56, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            Text = "#FFFFFF",
            PlaceholderText = "#RRGGBB",
            PlaceholderColor3 = Library.Theme["Inactive Text"],
            TextColor3 = Library.Theme["Text"],
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
        }):AddToTheme({ TextColor3 = "Text", PlaceholderColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["HexInput"])

        Items["AlphaReadout"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["HexBox"].Instance,
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -6, 0, 0),
            Size = UDim2.new(0, 44, 1, 0),
            Text = "0%",
            TextColor3 = Library.Theme["Inactive Text"],
            TextXAlignment = Enum.TextXAlignment.Right,
        }):AddToTheme({ TextColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["AlphaReadout"])

        Colorpicker.Items = Items
        Colorpicker.Holder = Items["ColorpickerWindow"]

        function Colorpicker:SetVisibility(Bool)
            Items["ColorpickerButton"].Instance.Visible = Bool
        end

        function Colorpicker:Update(IsFromAlpha)
            local Hue, Saturation, Value = Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value
            Colorpicker.Color = Color3.fromHSV(Hue, Saturation, Value)
            Colorpicker.HexValue = Colorpicker.Color:ToHex()

            Items["ColorpickerButton"].Instance.BackgroundColor3 = Colorpicker.Color
            local btnCheckerTrans = 1 - Colorpicker.Alpha * 0.5
            Items["ButtonCheckers"].Instance.ImageTransparency = btnCheckerTrans
            setRestTransparency(Items["ButtonCheckers"].Instance, "ImageTransparency", btnCheckerTrans)
            Items["Palette"].Instance.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)

            if not IsFromAlpha then
                Items["Alpha"].Instance.BackgroundColor3 = Colorpicker.Color
            end

            Items["CurrentColor"].Instance.BackgroundColor3 = Colorpicker.Color
            local checkerTrans = 1 - Colorpicker.Alpha
            Items["Checkers"].Instance.ImageTransparency = checkerTrans
            setRestTransparency(Items["Checkers"].Instance, "ImageTransparency", checkerTrans)
            Items["AlphaReadout"].Instance.Text = math.floor(Colorpicker.Alpha * 100 + 0.5) .. "%"

            if not Items["HexInput"].Instance:IsFocused() then
                Items["HexInput"].Instance.Text = "#" .. string.upper(Colorpicker.HexValue)
            end

            Flags[Colorpicker.Flag] = {
                Alpha = Colorpicker.Alpha,
                Color = Colorpicker.Color,
                HexValue = Colorpicker.HexValue,
                Transparency = 1 - Colorpicker.Alpha,
            }

            if Data.Callback then
                Library:SafeCall(Data.Callback, Colorpicker.Color, Colorpicker.Alpha)
            end
        end

        local ColorpickerWindow = Items["ColorpickerWindow"].Instance
        local ColorpickerButton = Items["ColorpickerButton"].Instance
        local IsSettings = Data.Section and Data.Section.IsSettings
        local OpenToken = 0

        function Colorpicker:SetOpen(Bool)
            if Colorpicker.IsOpen == Bool then
                return
            end

            OpenToken = OpenToken + 1
            local token = OpenToken
            Colorpicker.IsOpen = Bool

            if Bool then
                for _, Frame in pairs(Library.OpenFrames) do
                    if Frame ~= Colorpicker and Frame ~= IsSettings then
                        Frame:SetOpen(false)
                    end
                end

                ColorpickerWindow.Parent = Library.Holder.Instance
                local x, y = placePopup(ColorpickerWindow, ColorpickerButton, 204, 198)
                ColorpickerWindow.Position = UDim2.fromOffset(x, y - 4)
                ColorpickerWindow.Visible = true
                setPopupZIndex(ColorpickerWindow, Library.ZIndexOrder.ColorpickerWindow + (IsSettings and 5 or 0))

                Items["ColorpickerWindow"]:Tween({ Position = UDim2.fromOffset(x, y) })
                Items["ColorpickerWindow"]:FadeDescendants(true)

                Library.OpenFrames[Colorpicker] = Colorpicker
            else
                Library.OpenFrames[Colorpicker] = nil
                local curPos = ColorpickerWindow.Position
                Items["ColorpickerWindow"]:Tween({ Position = UDim2.fromOffset(curPos.X.Offset, curPos.Y.Offset - 4) })
                Items["ColorpickerWindow"]:FadeDescendants(false, function()
                    if OpenToken == token then
                        ColorpickerWindow.Parent = Library.UnusedHolder.Instance
                    end
                end)
            end
        end

        local SlidingPalette = false
        local SlidingHue = false
        local SlidingAlpha = false

        function Colorpicker:SlidePalette(Input)
            local pal = Items["Palette"].Instance
            local pos = getPointerPosition(Input)
            local rx = math.clamp((pos.X - pal.AbsolutePosition.X) / math.max(1, pal.AbsoluteSize.X), 0, 1)
            local ry = math.clamp((pos.Y - pal.AbsolutePosition.Y) / math.max(1, pal.AbsoluteSize.Y), 0, 1)

            Colorpicker.Saturation = 1 - rx
            Colorpicker.Value = 1 - ry

            Items["PaletteDragger"].Instance.Position = UDim2.new(rx, 0, ry, 0)
            Colorpicker:Update()
        end

        function Colorpicker:SlideHue(Input)
            local hue = Items["Hue"].Instance
            local pos = getPointerPosition(Input)
            local ry = math.clamp((pos.Y - hue.AbsolutePosition.Y) / math.max(1, hue.AbsoluteSize.Y), 0, 1)

            Colorpicker.Hue = ry
            Items["HueDragger"].Instance.Position = UDim2.new(0, 0, math.clamp(ry, 0, 0.985), 0)
            Colorpicker:Update()
        end

        function Colorpicker:SlideAlpha(Input)
            local alpha = Items["Alpha"].Instance
            local pos = getPointerPosition(Input)
            local rx = math.clamp((pos.X - alpha.AbsolutePosition.X) / math.max(1, alpha.AbsoluteSize.X), 0, 1)

            Colorpicker.Alpha = rx
            Items["AlphaDragger"].Instance.Position = UDim2.new(math.clamp(rx, 0, 0.985), 0, 0, 0)
            Colorpicker:Update(true)
        end

        function Colorpicker:Set(Color, Alpha)
            if type(Color) == "table" then
                Color = Color3.fromRGB(Color[1] or 255, Color[2] or 255, Color[3] or 255)
            elseif type(Color) == "string" then
                local ok, parsed = pcall(Color3.fromHex, Color)
                Color = ok and parsed or Color3.fromRGB(255, 255, 255)
            elseif typeof(Color) ~= "Color3" then
                Color = Color3.fromRGB(255, 255, 255)
            end

            Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value = Color:ToHSV()
            Colorpicker.Alpha = math.clamp(tonumber(Alpha) or 0, 0, 1)

            Items["PaletteDragger"].Instance.Position = UDim2.new(math.clamp(1 - Colorpicker.Saturation, 0, 1), 0, math.clamp(1 - Colorpicker.Value, 0, 1), 0)
            Items["HueDragger"].Instance.Position = UDim2.new(0, 0, math.clamp(Colorpicker.Hue, 0, 0.985), 0)
            Items["AlphaDragger"].Instance.Position = UDim2.new(math.clamp(Colorpicker.Alpha, 0, 0.985), 0, 0, 0)

            Colorpicker:Update()
        end

        Items["HexInput"]:Connect("FocusLost", function(Enter)
            if Enter then
                local ok, parsed = pcall(Color3.fromHex, Items["HexInput"].Instance.Text)
                if ok and parsed then
                    Colorpicker:Set(parsed, Colorpicker.Alpha)
                else
                    Items["HexInput"].Instance.Text = "#" .. string.upper(Colorpicker.HexValue)
                end
            else
                Items["HexInput"].Instance.Text = "#" .. string.upper(Colorpicker.HexValue)
            end
        end)

        Items["ColorpickerButton"]:Connect("MouseButton1Down", function()
            Colorpicker:SetOpen(not Colorpicker.IsOpen)
        end)

        local function bindSliderDrag(ItemObj, FlagSetter, SlideMethod)
            ItemObj:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Library.ActiveDragLock = true
                    FlagSetter(true)
                    SlideMethod(Colorpicker, Input)

                    local conn
                    conn = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            FlagSetter(false)
                            Library.ActiveDragLock = false
                            if conn then
                                conn:Disconnect()
                                conn = nil
                            end
                        end
                    end)
                end
            end)
        end

        bindSliderDrag(Items["Palette"], function(v) SlidingPalette = v end, Colorpicker.SlidePalette)
        bindSliderDrag(Items["Hue"], function(v) SlidingHue = v end, Colorpicker.SlideHue)
        bindSliderDrag(Items["Alpha"], function(v) SlidingAlpha = v end, Colorpicker.SlideAlpha)

        Library:Connect(UserInputService.InputChanged, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                if SlidingPalette then
                    Colorpicker:SlidePalette(Input)
                end
                if SlidingHue then
                    Colorpicker:SlideHue(Input)
                end
                if SlidingAlpha then
                    Colorpicker:SlideAlpha(Input)
                end
            end
        end)

        Library:Connect(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                if Colorpicker.IsOpen and not Items["ColorpickerWindow"]:IsMouseOverFrame() and not Items["ColorpickerButton"]:IsMouseOverFrame() then
                    Colorpicker:SetOpen(false)
                end
            end
        end)

        if Data.Default then
            Colorpicker:Set(Data.Default, Data.Alpha)
        else
            Colorpicker:Set(Color3.fromRGB(255, 255, 255), Data.Alpha)
        end

        SetFlags[Colorpicker.Flag] = function(Value, Alpha)
            Colorpicker:Set(Value, Alpha)
        end

        return Colorpicker, Items
    end

    function Library:CreateKeybind(Data)
        local Keybind = {
            Flag = Data.Flag,
            IsOpen = false,

            Key = "None",
            Mode = Data.Mode or "Toggle",
            Value = "None",

            Toggled = false,
            Picking = false,
            ShowInList = Data.ShowInList ~= false,
            Items = {},
        }

        local Items = {}
        Items["KeyButton"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Data.Parent.Instance,
            TextColor3 = Library.Theme["Inactive Text"],
            Text = "[None]",
            TextSize = Library.FontSize - 1,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Right,
            AutomaticSize = Enum.AutomaticSize.X,
        }):AddToTheme({ TextColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["KeyButton"])

        Items["KeyButton"]:OnHover(function()
            if not Keybind.Picking then
                Items["KeyButton"]:Tween({ TextColor3 = Library.Theme["Text"] })
            end
        end, function()
            if not Keybind.Picking then
                Items["KeyButton"]:Tween({ TextColor3 = Library.Theme["Inactive Text"] })
            end
        end)

        Items["KeybindWindow"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Library.UnusedHolder.Instance,
            Visible = false,
            Text = "",
            Size = UDim2.new(0, 186, 0, 0),
            Position = UDim2.new(0, 500, 0, 200),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Library.Theme["Background"],
        }):AddToTheme({ BackgroundColor3 = "Background" })

        Library:AddBorderStrokes(Items["KeybindWindow"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
            { Theme = "Outline 2", Offset = 2 },
        })

        Items["PopupContent"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["KeybindWindow"].Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        })

        Library:Create("UIPadding", {
            Name = "\0",
            Parent = Items["PopupContent"].Instance,
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 7),
            PaddingLeft = UDim.new(0, 7),
        })

        Library:Create("UIListLayout", {
            Name = "\0",
            Parent = Items["PopupContent"].Instance,
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        Keybind.Items = Items
        Keybind.Holder = Items["KeybindWindow"]

        local KeybindWindow = Items["KeybindWindow"].Instance
        local KeyButton = Items["KeyButton"].Instance
        local IsSettings = Data.Section and Data.Section.IsSettings
        local OpenToken = 0

        function Keybind:SetOpen(Bool)
            if Keybind.IsOpen == Bool then
                return
            end

            OpenToken = OpenToken + 1
            local token = OpenToken
            Keybind.IsOpen = Bool

            if Bool then
                for _, Frame in pairs(Library.OpenFrames) do
                    if Frame ~= Keybind and Frame ~= IsSettings then
                        Frame:SetOpen(false)
                    end
                end

                KeybindWindow.Parent = Library.Holder.Instance
                local x, y = placePopup(KeybindWindow, KeyButton, 186, 108)
                KeybindWindow.Position = UDim2.fromOffset(x, y - 4)
                KeybindWindow.Visible = true
                setPopupZIndex(KeybindWindow, Library.ZIndexOrder.KeybindWindow + (IsSettings and 5 or 0))

                Items["KeybindWindow"]:Tween({ Position = UDim2.fromOffset(x, y) })
                Items["KeybindWindow"]:FadeDescendants(true)

                Library.OpenFrames[Keybind] = Keybind
            else
                Library.OpenFrames[Keybind] = nil
                local curPos = KeybindWindow.Position
                Items["KeybindWindow"]:Tween({ Position = UDim2.fromOffset(curPos.X.Offset, curPos.Y.Offset - 4) })
                Items["KeybindWindow"]:FadeDescendants(false, function()
                    if OpenToken == token then
                        KeybindWindow.Parent = Library.UnusedHolder.Instance
                    end
                end)
            end
        end

        local KeybindObject
        if Library.KeyList then
            KeybindObject = Library.KeyList:Add(Data.Name or Keybind.Flag, Keybind.Mode)
        end

        local function updateHudItem()
            if KeybindObject then
                KeybindObject:Set(Data.Name, Keybind.Mode)
                KeybindObject:SetStatus(Keybind.Toggled)
                if Keybind.Mode == "Hold" then
                    KeybindObject:SetMode(Keybind.Toggled and "holding" or "off")
                elseif Keybind.Mode == "Always" then
                    KeybindObject:SetMode("always")
                else
                    KeybindObject:SetMode(Keybind.Toggled and "toggled" or "off")
                end
            end
        end

        local function commitFlag()
            Flags[Keybind.Flag] = {
                Mode = Keybind.Mode,
                Key = Keybind.Key,
                Toggled = Keybind.Toggled,
            }
        end

        function Keybind:SetMode(NewMode)
            if NewMode and table.find({ "Toggle", "Hold", "Always" }, NewMode) then
                Keybind.Mode = NewMode
            end
            if Keybind.Mode == "Always" then
                Keybind.Toggled = true
            elseif Keybind.Mode == "Hold" then
                Keybind.Toggled = false
            end
            commitFlag()
            if Data.Callback then
                Library:SafeCall(Data.Callback, Keybind.Toggled)
            end
            updateHudItem()
        end

        local syncingDropdown = false
        local ModeDropdown = Library:Dropdown({
            Name = "mode",
            Flag = Keybind.Flag .. "ModeDropdown",
            Parent = Items["PopupContent"],
            Items = { "Toggle", "Hold", "Always" },
            Default = Keybind.Mode,
            Callback = function(Value)
                if syncingDropdown then
                    return
                end
                Keybind:SetMode(Value)
            end,
        })

        Library:Toggle({
            Name = "show in keybinds list",
            Flag = Data.Flag .. "ShowInKeybindsList",
            Parent = Items["PopupContent"],
            Default = Keybind.ShowInList,
            Callback = function(Value)
                Keybind.ShowInList = Value
                if KeybindObject then
                    KeybindObject:SetVis(Value)
                    updateHudItem()
                end
            end,
        })

        local SyncEnabled = true
        if Data.Toggle then
            Library:Toggle({
                Name = "require toggle",
                Flag = Data.Flag .. "Sync",
                Parent = Items["PopupContent"],
                Default = true,
                Callback = function(Value)
                    SyncEnabled = Value
                end,
            })
        end

        if KeybindObject then
            KeybindObject:SetVis(Keybind.ShowInList)
        end

        function Keybind:Press(Bool)
            if Keybind.Mode == "Toggle" then
                Keybind.Toggled = not Keybind.Toggled
            elseif Keybind.Mode == "Hold" then
                Keybind.Toggled = Bool == true
            elseif Keybind.Mode == "Always" then
                Keybind.Toggled = true
            end

            commitFlag()
            if Data.Callback then
                Library:SafeCall(Data.Callback, Keybind.Toggled)
            end
            updateHudItem()
        end

        function Keybind:Set(Key)
            if typeof(Key) == "EnumItem" or (type(Key) == "string" and string.find(Key, "^Enum%.")) then
                local strKey = tostring(Key)
                if strKey == "Enum.KeyCode.Backspace" or strKey == "Enum.KeyCode.Escape" or strKey == "Enum.KeyCode.Unknown" then
                    Keybind.Key = "None"
                    Keybind.Value = "None"
                    Keybind.Toggled = (Keybind.Mode == "Always")
                else
                    Keybind.Key = strKey
                    Keybind.Value = formatKeyDisplay(Key)
                end

                Items["KeyButton"].Instance.Text = "[" .. Keybind.Value .. "]"
                commitFlag()

                if Data.Callback then
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end
                updateHudItem()
            elseif type(Key) == "table" then
                local rawKey = Key.Key or "None"
                if rawKey == "Backspace" or rawKey == "Enum.KeyCode.Backspace" or rawKey == "Enum.KeyCode.Escape" or rawKey == "None" then
                    Keybind.Key = "None"
                    Keybind.Value = "None"
                else
                    Keybind.Key = tostring(rawKey)
                    Keybind.Value = formatKeyDisplay(rawKey)
                end

                local targetMode = Key.Mode or Keybind.Mode or "Toggle"
                if table.find({ "Toggle", "Hold", "Always" }, targetMode) then
                    Keybind.Mode = targetMode
                    syncingDropdown = true
                    ModeDropdown:Set(targetMode)
                    syncingDropdown = false
                    Keybind:SetMode(targetMode)
                end

                Items["KeyButton"].Instance.Text = "[" .. Keybind.Value .. "]"
                commitFlag()

                if Data.Callback then
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end
                updateHudItem()
            elseif table.find({ "Toggle", "Hold", "Always" }, Key) then
                syncingDropdown = true
                ModeDropdown:Set(Key)
                syncingDropdown = false
                Keybind:SetMode(Key)
            end

            Keybind.Picking = false
        end

        Items["KeyButton"]:Connect("MouseButton1Click", function()
            if Keybind.Picking then
                return
            end
            Keybind.Picking = true
            Library.IsPickingKeybind = true

            Items["KeyButton"].Instance.Text = "[...]"
            Items["KeyButton"]:Tween({ TextColor3 = Library.Theme["Accent"] })

            local InputConn
            InputConn = UserInputService.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement then
                    return
                end
                if InputConn then
                    InputConn:Disconnect()
                    InputConn = nil
                end

                if Input.UserInputType == Enum.UserInputType.Keyboard then
                    Keybind:Set(Input.KeyCode)
                else
                    Keybind:Set(Input.UserInputType)
                end

                Items["KeyButton"]:Tween({ TextColor3 = Library.Theme["Inactive Text"] })
                task.defer(function()
                    Library.IsPickingKeybind = false
                end)
            end)
        end)

        Library:Connect(UserInputService.InputBegan, function(Input, GPE)
            if Keybind.Picking then
                return
            end

            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                if Keybind.IsOpen
                    and not Items["KeybindWindow"]:IsMouseOverFrame()
                    and not ModeDropdown.Items.OptionHolder:IsMouseOverFrame()
                    and not Items["KeyButton"]:IsMouseOverFrame() then
                    Keybind:SetOpen(false)
                end
            end

            if Keybind.Value == "None" or Keybind.Key == "None" then
                return
            end

            if Data.Toggle and SyncEnabled and not Data.Toggle.Value then
                return
            end

            if not GPE then
                if tostring(Input.KeyCode) == Keybind.Key or tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.Mode == "Toggle" then
                        Keybind:Press()
                    elseif Keybind.Mode == "Hold" or Keybind.Mode == "Always" then
                        Keybind:Press(true)
                    end
                end
            end
        end)

        Library:Connect(UserInputService.InputEnded, function(Input, GPE)
            if GPE or Keybind.Picking or Keybind.Value == "None" then
                return
            end

            if tostring(Input.KeyCode) == Keybind.Key or tostring(Input.UserInputType) == Keybind.Key then
                if Keybind.Mode == "Hold" then
                    Keybind:Press(false)
                elseif Keybind.Mode == "Always" then
                    Keybind:Press(true)
                end
            end
        end)

        Items["KeyButton"]:Connect("MouseButton2Down", function()
            Keybind:SetOpen(not Keybind.IsOpen)
        end)

        if Data.Default then
            Keybind:Set({
                Mode = Data.Mode or "Toggle",
                Key = Data.Default,
            })
        else
            commitFlag()
            updateHudItem()
        end

        SetFlags[Keybind.Flag] = function(Value)
            Keybind:Set(Value)
        end

        return Keybind, Items
    end

    function Library:Watermark(Params)
        Params = Params or {}

        local Watermark = {
            Name = Params.Name or Params.name or "Watermark",
            SubName = Params.SubName or Params.subname or "SubName",
            ShowStats = Params.ShowStats ~= false,
            Items = {},
        }

        local vp = getViewportSize()
        local Items = {}

        Items["Watermark"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Library.Holder.Instance,
            Position = UDim2.new(0, math.floor(vp.X * 0.5 - 130), 0, 12),
            Size = UDim2.new(0, 0, 0, 22),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Library.Theme["Background"],
        }):AddToTheme({ BackgroundColor3 = "Background" })
        Library:AddSurfaceShade(Items["Watermark"], Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 220, 226))

        Items["Watermark"]:MakeDraggable()

        Library:AddBorderStrokes(Items["Watermark"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
            { Theme = "Outline 2", Offset = 2 },
            { Theme = "Outline 4", Offset = 3 },
        })

        Items["AccentLine"] = Library:AddAccentHairline(Items["Watermark"], 3)

        Items["Row"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Watermark"].Instance,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 1),
            Size = UDim2.new(0, 0, 1, -1),
            AutomaticSize = Enum.AutomaticSize.X,
        })

        Library:Create("UIPadding", {
            Name = "\0",
            Parent = Items["Row"].Instance,
            PaddingLeft = UDim.new(0, 9),
            PaddingRight = UDim.new(0, 9),
        })

        Library:Create("UIListLayout", {
            Name = "\0",
            Parent = Items["Row"].Instance,
            FillDirection = Enum.FillDirection.Horizontal,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 7),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        Items["Text"] = Library:Create("TextLabel", {
            Name = "\0",
            FontFace = Library.BoldFont,
            Parent = Items["Row"].Instance,
            RichText = true,
            TextColor3 = Library.Theme["Text"],
            Text = Watermark.Name,
            Size = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            LayoutOrder = 1,
        }):AddToTheme({ TextColor3 = "Text" })
        Library:AddTextStroke(Items["Text"])

        Items["Divider1"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Row"].Instance,
            Size = UDim2.new(0, 1, 0, 10),
            BackgroundColor3 = Library.Theme["Outline 1"],
            LayoutOrder = 2,
        }):AddToTheme({ BackgroundColor3 = "Outline 1" })

        Items["SubText"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["Row"].Instance,
            RichText = true,
            TextColor3 = Library.Theme["Inactive Text"],
            Text = Watermark.SubName,
            Size = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            LayoutOrder = 3,
        }):AddToTheme({ TextColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["SubText"])

        Items["Divider2"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Row"].Instance,
            Size = UDim2.new(0, 1, 0, 10),
            BackgroundColor3 = Library.Theme["Outline 1"],
            Visible = Watermark.ShowStats,
            LayoutOrder = 4,
        }):AddToTheme({ BackgroundColor3 = "Outline 1" })

        Items["StatsText"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["Row"].Instance,
            RichText = true,
            TextColor3 = Library.Theme["Inactive Text"],
            Text = '60 <font color="rgb(130,133,140)">fps</font>',
            Size = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            Visible = Watermark.ShowStats,
            LayoutOrder = 5,
        }):AddToTheme({ TextColor3 = "Text" })
        Library:AddTextStroke(Items["StatsText"])

        Watermark.Items = Items
        Library.WatermarkWidget = Watermark

        local frameCount = 0
        local lastSample = os.clock()
        Library:Connect(RunService.RenderStepped, function()
            if not Watermark.ShowStats or not Items["Watermark"].Instance.Visible then
                return
            end
            frameCount = frameCount + 1
            local now = os.clock()
            local elapsed = now - lastSample
            if elapsed >= 0.5 then
                local fps = math.floor(frameCount / elapsed + 0.5)
                frameCount = 0
                lastSample = now
                local ping = 0
                pcall(function()
                    local netStats = Stats.Network.ServerStatsItem["Data Ping"]
                    if netStats then
                        ping = math.floor(netStats:GetValue() + 0.5)
                    end
                end)
                Items["StatsText"].Instance.Text = string.format(
                    '%d <font color="rgb(130,133,140)">fps</font>  %d <font color="rgb(130,133,140)">ms</font>',
                    fps,
                    ping
                )
            end
        end)

        function Watermark:Center()
            local screen = getViewportSize()
            local w = Items["Watermark"].Instance.AbsoluteSize.X
            Items["Watermark"].Instance.AnchorPoint = Vector2.new(0, 0)
            Items["Watermark"].Instance.Position = UDim2.fromOffset(math.floor((screen.X - w) * 0.5), 12)
        end

        function Watermark:SetText(Text)
            Items["Text"].Instance.Text = tostring(Text)
        end

        function Watermark:SetSubText(Text)
            local str = tostring(Text or "")
            Items["SubText"].Instance.Text = str
            local hasSub = str ~= ""
            Items["SubText"].Instance.Visible = hasSub
            Items["Divider1"].Instance.Visible = hasSub
        end

        function Watermark:SetStatsVisible(Bool)
            Watermark.ShowStats = Bool
            Items["StatsText"].Instance.Visible = Bool
            Items["Divider2"].Instance.Visible = Bool
        end

        function Watermark:SetVisibility(Bool)
            Items["Watermark"].Instance.Visible = Bool
        end

        Watermark:SetSubText(Watermark.SubName)
        task.defer(function()
            if Items["Watermark"] and Items["Watermark"].Instance and Items["Watermark"].Instance.Parent then
                Watermark:Center()
            end
        end)

        return setmetatable(Watermark, Library)
    end

    function Library:KeybindList(Params)
        Params = Params or {}

        local KeybindList = {
            Name = Params.Name or Params.name or 'hot<font color="rgb(126, 192, 255)">keys</font>',
            EmptyText = Params.EmptyText or "none",
            HideWhenEmpty = Params.HideWhenEmpty == true,
            Items = {},
        }
        Library.KeyList = KeybindList

        local vp = getViewportSize()
        local Items = createHudPanel({
            Width = 194,
            Title = KeybindList.Name,
            Position = UDim2.fromOffset(20, math.floor(vp.Y * 0.48)),
            ItemsKey = "KeybindList",
        })

        Items["EmptyLabel"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["Content"].Instance,
            TextColor3 = Library.Theme["Inactive Text"],
            Text = KeybindList.EmptyText,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            LayoutOrder = 999,
        }):AddToTheme({ TextColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["EmptyLabel"])

        KeybindList.Items = Items
        Library.KeybindListWidget = KeybindList

        local TrackedItems = {}
        local UserVisible = true

        local function refreshCounts()
            local activeCount = 0
            for _, entry in ipairs(TrackedItems) do
                if entry.Active then
                    activeCount = activeCount + 1
                end
            end
            Items["Badge"].Instance.Text = activeCount > 0 and tostring(activeCount) or ""
            Items["EmptyLabel"].Instance.Visible = (activeCount == 0)
            if KeybindList.HideWhenEmpty then
                Items["KeybindList"].Instance.Visible = UserVisible and (activeCount > 0)
            else
                Items["KeybindList"].Instance.Visible = UserVisible
            end
        end

        function KeybindList:Center()
            local screen = getViewportSize()
            local sz = Items["KeybindList"].Instance.AbsoluteSize
            Items["KeybindList"].Instance.Position = UDim2.fromOffset(20, math.floor((screen.Y - sz.Y) * 0.5))
        end

        function KeybindList:SetText(Text)
            Items["Text"].Instance.Text = tostring(Text)
        end

        function KeybindList:SetVisibility(Bool)
            UserVisible = Bool
            refreshCounts()
        end

        function KeybindList:Add(Name, Mode)
            local NewItems = {
                Active = false,
            }

            NewItems["NewKey"] = Library:Create("Frame", {
                Name = "\0",
                Parent = Items["Content"].Instance,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Visible = false,
            })

            NewItems["Holder"] = Library:Create("Frame", {
                Name = "\0",
                Parent = NewItems["NewKey"].Instance,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
            })

            NewItems["Text"] = Library:Create("TextLabel", {
                Name = "\0",
                Parent = NewItems["Holder"].Instance,
                TextColor3 = Library.Theme["Text"],
                Text = tostring(Name or ""),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(1, -56, 0, 14),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0.5, 0),
            }):AddToTheme({ TextColor3 = "Text" })
            Library:AddTextStroke(NewItems["Text"])

            NewItems["Mode"] = Library:Create("TextLabel", {
                Name = "\0",
                Parent = NewItems["Holder"].Instance,
                TextColor3 = Library.Theme["Accent"],
                Text = tostring(Mode or ""),
                TextSize = Library.FontSize - 1,
                TextXAlignment = Enum.TextXAlignment.Right,
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0, 54, 0, 14),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, 0, 0.5, 0),
            }):AddToTheme({ TextColor3 = "Accent" })
            Library:AddTextStroke(NewItems["Mode"])

            table.insert(TrackedItems, NewItems)
            local CanBeVisible = true

            function NewItems:SetVis(Bool)
                CanBeVisible = Bool
                if not CanBeVisible then
                    NewItems.Active = false
                    NewItems["NewKey"].Instance.Visible = false
                    refreshCounts()
                end
            end

            function NewItems:SetStatus(Bool)
                local show = CanBeVisible and (Bool == true)
                NewItems.Active = show
                NewItems["NewKey"].Instance.Visible = show
                refreshCounts()
            end

            function NewItems:Set(NewName, NewMode)
                if NewName ~= nil then
                    NewItems["Text"].Instance.Text = tostring(NewName)
                end
                if NewMode ~= nil and NewMode ~= "" then
                    NewItems["Mode"].Instance.Text = string.lower(tostring(NewMode))
                end
            end

            function NewItems:SetMode(NewMode)
                NewItems["Mode"].Instance.Text = string.lower(tostring(NewMode))
            end

            refreshCounts()
            return NewItems
        end

        refreshCounts()
        return setmetatable(KeybindList, Library)
    end

    local function createHudListWidget(Params, ItemsKey)
        Params = Params or {}

        local Widget = {
            Name = Params.Name or Params.name or "list",
            EmptyText = Params.EmptyText or "none",
            Items = {},
        }

        local vp = getViewportSize()
        local Items = createHudPanel({
            Width = Params.Width or 198,
            Title = Widget.Name,
            Position = Params.Position or UDim2.fromOffset(20, math.floor(vp.Y * 0.72)),
            ItemsKey = ItemsKey,
        })

        if ItemsKey ~= "StaffList" then
            Items["StaffList"] = Items[ItemsKey]
        end

        Widget.Items = Items
        local Rows = {}

        local function updateBadge()
            local visibleCount = 0
            for _, row in ipairs(Rows) do
                local frame = rawget(row["NewStaff"], "Instance")
                if frame and frame.Visible then
                    local label = rawget(row["Text"], "Instance")
                    local txt = label and label.Text or ""
                    if txt ~= "" and txt ~= Widget.EmptyText and txt ~= "no spectators" then
                        visibleCount = visibleCount + 1
                    end
                end
            end
            Items["Badge"].Instance.Text = visibleCount > 0 and tostring(visibleCount) or ""
        end

        function Widget:Center()
            local screen = getViewportSize()
            local sz = Items[ItemsKey].Instance.AbsoluteSize
            Items[ItemsKey].Instance.Position = UDim2.fromOffset(20, math.floor(screen.Y * 0.7 - sz.Y * 0.5))
        end

        function Widget:SetText(Text)
            Items["Text"].Instance.Text = tostring(Text)
        end

        function Widget:SetVisibility(Bool)
            Items[ItemsKey].Instance.Visible = Bool
        end

        function Widget:Clear()
            for i = #Rows, 1, -1 do
                local row = Rows[i]
                local inst = row["NewStaff"] and rawget(row["NewStaff"], "Instance")
                if inst then
                    inst:Destroy()
                end
                Rows[i] = nil
            end
            updateBadge()
        end

        function Widget:Add(Name, Rank)
            local NewItems = {}

            NewItems["NewStaff"] = Library:Create("Frame", {
                Name = "\0",
                Parent = Items["Content"].Instance,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
            })

            NewItems["Text"] = Library:Create("TextLabel", {
                Name = "\0",
                Parent = NewItems["NewStaff"].Instance,
                TextColor3 = Library.Theme["Text"],
                Text = tostring(Name or ""),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(1, -70, 0, 14),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0.5, 0),
            }):AddToTheme({ TextColor3 = "Text" })
            Library:AddTextStroke(NewItems["Text"])

            NewItems["Rank"] = Library:Create("TextLabel", {
                Name = "\0",
                Parent = NewItems["NewStaff"].Instance,
                TextColor3 = Library.Theme["Inactive Text"],
                Text = tostring(Rank or ""),
                TextSize = Library.FontSize - 1,
                TextXAlignment = Enum.TextXAlignment.Right,
                AnchorPoint = Vector2.new(1, 0.5),
                Size = UDim2.new(0, 68, 0, 14),
                BackgroundTransparency = 1,
                Position = UDim2.new(1, 0, 0.5, 0),
            }):AddToTheme({ TextColor3 = "Inactive Text" })
            Library:AddTextStroke(NewItems["Rank"])

            Library:Connect(NewItems["NewStaff"].Instance:GetPropertyChangedSignal("Visible"), updateBadge)

            function NewItems:Set(NewName)
                NewItems["Text"].Instance.Text = tostring(NewName or "")
                updateBadge()
            end

            function NewItems:SetRank(NewRank)
                NewItems["Rank"].Instance.Text = tostring(NewRank or "")
            end

            function NewItems:SetMode(NewMode)
                NewItems:SetRank(NewMode)
            end

            function NewItems:SetVisibility(Bool)
                NewItems["NewStaff"].Instance.Visible = Bool
                updateBadge()
            end

            table.insert(Rows, NewItems)
            updateBadge()
            return NewItems
        end

        function Widget:SetEntries(Entries)
            Entries = Entries or {}
            if #Entries == 0 then
                if #Rows == 0 then
                    Widget:Add(Widget.EmptyText, "")
                else
                    Rows[1]:SetVisibility(true)
                    Rows[1]:Set(Widget.EmptyText)
                    Rows[1]:SetRank("")
                    for i = 2, #Rows do
                        Rows[i]:SetVisibility(false)
                    end
                end
                updateBadge()
                return
            end

            for i, entry in ipairs(Entries) do
                local name = type(entry) == "table" and (entry.Name or entry[1]) or tostring(entry)
                local mode = type(entry) == "table" and (entry.Mode or entry.Rank or entry[2] or "") or ""
                if not Rows[i] then
                    Widget:Add(name, mode)
                else
                    Rows[i]:SetVisibility(true)
                    Rows[i]:Set(name)
                    Rows[i]:SetRank(mode)
                end
            end

            for i = #Entries + 1, #Rows do
                Rows[i]:SetVisibility(false)
            end
            updateBadge()
        end

        Widget.SetSpectators = Widget.SetEntries
        return setmetatable(Widget, Library)
    end

    function Library:StaffList(Params)
        Params = Params or {}
        Params.Name = Params.Name or Params.name or 'staff<font color="rgb(126, 192, 255)"> list</font>'
        return createHudListWidget(Params, "StaffList")
    end

    function Library:SpectatorList(Params)
        Params = Params or {}
        Params.Name = Params.Name or Params.name or 'specta<font color="rgb(126, 192, 255)">tors</font>'
        Params.EmptyText = Params.EmptyText or "no spectators"
        return createHudListWidget(Params, "SpectatorList")
    end

    function Library:TargetIndicator(Params)
        Params = Params or {}

        local Indicator = {
            Name = Params.Name or Params.name or 'target<font color="rgb(126, 192, 255)"> info</font>',
            Items = {},
        }

        local vp = getViewportSize()
        local Items = createHudPanel({
            Width = 244,
            Title = Indicator.Name,
            Position = UDim2.fromOffset(math.floor(vp.X * 0.68), math.floor(vp.Y * 0.58)),
            ItemsKey = "TargetIndicator",
        })

        Items["Status"] = Items["Badge"]
        Items["Status"].Instance.Size = UDim2.new(0, 84, 0, 14)
        Items["Status"].Instance.Text = "idle"

        Items["Main"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Content"].Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 50),
        })

        Items["AvatarFrame"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Main"].Instance,
            Size = UDim2.new(0, 48, 0, 48),
            BackgroundColor3 = Library.Theme["Content"],
        }):AddToTheme({ BackgroundColor3 = "Content" })
        Library:AddBorderStrokes(Items["AvatarFrame"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        })

        Items["Avatar"] = Library:Create("ImageLabel", {
            Name = "\0",
            Parent = Items["AvatarFrame"].Instance,
            Image = "rbxassetid://125055486069298",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
        })

        Items["Other"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Main"].Instance,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 57, 0, 0),
            Size = UDim2.new(1, -57, 1, 0),
        })

        Library:Create("UIListLayout", {
            Name = "\0",
            Parent = Items["Other"].Instance,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        Items["Name"] = Library:Create("TextLabel", {
            Name = "\0",
            FontFace = Library.BoldFont,
            Parent = Items["Other"].Instance,
            TextColor3 = Library.Theme["Text"],
            Text = "none",
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
        }):AddToTheme({ TextColor3 = "Text" })
        Library:AddTextStroke(Items["Name"])

        Items["Healthbar"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Other"].Instance,
            Size = UDim2.new(1, 0, 0, 5),
            BackgroundColor3 = Library.Theme["Outline 4"],
        }):AddToTheme({ BackgroundColor3 = "Outline 4" })
        Library:AddBorderStrokes(Items["Healthbar"], {
            { Theme = "Outline 1", Offset = 0 },
        })

        Items["Fill"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Healthbar"].Instance,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(98, 216, 148),
        })
        Library:AddSurfaceShade(Items["Fill"], Color3.fromRGB(255, 255, 255), Color3.fromRGB(185, 185, 195))

        Items["MetaRow"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Other"].Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
        })

        Items["HealthText"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["MetaRow"].Instance,
            TextColor3 = Library.Theme["Inactive Text"],
            Text = "100 / 100",
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.55, 0, 1, 0),
        }):AddToTheme({ TextColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["HealthText"])

        Items["Distance"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["MetaRow"].Instance,
            TextColor3 = Library.Theme["Inactive Text"],
            Text = "0 st",
            TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            Size = UDim2.new(0.45, 0, 1, 0),
        }):AddToTheme({ TextColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["Distance"])

        Items["Backpack"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Content"].Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = false,
        })

        Library:Create("UIGridLayout", {
            Name = "\0",
            Parent = Items["Backpack"].Instance,
            SortOrder = Enum.SortOrder.LayoutOrder,
            CellSize = UDim2.new(0, 41, 0, 41),
            CellPadding = UDim2.new(0, 5, 0, 5),
        })

        Indicator.Items = Items
        Library.TargetIndicatorList = Library.TargetIndicatorList or {}
        table.insert(Library.TargetIndicatorList, Indicator)

        function Indicator:Center()
            local screen = getViewportSize()
            Items["TargetIndicator"].Instance.Position = UDim2.fromOffset(math.floor(screen.X * 0.68), math.floor(screen.Y * 0.58))
        end

        function Indicator:SetText(Text)
            Items["Text"].Instance.Text = tostring(Text)
        end

        function Indicator:SetVisibility(Bool)
            Items["TargetIndicator"].Instance.Visible = Bool
        end

        function Indicator:SetStatus(Text, Color)
            if typeof(Color) == "Color3" then
                Items["Status"].Instance.Text = string.format(
                    '<font color="rgb(%d,%d,%d)">%s</font>',
                    math.floor(Color.R * 255),
                    math.floor(Color.G * 255),
                    math.floor(Color.B * 255),
                    tostring(Text)
                )
            else
                Items["Status"].Instance.Text = tostring(Text)
            end
        end

        local HealthConnection = nil
        local DistanceConnection = nil
        local TargetGen = 0

        function Indicator:ResetConnection()
            if HealthConnection then
                HealthConnection:Disconnect()
                HealthConnection = nil
            end
            if DistanceConnection then
                DistanceConnection:Disconnect()
                DistanceConnection = nil
            end
        end

        function Indicator:SetTarget(Target)
            TargetGen = TargetGen + 1
            local currentGen = TargetGen
            Indicator:ResetConnection()

            if not Target then
                Items["Name"].Instance.Text = "none"
                Items["Avatar"].Instance.Image = "rbxassetid://125055486069298"
                Items["HealthText"].Instance.Text = "0 / 0"
                Items["Distance"].Instance.Text = "0 st"
                Items["Fill"]:Tween({ Size = UDim2.new(0, 0, 1, 0) })
                Indicator:SetStatus("idle")
                return
            end

            Items["Name"].Instance.Text = Target.Name
            Indicator:SetStatus("locked", Library.Theme["Accent"])

            task.spawn(function()
                local ok, thumb = pcall(function()
                    return Players:GetUserThumbnailAsync(Target.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                end)
                if ok and thumb and TargetGen == currentGen then
                    Items["Avatar"].Instance.Image = thumb
                end
            end)

            local function updateHealth(Health)
                local char = Target.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local maxHealth = (hum and hum.MaxHealth > 0) and hum.MaxHealth or 100
                Health = math.clamp(Health or 0, 0, maxHealth)
                local alpha = math.clamp(Health / maxHealth, 0, 1)

                Items["HealthText"].Instance.Text = string.format("%d / %d", math.floor(Health), math.floor(maxHealth))
                local hpColor = Color3.fromRGB(235, 88, 92):Lerp(Color3.fromRGB(98, 216, 148), alpha)
                Items["Fill"]:Tween({ Size = UDim2.new(alpha, 0, 1, 0), BackgroundColor3 = hpColor })
            end

            local char = Target.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                updateHealth(hum.Health)
                HealthConnection = hum.HealthChanged:Connect(updateHealth)
                table.insert(Library.Connections, HealthConnection)
            else
                updateHealth(0)
            end

            DistanceConnection = RunService.RenderStepped:Connect(function()
                if TargetGen ~= currentGen or not Target or not Target.Parent then
                    Indicator:ResetConnection()
                    return
                end
                local tChar = Target.Character
                local tRoot = tChar and tChar:FindFirstChild("HumanoidRootPart")
                local lChar = LocalPlayer and LocalPlayer.Character
                local lRoot = lChar and lChar:FindFirstChild("HumanoidRootPart")
                if tRoot and lRoot then
                    local dist = math.floor((lRoot.Position - tRoot.Position).Magnitude)
                    Items["Distance"].Instance.Text = dist .. " st"
                end
            end)
            table.insert(Library.Connections, DistanceConnection)
        end

        function Indicator:ClearItems()
            for _, child in ipairs(Items["Backpack"].Instance:GetChildren()) do
                if child:IsA("ImageLabel") then
                    child:Destroy()
                end
            end
            Items["Backpack"].Instance.Visible = false
        end

        function Indicator:AddItem(Icon)
            Items["Backpack"].Instance.Visible = true
            local itemImg = Library:Create("ImageLabel", {
                Name = "\0",
                Parent = Items["Backpack"].Instance,
                Image = Icon,
                BackgroundColor3 = Library.Theme["Content"],
                BackgroundTransparency = 0,
            }):AddToTheme({ BackgroundColor3 = "Content" })
            Library:AddBorderStrokes(itemImg, {
                { Theme = "Outline 1", Offset = 0 },
            })
            return itemImg
        end

        return setmetatable(Indicator, Library)
    end

    function Library:Notification(Params)
        Params = Params or {}
        local duration = tonumber(Params.Time or Params.Duration) or 4
        local message = tostring(Params.Name or Params.Text or "notification")
        local accentColor = Params.Color or Library.Theme["Accent"]

        local Items = {}
        Items["Notification"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Library.NotifHolder.Instance,
            Size = UDim2.new(0, 0, 0, 23),
            ClipsDescendants = true,
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Library.Theme["Background"],
            BackgroundTransparency = 1,
            ZIndex = Library.ZIndexOrder.Notification,
        }):AddToTheme({ BackgroundColor3 = "Background" })
        Library:AddSurfaceShade(Items["Notification"], Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 220, 226))

        Items["Stroke1"] = Library:Create("UIStroke", {
            Name = "\0",
            Parent = Items["Notification"].Instance,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            LineJoinMode = Enum.LineJoinMode.Miter,
            Color = Library.Theme["Outline 1"],
            Transparency = 1,
        }):AddToTheme({ Color = "Outline 1" })

        Items["Stroke2"] = Library:Create("UIStroke", {
            Name = "\0",
            Parent = Items["Notification"].Instance,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            LineJoinMode = Enum.LineJoinMode.Miter,
            Color = Library.Theme["Outline 3"],
            BorderOffset = UDim.new(0, 1),
            Transparency = 1,
        }):AddToTheme({ Color = "Outline 3" })

        Items["Progress"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Notification"].Instance,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = accentColor,
            BackgroundTransparency = 1,
            ZIndex = Library.ZIndexOrder.Notification + 1,
        })
        if not Params.Color then
            Items["Progress"]:AddToTheme({ BackgroundColor3 = "Accent" })
        end

        Items["Text"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["Notification"].Instance,
            RichText = true,
            TextColor3 = Library.Theme["Text"],
            Text = message,
            TextTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0.5, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            ZIndex = Library.ZIndexOrder.Notification + 1,
        }):AddToTheme({ TextColor3 = "Text" })

        Items["TextStroke"] = Library:Create("UIStroke", {
            Name = "\0",
            Parent = Items["Text"].Instance,
            Transparency = 1,
        })

        Library:Create("UIPadding", {
            Name = "\0",
            Parent = Items["Notification"].Instance,
            PaddingRight = UDim.new(0, 9),
        })

        local fadeInInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local fadeOutInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

        Items["Notification"]:Tween({ BackgroundTransparency = 0 }, fadeInInfo)
        Items["Stroke1"]:Tween({ Transparency = 0 }, fadeInInfo)
        Items["Stroke2"]:Tween({ Transparency = 0 }, fadeInInfo)
        Items["Progress"]:Tween({ BackgroundTransparency = 0 }, fadeInInfo)
        Items["Text"]:Tween({ TextTransparency = 0 }, fadeInInfo)
        Items["TextStroke"]:Tween({ Transparency = 0.15 }, fadeInInfo)

        Items["Progress"]:Tween(
            { Size = UDim2.new(0, 0, 0, 1) },
            TweenInfo.new(math.max(0.2, duration), Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
        )

        task.delay(duration, function()
            if not Items["Notification"].Instance or not Items["Notification"].Instance.Parent then
                return
            end
            Items["Notification"]:Tween({ BackgroundTransparency = 1 }, fadeOutInfo)
            Items["Stroke1"]:Tween({ Transparency = 1 }, fadeOutInfo)
            Items["Stroke2"]:Tween({ Transparency = 1 }, fadeOutInfo)
            Items["Progress"]:Tween({ BackgroundTransparency = 1 }, fadeOutInfo)
            Items["Text"]:Tween({ TextTransparency = 1 }, fadeOutInfo)
            Items["TextStroke"]:Tween({ Transparency = 1 }, fadeOutInfo)
            task.delay(0.24, function()
                if Items["Notification"].Instance then
                    Items["Notification"].Instance:Destroy()
                end
            end)
        end)
    end

    function Library:Window(Params)
        Params = Params or {}

        local initialSize = Params.Size or Vector2.new(540, 455)
        local vp = getViewportSize()

        local Window = {
            Name = Params.Name or Params.name or "Window",
            IsOpen = true,
            Pages = {},
            Items = {},
        }

        local Items = {}
        Items["MainFrame"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Library.Holder.Instance,
            Position = UDim2.fromOffset(
                math.max(12, math.floor((vp.X - initialSize.X) * 0.5)),
                math.max(32, math.floor((vp.Y - initialSize.Y) * 0.5))
            ),
            Size = UDim2.fromOffset(initialSize.X, initialSize.Y),
            BackgroundColor3 = Library.Theme["Background"],
        }):AddToTheme({ BackgroundColor3 = "Background" })
        Library:AddSurfaceShade(Items["MainFrame"], Color3.fromRGB(255, 255, 255), Color3.fromRGB(224, 224, 230))

        if IsMobile then
            Library.WindowScale = Library:Create("UIScale", {
                Parent = Items["MainFrame"].Instance,
                Scale = 0.72,
            })
        else
            Library.WindowScale = Library:Create("UIScale", {
                Parent = Items["MainFrame"].Instance,
                Scale = Library.Scale,
            })
        end

        Items["MainFrame"]:MakeDraggable(nil, 24)
        Items["MainFrame"]:MakeResizeable(Vector2.new(440, 340), 24)

        Library:AddBorderStrokes(Items["MainFrame"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
            { Theme = "Outline 2", Offset = 2 },
            { Theme = "Outline 4", Offset = 3 },
        })

        Items["TopAccent"] = Library:AddAccentHairline(Items["MainFrame"], 4)

        Items["Pages"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["MainFrame"].Instance,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(1, -16, 0, 21),
        })

        Library:Create("UIListLayout", {
            Name = "\0",
            Parent = Items["Pages"].Instance,
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 3),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        Items["Content"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["MainFrame"].Instance,
            Position = UDim2.new(0, 8, 0, 29),
            Size = UDim2.new(1, -16, 1, -37),
            BackgroundColor3 = Library.Theme["Content"],
        }):AddToTheme({ BackgroundColor3 = "Content" })

        Library:AddBorderStrokes(Items["Content"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
            { Theme = "Outline 2", Offset = 2 },
        })

        Items["Title"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["MainFrame"].Instance,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 20),
            ZIndex = 1,
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Library.Theme["Background"],
        }):AddToTheme({ BackgroundColor3 = "Background" })

        Library:AddBorderStrokes(Items["Title"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        })

        Items["_"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Title"].Instance,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 1),
            Size = UDim2.new(1, 0, 0, 2),
            BackgroundColor3 = Library.Theme["Background"],
            ZIndex = 3,
        }):AddToTheme({ BackgroundColor3 = "Background" })

        Items["ActualTitle"] = Library:Create("TextLabel", {
            Name = "\0",
            FontFace = Library.BoldFont,
            Parent = Items["Title"].Instance,
            RichText = true,
            TextColor3 = Library.Theme["Text"],
            Text = Window.Name,
            Size = UDim2.new(0, 0, 0, 14),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0.5, 0),
            AutomaticSize = Enum.AutomaticSize.X,
            ZIndex = 2,
        }):AddToTheme({ TextColor3 = "Text" })
        Library:AddTextStroke(Items["ActualTitle"])

        Library:Create("UIPadding", {
            Name = "\0",
            Parent = Items["ActualTitle"].Instance,
            PaddingRight = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
        })

        Window.Items = Items

        function Window:SetTitle(Text)
            Items["ActualTitle"].Instance.Text = tostring(Text)
        end

        function Window:SetOpen(Bool)
            if Window.IsOpen == Bool then
                return
            end
            Window.IsOpen = Bool
            Items["MainFrame"]:FadeDescendants(Bool)
            if not Bool then
                for _, Frame in pairs(Library.OpenFrames) do
                    Frame:SetOpen(false)
                end
            end
        end

        function Window:Center()
            local screen = getViewportSize()
            local sz = Items["MainFrame"].Instance.AbsoluteSize
            Items["MainFrame"].Instance.AnchorPoint = Vector2.new(0, 0)
            Items["MainFrame"].Instance.Position = UDim2.fromOffset(
                math.max(12, math.floor((screen.X - sz.X) * 0.5)),
                math.max(32, math.floor((screen.Y - sz.Y) * 0.5))
            )
        end

        Library:Connect(UserInputService.InputBegan, function(Input)
            if Library.IsPickingKeybind or UserInputService:GetFocusedTextBox() then
                return
            end
            if tostring(Input.KeyCode) == Library.MenuKeybind or tostring(Input.UserInputType) == Library.MenuKeybind then
                Window:SetOpen(not Window.IsOpen)
            end
        end)

        return setmetatable(Window, Library)
    end

    function Library:Page(Params)
        Params = Params or {}

        local Page = {
            Name = Params.Name or Params.name or "Page",
            Window = self,
            ColumnsData = {},
            Items = {},
            Active = false,
        }

        local Items = {}
        Items["Inactive"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Page.Window.Items["Pages"].Instance,
            Text = "",
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0),
            ZIndex = 2,
            BackgroundColor3 = Library.Theme["Inline"],
        }):AddToTheme({ BackgroundColor3 = "Inline" })

        Items["AccentTop"] = Library:AddAccentHairline(
            Items["Inactive"],
            4,
            UDim2.new(0, 0, 0, 0),
            UDim2.new(1, 0, 0, 1),
            false
        )

        Items["Text"] = Library:Create("TextLabel", {
            Name = "\0",
            FontFace = Library.BoldFont,
            Parent = Items["Inactive"].Instance,
            TextColor3 = Library.Theme["Inactive Text"],
            Text = Page.Name,
            AutomaticSize = Enum.AutomaticSize.X,
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0.5, 0),
            ZIndex = 3,
        }):AddToTheme({ TextColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["Text"])

        Library:Create("UIPadding", {
            Name = "\0",
            Parent = Items["Text"].Instance,
            PaddingRight = UDim.new(0, 9),
            PaddingLeft = UDim.new(0, 9),
        })

        Library:AddBorderStrokes(Items["Inactive"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        })

        Items["Hide"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Inactive"].Instance,
            Visible = false,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 2),
            Size = UDim2.new(1, 0, 0, 3),
            ZIndex = 3,
            BackgroundColor3 = Library.Theme["Content"],
        }):AddToTheme({ BackgroundColor3 = "Content" })

        Items["Page"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Library.UnusedHolder.Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            Visible = false,
        })

        Library:Create("UIListLayout", {
            Name = "\0",
            Parent = Items["Page"].Instance,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        local function createColumn(padLeft, padRight)
            local col = Library:Create("ScrollingFrame", {
                Name = "\0",
                Parent = Items["Page"].Instance,
                ScrollBarImageColor3 = Library.Theme["Outline 1"],
                ScrollBarImageTransparency = 0.25,
                ScrollBarThickness = 2,
                Active = true,
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
            }):AddToTheme({ ScrollBarImageColor3 = "Outline 1" })

            Library:Create("UIPadding", {
                Name = "\0",
                Parent = col.Instance,
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, padLeft),
                PaddingRight = UDim.new(0, padRight),
            })

            Library:Create("UIListLayout", {
                Name = "\0",
                Parent = col.Instance,
                Padding = UDim.new(0, 11),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            return col
        end

        Items["LeftColumn"] = createColumn(8, 4)
        Items["RightColumn"] = createColumn(4, 8)

        Page.ColumnsData[1] = Items["LeftColumn"]
        Page.ColumnsData[2] = Items["RightColumn"]
        Page.Items = Items

        Items["Inactive"]:OnHover(function()
            if Page.Window.Current ~= Page then
                Items["Text"]:Tween({ TextColor3 = Library.Theme["Text"] })
            end
        end, function()
            if Page.Window.Current ~= Page then
                Items["Text"]:Tween({ TextColor3 = Library.Theme["Inactive Text"] })
            end
        end)

        function Page:Turn()
            local Old = Page.Window.Current
            if Old == Page then
                return
            end

            for _, Frame in pairs(Library.OpenFrames) do
                Frame:SetOpen(false)
            end

            if Old then
                Old.Active = false
                Old.Items["Text"]:ChangeItemTheme({ TextColor3 = "Inactive Text" })
                Old.Items["Text"]:Tween({ TextColor3 = Library.Theme["Inactive Text"] })
                Old.Items["Inactive"]:ChangeItemTheme({ BackgroundColor3 = "Inline" })
                Old.Items["Inactive"]:Tween({ BackgroundColor3 = Library.Theme["Inline"] })
                Old.Items["Hide"].Instance.Visible = false
                Old.Items["AccentTop"].Instance.Visible = false

                Old.Items["Page"].Instance.Visible = false
                Old.Items["Page"].Instance.Parent = Library.UnusedHolder.Instance
            end

            Page.Active = true
            Page.Window.Current = Page

            Items["Inactive"]:ChangeItemTheme({ BackgroundColor3 = "Content" })
            Items["Inactive"]:Tween({ BackgroundColor3 = Library.Theme["Content"] })
            Items["Text"]:ChangeItemTheme({ TextColor3 = "Text" })
            Items["Text"]:Tween({ TextColor3 = Library.Theme["Text"] })
            Items["Hide"].Instance.Visible = true
            Items["AccentTop"].Instance.Visible = true

            Items["Page"].Instance.Parent = Page.Window.Items["Content"].Instance
            Items["Page"]:FadeDescendants(true)
        end

        Items["Inactive"]:Connect("MouseButton1Down", function()
            Page:Turn()
        end)

        if #Page.Window.Pages == 0 then
            Page:Turn()
        end

        table.insert(Page.Window.Pages, Page)
        return setmetatable(Page, Library)
    end

    function Library:Section(Params)
        Params = Params or {}

        local Section = {
            Name = Params.Name or Params.name or "Section",
            Side = Params.Side or Params.side or 1,

            Window = self.Window,
            Page = self,
            Items = {},
        }

        local col = Section.Page.ColumnsData[Section.Side] or Section.Page.ColumnsData[1]
        local Items = {}

        Items["Section"] = Library:Create("Frame", {
            Name = "\0",
            Parent = col.Instance,
            Size = UDim2.new(1, 0, 0, 26),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Library.Theme["Inline"],
        }):AddToTheme({ BackgroundColor3 = "Inline" })

        Library:AddBorderStrokes(Items["Section"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        })

        Items["TitleMask"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Section"].Instance,
            Position = UDim2.new(0, 7, 0, -2),
            Size = UDim2.new(0, 0, 0, 4),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Library.Theme["Inline"],
            ZIndex = 2,
        }):AddToTheme({ BackgroundColor3 = "Inline" })

        Library:Create("UIPadding", {
            Name = "\0",
            Parent = Items["TitleMask"].Instance,
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3),
        })

        Items["Text"] = Library:Create("TextLabel", {
            Name = "\0",
            FontFace = Library.BoldFont,
            Parent = Items["TitleMask"].Instance,
            TextColor3 = Library.Theme["Text"],
            Text = Section.Name,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(0, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, -5),
            ZIndex = 3,
        }):AddToTheme({ TextColor3 = "Text" })
        Library:AddTextStroke(Items["Text"])

        Items["Content"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Section"].Instance,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 12),
            Size = UDim2.new(1, -16, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        })

        Library:Create("UIListLayout", {
            Name = "\0",
            Parent = Items["Content"].Instance,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        Library:Create("UIPadding", {
            Name = "\0",
            Parent = Items["Section"].Instance,
            PaddingBottom = UDim.new(0, 8),
        })

        Section.Items = Items
        return setmetatable(Section, Library)
    end

    function Library:MultiSection(Params)
        Params = Params or {}

        local MultiSection = {
            Side = Params.Side or Params.side or 1,
            Window = self.Window,
            Page = self,
            Items = {},
            Current = nil,
            Sections = {},
        }

        local col = MultiSection.Page.ColumnsData[MultiSection.Side] or MultiSection.Page.ColumnsData[1]
        local Items = {}

        Items["MultiSection"] = Library:Create("Frame", {
            Name = "\0",
            Parent = col.Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        })

        Items["Sections"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["MultiSection"].Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
        })

        Library:Create("UIListLayout", {
            Name = "\0",
            Parent = Items["Sections"].Instance,
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 3),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        Items["Inline"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["MultiSection"].Instance,
            Size = UDim2.new(1, 0, 0, 28),
            Position = UDim2.new(0, 0, 0, 20),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Library.Theme["Inline"],
        }):AddToTheme({ BackgroundColor3 = "Inline" })

        Library:AddBorderStrokes(Items["Inline"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        })

        Items["Content"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Inline"].Instance,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(1, -16, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
        })

        Library:Create("UIPadding", {
            Name = "\0",
            Parent = Items["Inline"].Instance,
            PaddingBottom = UDim.new(0, 8),
        })

        MultiSection.Items = Items

        function MultiSection:Add(Name)
            local NewSection = {
                Active = false,
                Window = MultiSection.Window,
                Page = MultiSection.Page,
                Items = {},
            }

            local NewItems = {}
            NewItems["Inactive"] = Library:Create("TextButton", {
                Name = "\0",
                Parent = Items["Sections"].Instance,
                Text = "",
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2.new(0, 0, 1, 0),
                ZIndex = 2,
                BackgroundColor3 = Library.Theme["Content"],
            }):AddToTheme({ BackgroundColor3 = "Content" })

            NewItems["AccentTop"] = Library:AddAccentHairline(
                NewItems["Inactive"],
                4,
                UDim2.new(0, 0, 0, 0),
                UDim2.new(1, 0, 0, 1),
                false
            )

            NewItems["Text"] = Library:Create("TextLabel", {
                Name = "\0",
                FontFace = Library.BoldFont,
                Parent = NewItems["Inactive"].Instance,
                TextColor3 = Library.Theme["Inactive Text"],
                Text = Name,
                AutomaticSize = Enum.AutomaticSize.X,
                AnchorPoint = Vector2.new(0, 0.5),
                Size = UDim2.new(0, 0, 0, 14),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0.5, 0),
                ZIndex = 3,
            }):AddToTheme({ TextColor3 = "Inactive Text" })
            Library:AddTextStroke(NewItems["Text"])

            Library:Create("UIPadding", {
                Name = "\0",
                Parent = NewItems["Text"].Instance,
                PaddingRight = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
            })

            Library:AddBorderStrokes(NewItems["Inactive"], {
                { Theme = "Outline 1", Offset = 0 },
                { Theme = "Outline 3", Offset = 1 },
            })

            NewItems["Hide"] = Library:Create("Frame", {
                Name = "\0",
                Parent = NewItems["Inactive"].Instance,
                Visible = false,
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, 2),
                Size = UDim2.new(1, 0, 0, 3),
                ZIndex = 3,
                BackgroundColor3 = Library.Theme["Inline"],
            }):AddToTheme({ BackgroundColor3 = "Inline" })

            NewItems["Content"] = Library:Create("Frame", {
                Name = "\0",
                Parent = Library.UnusedHolder.Instance,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = false,
            })

            Library:Create("UIListLayout", {
                Name = "\0",
                Parent = NewItems["Content"].Instance,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            NewSection.Items = NewItems

            NewItems["Inactive"]:OnHover(function()
                if MultiSection.Current ~= NewSection then
                    NewItems["Text"]:Tween({ TextColor3 = Library.Theme["Text"] })
                end
            end, function()
                if MultiSection.Current ~= NewSection then
                    NewItems["Text"]:Tween({ TextColor3 = Library.Theme["Inactive Text"] })
                end
            end)

            function NewSection:Turn()
                local Old = MultiSection.Current
                if Old == NewSection then
                    return
                end

                for _, Frame in pairs(Library.OpenFrames) do
                    Frame:SetOpen(false)
                end

                if Old then
                    Old.Active = false
                    Old.Items["Text"]:ChangeItemTheme({ TextColor3 = "Inactive Text" })
                    Old.Items["Text"]:Tween({ TextColor3 = Library.Theme["Inactive Text"] })
                    Old.Items["Inactive"]:ChangeItemTheme({ BackgroundColor3 = "Content" })
                    Old.Items["Inactive"]:Tween({ BackgroundColor3 = Library.Theme["Content"] })
                    Old.Items["Hide"].Instance.Visible = false
                    Old.Items["AccentTop"].Instance.Visible = false

                    Old.Items["Content"].Instance.Visible = false
                    Old.Items["Content"].Instance.Parent = Library.UnusedHolder.Instance
                end

                NewSection.Active = true
                MultiSection.Current = NewSection

                NewItems["Inactive"]:ChangeItemTheme({ BackgroundColor3 = "Inline" })
                NewItems["Inactive"]:Tween({ BackgroundColor3 = Library.Theme["Inline"] })
                NewItems["Text"]:ChangeItemTheme({ TextColor3 = "Text" })
                NewItems["Text"]:Tween({ TextColor3 = Library.Theme["Text"] })
                NewItems["Hide"].Instance.Visible = true
                NewItems["AccentTop"].Instance.Visible = true

                NewItems["Content"].Instance.Parent = Items["Content"].Instance
                NewItems["Content"]:FadeDescendants(true)
            end

            NewItems["Inactive"]:Connect("MouseButton1Down", function()
                NewSection:Turn()
            end)

            if #MultiSection.Sections == 0 then
                NewSection:Turn()
            end

            table.insert(MultiSection.Sections, NewSection)
            return setmetatable(NewSection, Library)
        end

        return setmetatable(MultiSection, Library)
    end

    function Library:Toggle(Params)
        Params = Params or {}

        local Toggle = {
            Name = Params.Name or Params.name or "Toggle",
            Flag = Params.Flag or Params.flag or (Params.Name or Params.name),
            Default = Params.Default or Params.default or false,
            Callback = Params.Callback or Params.callback or function() end,

            Window = self.Window,
            Page = self.Page,
            Section = self,

            Value = false,
            Items = {},
            SettingsItem = nil,
        }

        local Parent = Params.Parent or Toggle.Section.Items["Content"]
        local Items = {}

        Items["Toggle"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Parent.Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
        })

        Items["Hitbox"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Items["Toggle"].Instance,
            Text = "",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
        })

        Items["Indicator"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Toggle"].Instance,
            Position = UDim2.new(0, 1, 0, 2),
            Size = UDim2.new(0, 9, 0, 9),
            BackgroundColor3 = Library.Theme["Content"],
        }):AddToTheme({ BackgroundColor3 = "Content" })

        Library:AddBorderStrokes(Items["Indicator"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        })

        Items["Inline"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Indicator"].Instance,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Library.Theme["Accent"],
        }):AddToTheme({ BackgroundColor3 = "Accent" })
        Library:AddSurfaceShade(Items["Inline"], Color3.fromRGB(255, 255, 255), Color3.fromRGB(185, 185, 195))

        Items["Text"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["Toggle"].Instance,
            TextColor3 = Library.Theme["Inactive Text"],
            Text = Toggle.Name,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 17, 0, -1),
            AutomaticSize = Enum.AutomaticSize.X,
        }):AddToTheme({ TextColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["Text"])

        Items["SubElements"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Toggle"].Instance,
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -1, 0, 0),
            Size = UDim2.new(0, 0, 0, 14),
        })

        Library:Create("UIListLayout", {
            Name = "\0",
            Parent = Items["SubElements"].Instance,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        Items["Hitbox"]:OnHover(function()
            Items["Indicator"]:Tween({ BackgroundColor3 = Library.Theme["Hovered Element"] })
        end, function()
            Items["Indicator"]:Tween({ BackgroundColor3 = Library.Theme["Content"] })
        end)

        Toggle.Items = Items

        function Toggle:Set(Bool)
            Bool = Bool == true
            Toggle.Value = Bool

            if Bool then
                Items["Inline"]:Tween({ BackgroundTransparency = 0, Size = UDim2.new(1, 0, 1, 0) })
                Items["Text"]:ChangeItemTheme({ TextColor3 = "Text" })
                Items["Text"]:Tween({ TextColor3 = Library.Theme["Text"] })
            else
                Items["Inline"]:Tween({ BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0) })
                Items["Text"]:ChangeItemTheme({ TextColor3 = "Inactive Text" })
                Items["Text"]:Tween({ TextColor3 = Library.Theme["Inactive Text"] })
            end

            if Toggle.SettingsItem then
                Toggle.SettingsItem:SetOpen(Bool)
            end

            Flags[Toggle.Flag] = Bool
            Library:SafeCall(Toggle.Callback, Bool)
        end

        function Toggle:SetVisibility(Bool)
            Items["Toggle"].Instance.Visible = Bool
        end

        function Toggle:SetText(Text)
            Items["Text"].Instance.Text = tostring(Text)
        end

        function Toggle:Colorpicker(Data)
            Data = Data or {}
            return Library:CreateColorpicker({
                Parent = Items["SubElements"],
                Page = Toggle.Page,
                Section = Toggle.Section,
                Flag = Data.Flag or Data.flag or (Data.Name or Data.name or Toggle.Name),
                Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                Callback = Data.Callback or Data.callback or function() end,
                Alpha = Data.Alpha or Data.alpha or 0,
            })
        end

        function Toggle:Keybind(Data)
            Data = Data or {}
            return Library:CreateKeybind({
                Parent = Items["SubElements"],
                Name = Data.Name or Data.name or Toggle.Name,
                Page = Toggle.Page,
                Section = Toggle.Section,
                Toggle = Toggle,
                Flag = Data.Flag or Data.flag or (Data.Name or Data.name or Toggle.Name),
                Default = Data.Default or Data.default or Enum.KeyCode.E,
                Mode = Data.Mode or Data.mode or "Toggle",
                ShowInList = Data.ShowInList,
                Callback = Data.Callback or Data.callback or function() end,
            })
        end

        function Toggle:Settings()
            local Settings = {
                IsOpen = false,
                IsSettings = true,
                Window = Toggle.Window,
                Page = Toggle.Page,
                Items = {},
            }

            Items["Toggle"].Instance.AutomaticSize = Enum.AutomaticSize.Y

            local SettingsItems = {}
            SettingsItems["Content"] = Library:Create("Frame", {
                Name = "\0",
                Parent = Items["Toggle"].Instance,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 17, 0, 18),
                Size = UDim2.new(1, -17, 0, 0),
                Visible = false,
                AutomaticSize = Enum.AutomaticSize.Y,
            })

            Library:Create("UIListLayout", {
                Name = "\0",
                Parent = SettingsItems["Content"].Instance,
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })

            Library:Create("UIPadding", {
                Name = "\0",
                Parent = SettingsItems["Content"].Instance,
                PaddingBottom = UDim.new(0, 4),
            })

            SettingsItems["Connect"] = Library:Create("Frame", {
                Name = "\0",
                Parent = Items["Toggle"].Instance,
                Position = UDim2.new(0, 5, 0, 13),
                Size = UDim2.new(0, 1, 0, 0),
                BackgroundColor3 = Library.Theme["Outline 1"],
                Visible = false,
            }):AddToTheme({ BackgroundColor3 = "Outline 1" })

            local function syncConnectHeight()
                if Settings.IsOpen then
                    local h = math.max(0, SettingsItems["Content"].Instance.AbsoluteSize.Y + 2)
                    SettingsItems["Connect"].Instance.Size = UDim2.new(0, 1, 0, h)
                end
            end

            Library:Connect(SettingsItems["Content"].Instance:GetPropertyChangedSignal("AbsoluteSize"), syncConnectHeight)

            Settings.Items = SettingsItems

            function Settings:SetOpen(Bool)
                Settings.IsOpen = Bool
                SettingsItems["Content"].Instance.Visible = Bool
                SettingsItems["Connect"].Instance.Visible = Bool
                if Bool then
                    syncConnectHeight()
                else
                    SettingsItems["Connect"].Instance.Size = UDim2.new(0, 1, 0, 0)
                end
            end

            Toggle.SettingsItem = Settings
            if Toggle.Value then
                Settings:SetOpen(true)
            end
            return setmetatable(Settings, Library)
        end

        Items["Hitbox"]:Connect("MouseButton1Down", function()
            Toggle:Set(not Toggle.Value)
        end)

        Toggle:Set(Toggle.Default)

        SetFlags[Toggle.Flag] = function(Value)
            Toggle:Set(Value)
        end

        return setmetatable(Toggle, Library)
    end

    function Library:Button(Params)
        Params = Params or {}

        local Button = {
            Name = Params.Name or Params.name or "Button",
            Callback = Params.Callback or Params.callback or function() end,

            Window = self.Window,
            Page = self.Page,
            Section = self,
            Items = {},
        }

        local Parent = Params.Parent or Button.Section.Items["Content"]
        local Items = {}

        Items["Button"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Parent.Instance,
            Size = UDim2.new(1, 0, 0, 19),
            BackgroundTransparency = 1,
        })

        Items["RealButton"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Items["Button"].Instance,
            Text = "",
            Position = UDim2.new(0, 1, 0, 0),
            Size = UDim2.new(1, -2, 0, 19),
            BackgroundColor3 = Library.Theme["Content"],
        }):AddToTheme({ BackgroundColor3 = "Content" })
        Library:AddSurfaceShade(Items["RealButton"], Color3.fromRGB(255, 255, 255), Color3.fromRGB(215, 215, 222))

        Library:AddBorderStrokes(Items["RealButton"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        })

        Items["Text"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["RealButton"].Instance,
            TextColor3 = Library.Theme["Text"],
            Text = Button.Name,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(1, -12, 0, 14),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0),
        }):AddToTheme({ TextColor3 = "Text" })
        Library:AddTextStroke(Items["Text"])

        local hovering = false
        Items["RealButton"]:OnHover(function()
            hovering = true
            Items["RealButton"]:Tween({ BackgroundColor3 = Library.Theme["Hovered Element"] })
        end, function()
            hovering = false
            Items["RealButton"]:Tween({ BackgroundColor3 = Library.Theme["Content"] })
        end)

        Button.Items = Items

        local pressToken = 0
        function Button:Press()
            pressToken = pressToken + 1
            local token = pressToken
            Items["RealButton"]:ChangeItemTheme({ BackgroundColor3 = "Accent" })
            Items["RealButton"]:Tween({ BackgroundColor3 = Library.Theme["Accent"] }, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
            Items["Text"]:Tween({ TextColor3 = Library.Theme["Background"] }, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))

            task.delay(0.11, function()
                if pressToken ~= token or not Items["RealButton"].Instance or not Items["RealButton"].Instance.Parent then
                    return
                end
                local targetBg = hovering and "Hovered Element" or "Content"
                Items["RealButton"]:ChangeItemTheme({ BackgroundColor3 = targetBg })
                Items["RealButton"]:Tween({ BackgroundColor3 = Library.Theme[targetBg] })
                Items["Text"]:Tween({ TextColor3 = Library.Theme["Text"] })
            end)

            Library:SafeCall(Button.Callback)
        end

        function Button:SetVisibility(Bool)
            Items["Button"].Instance.Visible = Bool
        end

        function Button:SetText(Text)
            Items["Text"].Instance.Text = tostring(Text)
        end

        Items["RealButton"]:Connect("MouseButton1Down", function()
            Button:Press()
        end)

        return setmetatable(Button, Library)
    end

    function Library:Slider(Params)
        Params = Params or {}

        local Slider = {
            Name = Params.Name or Params.name or "Slider",
            Flag = Params.Flag or Params.flag or (Params.Name or Params.name),
            Default = Params.Default or Params.default or 0,
            Min = Params.Min or Params.min or 0,
            Max = Params.Max or Params.max or 100,
            Callback = Params.Callback or Params.callback or function() end,
            Decimals = (Params.Decimals and Params.Decimals > 0) and Params.Decimals or (Params.decimals and Params.decimals > 0 and Params.decimals) or 1,
            Suffix = Params.Suffix or Params.suffix or "",

            Window = self.Window,
            Page = self.Page,
            Section = self,

            Value = 0,
            Sliding = false,
            Items = {},
        }

        local Parent = Params.Parent or Slider.Section.Items["Content"]
        local Items = {}

        Items["Slider"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Parent.Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 24),
        })

        Items["Text"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["Slider"].Instance,
            TextColor3 = Library.Theme["Text"],
            Text = Slider.Name,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Size = UDim2.new(1, -60, 0, 14),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 1, 0, 0),
        }):AddToTheme({ TextColor3 = "Text" })
        Library:AddTextStroke(Items["Text"])

        Items["Value"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["Slider"].Instance,
            TextColor3 = Library.Theme["Inactive Text"],
            Text = "0",
            TextXAlignment = Enum.TextXAlignment.Right,
            AnchorPoint = Vector2.new(1, 0),
            Size = UDim2.new(0, 58, 0, 14),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -1, 0, 0),
        }):AddToTheme({ TextColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["Value"])

        Items["HitArea"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Items["Slider"].Instance,
            Text = "",
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 10),
        })

        Items["RealSlider"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["HitArea"].Instance,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 1, 0.5, 0),
            Size = UDim2.new(1, -2, 0, 4),
            BackgroundColor3 = Library.Theme["Content"],
        }):AddToTheme({ BackgroundColor3 = "Content" })
        Library:AddSurfaceShade(Items["RealSlider"], Color3.fromRGB(228, 228, 232), Color3.fromRGB(255, 255, 255))

        Library:AddBorderStrokes(Items["RealSlider"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        })

        Items["Accent"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["RealSlider"].Instance,
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Library.Theme["Accent"],
        }):AddToTheme({ BackgroundColor3 = "Accent" })
        Library:AddSurfaceShade(Items["Accent"], Color3.fromRGB(255, 255, 255), Color3.fromRGB(185, 185, 195))

        Items["EdgeHighlight"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Accent"].Instance,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(0, 1, 1, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.55,
        })

        Items["HitArea"]:OnHover(function()
            Items["RealSlider"]:Tween({ BackgroundColor3 = Library.Theme["Hovered Element"] })
            Items["Value"]:Tween({ TextColor3 = Library.Theme["Text"] })
        end, function()
            if not Slider.Sliding then
                Items["RealSlider"]:Tween({ BackgroundColor3 = Library.Theme["Content"] })
                Items["Value"]:Tween({ TextColor3 = Library.Theme["Inactive Text"] })
            end
        end)

        Slider.Items = Items

        function Slider:Set(Value)
            local numeric = tonumber(Value) or Slider.Min
            Slider.Value = math.clamp(Library:Round(numeric, Slider.Decimals), Slider.Min, Slider.Max)

            local span = Slider.Max - Slider.Min
            local alpha = span > 0 and math.clamp((Slider.Value - Slider.Min) / span, 0, 1) or 0
            local tweenInfo = Slider.Sliding and TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out) or nil

            Items["Accent"]:Tween({ Size = UDim2.new(alpha, 0, 1, 0) }, tweenInfo)
            Items["EdgeHighlight"].Instance.Visible = alpha > 0.01
            Items["Value"].Instance.Text = string.format("%s%s", tostring(Slider.Value), Slider.Suffix)

            Flags[Slider.Flag] = Slider.Value
            Library:SafeCall(Slider.Callback, Slider.Value)
        end

        function Slider:SetVisibility(Bool)
            Items["Slider"].Instance.Visible = Bool
        end

        function Slider:GetSize(Input)
            local track = Items["RealSlider"].Instance
            local pos = getPointerPosition(Input)
            local ratio = math.clamp((pos.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
            return ((Slider.Max - Slider.Min) * ratio) + Slider.Min
        end

        function Slider:SetText(Text)
            Items["Text"].Instance.Text = tostring(Text)
        end

        local InputChangedConn

        Items["HitArea"]:Connect("InputBegan", function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                Slider.Sliding = true
                Library.ActiveDragLock = true
                Items["Value"]:Tween({ TextColor3 = Library.Theme["Text"] })

                Slider:Set(Slider:GetSize(Input))

                if InputChangedConn then
                    InputChangedConn:Disconnect()
                end
                InputChangedConn = Input.Changed:Connect(function()
                    if Input.UserInputState == Enum.UserInputState.End then
                        Slider.Sliding = false
                        Library.ActiveDragLock = false
                        Items["RealSlider"]:Tween({ BackgroundColor3 = Library.Theme["Content"] })
                        Items["Value"]:Tween({ TextColor3 = Library.Theme["Inactive Text"] })
                        if InputChangedConn then
                            InputChangedConn:Disconnect()
                            InputChangedConn = nil
                        end
                    end
                end)
            end
        end)

        Library:Connect(UserInputService.InputChanged, function(Input)
            if Slider.Sliding and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                Slider:Set(Slider:GetSize(Input))
            end
        end)

        Slider:Set(Slider.Default)

        SetFlags[Slider.Flag] = function(Value)
            Slider:Set(Value)
        end

        return setmetatable(Slider, Library)
    end

    function Library:Dropdown(Params)
        Params = Params or {}

        local Dropdown = {
            Name = Params.Name or Params.name or "Dropdown",
            OptionItems = Params.Items or Params.items or {},
            Flag = Params.Flag or Params.flag or (Params.Name or Params.name),
            Default = Params.Default or Params.default or "",
            Callback = Params.Callback or Params.callback or function() end,
            Multi = Params.Multi or Params.multi or false,
            MaxSize = Params.MaxSize or 150,

            Window = self.Window,
            Page = self.Page,
            Section = self,

            Value = {},
            Options = {},
            IsOpen = false,
            Items = {},
        }

        local Parent = Params.Parent or Dropdown.Section.Items["Content"]
        local Items = {}

        Items["Dropdown"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Parent.Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 35),
        })

        Items["Text"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["Dropdown"].Instance,
            TextColor3 = Library.Theme["Text"],
            Text = Dropdown.Name,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(1, -2, 0, 14),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 1, 0, 0),
        }):AddToTheme({ TextColor3 = "Text" })
        Library:AddTextStroke(Items["Text"])

        Items["RealDropdown"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Items["Dropdown"].Instance,
            Text = "",
            ClipsDescendants = true,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 1, 1, 0),
            Size = UDim2.new(1, -2, 0, 19),
            BackgroundColor3 = Library.Theme["Content"],
        }):AddToTheme({ BackgroundColor3 = "Content" })
        Library:AddSurfaceShade(Items["RealDropdown"], Color3.fromRGB(255, 255, 255), Color3.fromRGB(220, 220, 226))

        Library:AddBorderStrokes(Items["RealDropdown"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        })

        Items["Value"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["RealDropdown"].Instance,
            TextColor3 = Library.Theme["Inactive Text"],
            Text = "...",
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            AnchorPoint = Vector2.new(0, 0.5),
            Size = UDim2.new(1, -24, 0, 14),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 6, 0.5, 0),
        }):AddToTheme({ TextColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["Value"])

        local Chevron = createChevron(Items["RealDropdown"].Instance, 2)

        Items["OptionHolder"] = Library:Create("TextButton", {
            Name = "\0",
            Parent = Library.UnusedHolder.Instance,
            Visible = false,
            Text = "",
            Size = UDim2.new(0, 200, 0, 0),
            Position = UDim2.new(0, 500, 0, 200),
            BackgroundColor3 = Library.Theme["Background"],
        }):AddToTheme({ BackgroundColor3 = "Background" })

        Library:AddBorderStrokes(Items["OptionHolder"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
            { Theme = "Outline 2", Offset = 2 },
        })

        Items["OptionScroll"] = Library:Create("ScrollingFrame", {
            Name = "\0",
            Parent = Items["OptionHolder"].Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Library.Theme["Outline 1"],
            ScrollBarImageTransparency = 0.25,
        }):AddToTheme({ ScrollBarImageColor3 = "Outline 1" })

        Library:Create("UIPadding", {
            Name = "\0",
            Parent = Items["OptionScroll"].Instance,
            PaddingTop = UDim.new(0, 3),
            PaddingBottom = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 3),
        })

        Items["OptionLayout"] = Library:Create("UIListLayout", {
            Name = "\0",
            Parent = Items["OptionScroll"].Instance,
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        Items["RealDropdown"]:OnHover(function()
            Items["RealDropdown"]:Tween({ BackgroundColor3 = Library.Theme["Hovered Element"] })
            Chevron:SetHovered(true, Dropdown.IsOpen)
        end, function()
            Items["RealDropdown"]:Tween({ BackgroundColor3 = Library.Theme["Content"] })
            Chevron:SetHovered(false, Dropdown.IsOpen)
        end)

        Dropdown.Items = Items
        Dropdown.Holder = Items["OptionHolder"]

        local function updateValueLabel()
            if Dropdown.Multi then
                local hasValues = type(Dropdown.Value) == "table" and #Dropdown.Value > 0
                Items["Value"].Instance.Text = hasValues and table.concat(Dropdown.Value, ", ") or "..."
                Items["Value"]:ChangeItemTheme({ TextColor3 = hasValues and "Text" or "Inactive Text" })
                Items["Value"].Instance.TextColor3 = Library.Theme[hasValues and "Text" or "Inactive Text"]
            else
                local hasValue = Dropdown.Value ~= nil and Dropdown.Value ~= ""
                Items["Value"].Instance.Text = hasValue and tostring(Dropdown.Value) or "..."
                Items["Value"]:ChangeItemTheme({ TextColor3 = hasValue and "Text" or "Inactive Text" })
                Items["Value"].Instance.TextColor3 = Library.Theme[hasValue and "Text" or "Inactive Text"]
            end
        end

        function Dropdown:Set(Value)
            if Dropdown.Multi then
                if type(Value) ~= "table" then
                    return
                end

                local selectedLookup = {}
                local cleanValues = {}
                for _, v in ipairs(Value) do
                    if Dropdown.Options[v] and not selectedLookup[v] then
                        selectedLookup[v] = true
                        table.insert(cleanValues, v)
                    end
                end

                Dropdown.Value = cleanValues
                for optName, OptionData in pairs(Dropdown.Options) do
                    if selectedLookup[optName] then
                        OptionData.IsSelected = true
                        OptionData:ToggleState("Active")
                    else
                        OptionData.IsSelected = false
                        OptionData:ToggleState("Inactive")
                    end
                end

                Flags[Dropdown.Flag] = Dropdown.Value
                updateValueLabel()
            else
                if not Dropdown.Options[Value] then
                    return
                end

                local OptionData = Dropdown.Options[Value]
                Dropdown.Value = Value

                for _, Opt in pairs(Dropdown.Options) do
                    if Opt ~= OptionData then
                        Opt.IsSelected = false
                        Opt:ToggleState("Inactive")
                    else
                        Opt.IsSelected = true
                        Opt:ToggleState("Active")
                    end
                end

                Flags[Dropdown.Flag] = Value
                updateValueLabel()
            end

            Library:SafeCall(Dropdown.Callback, Dropdown.Value)
        end

        function Dropdown:Add(Value)
            local OptionButton = Library:Create("TextButton", {
                Name = "\0",
                Parent = Items["OptionScroll"].Instance,
                TextColor3 = Library.Theme["Inactive Text"],
                Text = tostring(Value),
                BackgroundColor3 = Library.Theme["Hovered Element"],
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 17),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }):AddToTheme({ TextColor3 = "Inactive Text", BackgroundColor3 = "Hovered Element" })
            Library:AddTextStroke(OptionButton)

            Library:Create("UIPadding", {
                Name = "\0",
                Parent = OptionButton.Instance,
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 6),
            })

            local AccentTick = Library:Create("Frame", {
                Name = "\0",
                Parent = OptionButton.Instance,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, -6, 0.5, 0),
                Size = UDim2.new(0, 1, 0, 9),
                BackgroundColor3 = Library.Theme["Accent"],
                Visible = false,
            }):AddToTheme({ BackgroundColor3 = "Accent" })

            local OptionData = {
                Button = OptionButton,
                Text = OptionButton,
                AccentTick = AccentTick,
                Name = Value,
                IsSelected = false,
            }

            OptionButton:OnHover(function()
                OptionButton:Tween({ BackgroundTransparency = 0.2 })
                if not OptionData.IsSelected then
                    OptionButton:Tween({ TextColor3 = Library.Theme["Text"] })
                end
            end, function()
                OptionButton:Tween({ BackgroundTransparency = 1 })
                if not OptionData.IsSelected then
                    OptionButton:Tween({ TextColor3 = Library.Theme["Inactive Text"] })
                end
            end)

            function OptionData:ToggleState(State)
                if State == "Active" then
                    OptionData.AccentTick.Instance.Visible = true
                    OptionData.Text:ChangeItemTheme({ TextColor3 = "Accent" })
                    OptionData.Text:Tween({ TextColor3 = Library.Theme["Accent"] })
                else
                    OptionData.AccentTick.Instance.Visible = false
                    OptionData.Text:ChangeItemTheme({ TextColor3 = "Inactive Text" })
                    OptionData.Text:Tween({ TextColor3 = Library.Theme["Inactive Text"] })
                end
            end

            function OptionData:Set()
                OptionData.IsSelected = not OptionData.IsSelected

                if Dropdown.Multi then
                    if type(Dropdown.Value) ~= "table" then
                        Dropdown.Value = {}
                    end
                    local idx = table.find(Dropdown.Value, OptionData.Name)
                    if idx then
                        table.remove(Dropdown.Value, idx)
                        OptionData.IsSelected = false
                    else
                        table.insert(Dropdown.Value, OptionData.Name)
                        OptionData.IsSelected = true
                    end

                    OptionData:ToggleState(OptionData.IsSelected and "Active" or "Inactive")
                    Flags[Dropdown.Flag] = Dropdown.Value
                    updateValueLabel()
                else
                    if OptionData.IsSelected then
                        Dropdown.Value = OptionData.Name
                        Flags[Dropdown.Flag] = OptionData.Name
                        OptionData.IsSelected = true
                        OptionData:ToggleState("Active")

                        for _, Opt in pairs(Dropdown.Options) do
                            if Opt ~= OptionData then
                                Opt.IsSelected = false
                                Opt:ToggleState("Inactive")
                            end
                        end
                    else
                        Dropdown.Value = nil
                        Flags[Dropdown.Flag] = nil
                        OptionData.IsSelected = false
                        OptionData:ToggleState("Inactive")
                    end
                    updateValueLabel()
                    if Dropdown.IsOpen then
                        Dropdown:SetOpen(false)
                    end
                end

                Library:SafeCall(Dropdown.Callback, Dropdown.Value)
            end

            OptionData.Button:Connect("MouseButton1Down", function()
                OptionData:Set()
            end)

            Dropdown.Options[OptionData.Name] = OptionData
            return OptionData
        end

        function Dropdown:Remove(Option)
            if Dropdown.Options[Option] then
                Dropdown.Options[Option].Button.Instance:Destroy()
                Dropdown.Options[Option] = nil
            end
        end

        function Dropdown:Refresh(List)
            for optName in pairs(Dropdown.Options) do
                Dropdown:Remove(optName)
            end
            for _, val in ipairs(List) do
                Dropdown:Add(val)
            end
        end

        function Dropdown:SetText(Text)
            Items["Text"].Instance.Text = tostring(Text)
        end

        function Dropdown:SetVisibility(Bool)
            Items["Dropdown"].Instance.Visible = Bool
        end

        local OptionHolder = Items["OptionHolder"].Instance
        local RealDropdown = Items["RealDropdown"].Instance
        local IsSettings = Dropdown.Section and Dropdown.Section.IsSettings
        local OpenToken = 0

        local function getHolderHeight()
            local count = 0
            for _ in pairs(Dropdown.Options) do
                count = count + 1
            end
            local contentH = math.max(1, count) * 19 + 4
            return math.min(Dropdown.MaxSize, contentH)
        end

        function Dropdown:SetOpen(Bool)
            if Dropdown.IsOpen == Bool then
                return
            end

            OpenToken = OpenToken + 1
            local token = OpenToken
            Dropdown.IsOpen = Bool

            if Bool then
                for _, Frame in pairs(Library.OpenFrames) do
                    if Frame ~= Dropdown and Frame ~= IsSettings and not Params.Parent then
                        Frame:SetOpen(false)
                    end
                end

                local width = math.max(120, RealDropdown.AbsoluteSize.X)
                local height = getHolderHeight()
                OptionHolder.Size = UDim2.fromOffset(width, height)
                OptionHolder.Parent = Library.Holder.Instance

                local x, y = placePopup(OptionHolder, RealDropdown, width, height)
                OptionHolder.Position = UDim2.fromOffset(x, y - 4)
                OptionHolder.Visible = true
                Chevron:SetOpen(true)

                local zBase = Library.ZIndexOrder.OptionHolder + ((IsSettings or Params.Parent) and 5 or 0)
                setPopupZIndex(OptionHolder, zBase)

                Items["OptionHolder"]:Tween({ Position = UDim2.fromOffset(x, y) })
                Items["OptionHolder"]:FadeDescendants(true)

                Library.OpenFrames[Dropdown] = Dropdown
            else
                Library.OpenFrames[Dropdown] = nil
                Chevron:SetOpen(false)
                local curPos = OptionHolder.Position
                Items["OptionHolder"]:Tween({ Position = UDim2.fromOffset(curPos.X.Offset, curPos.Y.Offset - 4) })
                Items["OptionHolder"]:FadeDescendants(false, function()
                    if OpenToken == token then
                        OptionHolder.Parent = Library.UnusedHolder.Instance
                    end
                end)
            end
        end

        Items["RealDropdown"]:Connect("MouseButton1Down", function()
            Dropdown:SetOpen(not Dropdown.IsOpen)
        end)

        Library:Connect(UserInputService.InputBegan, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                if Dropdown.IsOpen and not Items["OptionHolder"]:IsMouseOverFrame() and not Items["RealDropdown"]:IsMouseOverFrame() then
                    Dropdown:SetOpen(false)
                end
            end
        end)

        for _, Value in ipairs(Dropdown.OptionItems) do
            Dropdown:Add(Value)
        end

        if Dropdown.Multi then
            Dropdown.Value = {}
            Flags[Dropdown.Flag] = Dropdown.Value
            if type(Dropdown.Default) == "table" then
                Dropdown:Set(Dropdown.Default)
            end
        elseif Dropdown.Default and Dropdown.Default ~= "" then
            Dropdown:Set(Dropdown.Default)
        else
            updateValueLabel()
        end

        SetFlags[Dropdown.Flag] = function(Value)
            Dropdown:Set(Value)
        end

        return setmetatable(Dropdown, Library)
    end

    function Library:Label(Params)
        Params = Params or {}

        local Label = {
            Name = Params.Name or Params.name or "Label",
            Window = self.Window,
            Page = self.Page,
            Section = self,
            Items = {},
        }

        local Parent = Params.Parent or Label.Section.Items["Content"]
        local Items = {}

        Items["Label"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Parent.Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
        })

        Items["Text"] = Library:Create("TextLabel", {
            Name = "\0",
            Parent = Items["Label"].Instance,
            RichText = true,
            TextColor3 = Library.Theme["Text"],
            Text = Label.Name,
            TextXAlignment = Enum.TextXAlignment.Left,
            Size = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 1, 0, 0),
            AutomaticSize = Enum.AutomaticSize.X,
        }):AddToTheme({ TextColor3 = "Text" })
        Library:AddTextStroke(Items["Text"])

        Items["SubElements"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Label"].Instance,
            AnchorPoint = Vector2.new(1, 0),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -1, 0, 0),
            Size = UDim2.new(0, 0, 1, 0),
        })

        Library:Create("UIListLayout", {
            Name = "\0",
            Parent = Items["SubElements"].Instance,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })

        Label.Items = Items

        function Label:SetVisibility(Bool)
            Items["Label"].Instance.Visible = Bool
        end

        function Label:SetText(Text)
            Items["Text"].Instance.Text = tostring(Text)
        end

        function Label:Colorpicker(Data)
            Data = Data or {}
            return Library:CreateColorpicker({
                Parent = Items["SubElements"],
                Page = Label.Page,
                Section = Label.Section,
                Flag = Data.Flag or Data.flag or (Data.Name or Data.name or Label.Name),
                Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                Callback = Data.Callback or Data.callback or function() end,
                Alpha = Data.Alpha or Data.alpha or 0,
            })
        end

        function Label:Keybind(Data)
            Data = Data or {}
            return Library:CreateKeybind({
                Parent = Items["SubElements"],
                Name = Data.Name or Data.name or Label.Name,
                Page = Label.Page,
                Section = Label.Section,
                Flag = Data.Flag or Data.flag or (Data.Name or Data.name or Label.Name),
                Default = Data.Default or Data.default or Enum.KeyCode.E,
                Mode = Data.Mode or Data.mode or "Toggle",
                ShowInList = Data.ShowInList,
                Callback = Data.Callback or Data.callback or function() end,
            })
        end

        return setmetatable(Label, Library)
    end

    function Library:Divider(Params)
        Params = Params or {}
        local Divider = {
            Name = Params.Name or Params.name,
            Window = self.Window,
            Page = self.Page,
            Section = self,
            Items = {},
        }

        local Parent = Params.Parent or Divider.Section.Items["Content"]
        local Items = {}

        Items["Divider"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Parent.Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Divider.Name and 14 or 6),
        })

        if Divider.Name and Divider.Name ~= "" then
            Items["Text"] = Library:Create("TextLabel", {
                Name = "\0",
                Parent = Items["Divider"].Instance,
                TextColor3 = Library.Theme["Inactive Text"],
                Text = Divider.Name,
                TextSize = Library.FontSize - 1,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 0, 0, 14),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Library.Theme["Inline"],
            }):AddToTheme({ TextColor3 = "Inactive Text", BackgroundColor3 = "Inline" })
            Library:AddTextStroke(Items["Text"])
            Library:Create("UIPadding", {
                Name = "\0",
                Parent = Items["Text"].Instance,
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
            })
            Items["Line"] = Library:Create("Frame", {
                Name = "\0",
                Parent = Items["Divider"].Instance,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 1, 0.5, 0),
                Size = UDim2.new(1, -2, 0, 1),
                BackgroundColor3 = Library.Theme["Outline 1"],
                ZIndex = 0,
            }):AddToTheme({ BackgroundColor3 = "Outline 1" })
        else
            Items["Line"] = Library:Create("Frame", {
                Name = "\0",
                Parent = Items["Divider"].Instance,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 1, 0.5, 0),
                Size = UDim2.new(1, -2, 0, 1),
                BackgroundColor3 = Library.Theme["Outline 1"],
            }):AddToTheme({ BackgroundColor3 = "Outline 1" })
        end

        Divider.Items = Items
        return setmetatable(Divider, Library)
    end

    function Library:Textbox(Params)
        Params = Params or {}
        local explicitName = Params.Name or Params.name

        local Textbox = {
            Name = explicitName or "Textbox",
            Flag = Params.Flag or Params.flag or (explicitName or "Textbox"),
            Default = Params.Default or Params.default or "",
            Callback = Params.Callback or Params.callback or function() end,
            Finished = Params.Finished or Params.finished or false,
            Placeholder = Params.Placeholder or Params.placeholder or "",
            Numeric = Params.Numeric or Params.numeric or false,

            Window = self.Window,
            Page = self.Page,
            Section = self,
            Value = "",
            Items = {},
        }

        local Parent = Params.Parent or Textbox.Section.Items["Content"]
        local hasHeader = explicitName ~= nil and explicitName ~= ""
        local Items = {}

        Items["Textbox"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Parent.Instance,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, hasHeader and 35 or 19),
        })

        if hasHeader then
            Items["Text"] = Library:Create("TextLabel", {
                Name = "\0",
                Parent = Items["Textbox"].Instance,
                TextColor3 = Library.Theme["Text"],
                Text = explicitName,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, -2, 0, 14),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 1, 0, 0),
            }):AddToTheme({ TextColor3 = "Text" })
            Library:AddTextStroke(Items["Text"])
        end

        Items["Background"] = Library:Create("Frame", {
            Name = "\0",
            Parent = Items["Textbox"].Instance,
            ClipsDescendants = true,
            AnchorPoint = Vector2.new(0, 1),
            Size = UDim2.new(1, -2, 0, 19),
            Position = UDim2.new(0, 1, 1, 0),
            BackgroundColor3 = Library.Theme["Content"],
        }):AddToTheme({ BackgroundColor3 = "Content" })
        Library:AddSurfaceShade(Items["Background"], Color3.fromRGB(235, 235, 240), Color3.fromRGB(255, 255, 255))

        local borderStrokes = Library:AddBorderStrokes(Items["Background"], {
            { Theme = "Outline 1", Offset = 0 },
            { Theme = "Outline 3", Offset = 1 },
        })
        local focusStroke = borderStrokes[1]

        Items["Input"] = Library:Create("TextBox", {
            Name = "\0",
            Parent = Items["Background"].Instance,
            Active = true,
            Selectable = true,
            AnchorPoint = Vector2.new(0, 0.5),
            PlaceholderColor3 = Library.Theme["Inactive Text"],
            PlaceholderText = Textbox.Placeholder,
            Size = UDim2.new(1, -12, 0, 14),
            TextColor3 = Library.Theme["Text"],
            Text = "",
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 6, 0.5, 0),
            CursorPosition = -1,
            ClearTextOnFocus = false,
        }):AddToTheme({ TextColor3 = "Text", PlaceholderColor3 = "Inactive Text" })
        Library:AddTextStroke(Items["Input"])

        Items["Input"]:Connect("Focused", function()
            focusStroke:ChangeItemTheme({ Color = "Accent" })
            focusStroke:Tween({ Color = Library.Theme["Accent"] })
        end)

        Items["Input"]:Connect("FocusLost", function()
            focusStroke:ChangeItemTheme({ Color = "Outline 1" })
            focusStroke:Tween({ Color = Library.Theme["Outline 1"] })
        end)

        Textbox.Items = Items

        function Textbox:SetVisibility(Bool)
            Items["Textbox"].Instance.Visible = Bool
        end

        function Textbox:SetText(Text)
            if Items["Text"] then
                Items["Text"].Instance.Text = tostring(Text)
            else
                Items["Input"].Instance.PlaceholderText = tostring(Text)
            end
        end

        local updatingText = false
        function Textbox:Set(Value)
            Value = tostring(Value or "")
            if Textbox.Numeric then
                if Value ~= "" and Value ~= "-" and Value ~= "." and not tonumber(Value) then
                    Value = Textbox.Value
                end
            end

            Textbox.Value = Value
            if Items["Input"].Instance.Text ~= Value then
                updatingText = true
                Items["Input"].Instance.Text = Value
                updatingText = false
            end

            Flags[Textbox.Flag] = Value
            Library:SafeCall(Textbox.Callback, Value)
        end

        if Textbox.Finished then
            Items["Input"]:Connect("FocusLost", function(Enter)
                if Enter then
                    Textbox:Set(Items["Input"].Instance.Text)
                end
            end)
        else
            Library:Connect(Items["Input"].Instance:GetPropertyChangedSignal("Text"), function()
                if updatingText then
                    return
                end
                Textbox:Set(Items["Input"].Instance.Text)
            end)
        end

        Textbox:Set(Textbox.Default)

        SetFlags[Textbox.Flag] = function(Value)
            Textbox:Set(Value)
        end

        return setmetatable(Textbox, Library)
    end

    function Library:InitWindow()
        local SettingsPage = self:Page({ Name = "settings" })

        local ConfigsSection = SettingsPage:Section({ Name = "configs", Side = 2 })
        local ConfigSelected = nil
        local ConfigName = ""

        local ConfigsDropdown = ConfigsSection:Dropdown({
            Name = "configs",
            Flag = "configs_dropdown",
            Items = {},
            Multi = false,
            Callback = function(Value)
                ConfigSelected = Value
            end,
        })

        ConfigsSection:Textbox({
            Flag = "config_name",
            Placeholder = "config name...",
            Callback = function(Value)
                ConfigName = Value
            end,
        })

        ConfigsSection:Button({
            Name = "create",
            Callback = function()
                if ConfigName and ConfigName ~= "" then
                    safeWriteFile(ConfigsFolder .. ConfigName .. ".json", Library:GetConfig())
                    Library:GetConfigsList(ConfigsDropdown)
                    Library:Notification({ Name = "created config: " .. ConfigName, Time = 3 })
                end
            end,
        })

        ConfigsSection:Button({
            Name = "save",
            Callback = function()
                if ConfigSelected and safeIsFile(ConfigsFolder .. ConfigSelected .. ".json") then
                    local ok, err = safeWriteFile(ConfigsFolder .. ConfigSelected .. ".json", Library:GetConfig())
                    if ok then
                        Library:Notification({ Name = "saved config: " .. ConfigSelected, Time = 3 })
                    else
                        Library:Notification({ Name = "failed to save config: " .. tostring(err), Time = 3 })
                    end
                end
            end,
        })

        ConfigsSection:Button({
            Name = "load",
            Callback = function()
                if ConfigSelected and safeIsFile(ConfigsFolder .. ConfigSelected .. ".json") then
                    local content = safeReadFile(ConfigsFolder .. ConfigSelected .. ".json")
                    if content then
                        local ok, err = Library:LoadConfig(content)
                        if ok then
                            Library:Notification({ Name = "loaded config: " .. ConfigSelected, Time = 3 })
                        else
                            Library:Notification({ Name = "failed to load config: " .. tostring(err), Time = 3 })
                        end
                    end
                end
            end,
        })

        ConfigsSection:Button({
            Name = "delete",
            Callback = function()
                if ConfigSelected and safeIsFile(ConfigsFolder .. ConfigSelected .. ".json") then
                    local deleted = ConfigSelected
                    safeDelFile(ConfigsFolder .. deleted .. ".json")
                    ConfigSelected = nil
                    Library:GetConfigsList(ConfigsDropdown)
                    Library:Notification({ Name = "deleted config: " .. deleted, Time = 3 })
                end
            end,
        })

        ConfigsSection:Button({
            Name = "set autoload",
            Callback = function()
                if ConfigSelected and safeIsFile(ConfigsFolder .. ConfigSelected .. ".json") then
                    safeWriteFile(AutoloadFile, ConfigSelected)
                    Library:Notification({ Name = "autoload set: " .. ConfigSelected, Time = 3 })
                end
            end,
        })

        ConfigsSection:Button({
            Name = "refresh",
            Callback = function()
                Library:GetConfigsList(ConfigsDropdown)
            end,
        })

        Library:GetConfigsList(ConfigsDropdown)

        local ThemingSection = SettingsPage:Section({ Name = "theming", Side = 1 })
        local presetNames = {}
        for name in pairs(ThemePresets) do
            table.insert(presetNames, name)
        end
        table.sort(presetNames)

        ThemingSection:Dropdown({
            Name = "theme preset",
            Flag = "ui_theme_preset",
            Items = presetNames,
            Default = "Radiance Blue",
            Multi = false,
            Callback = function(Value)
                Library:ApplyThemePreset(Value)
            end,
        })

        for _, Index in ipairs(Library.ThemeOrder) do
            local Value = Library.Theme[Index]
            if Value then
                ThemingSection:Label({ Name = Index }):Colorpicker({
                    Name = Index,
                    Flag = Index,
                    Default = Value,
                    Callback = function(NewColor)
                        Library.Theme[Index] = NewColor
                        Library:ChangeTheme(Index, NewColor)
                    end,
                })
            end
        end

        local OtherSection = SettingsPage:Section({ Name = "other", Side = 2 })
        OtherSection:Button({
            Name = "unload",
            Callback = function()
                Library:Exit()
            end,
        })

        OtherSection:Label({ Name = "ui bind" }):Keybind({
            Name = "ui bind",
            Flag = "uibind",
            Mode = "Toggle",
            ShowInList = false,
            Default = Enum.KeyCode.RightShift,
            Callback = function()
                if Flags["uibind"] and Flags["uibind"].Key and Flags["uibind"].Key ~= "None" then
                    Library.MenuKeybind = Flags["uibind"].Key
                end
            end,
        })

        OtherSection:Toggle({
            Name = "show watermark",
            Flag = "ui_show_watermark",
            Default = true,
            Callback = function(Value)
                if Library.WatermarkWidget then
                    Library.WatermarkWidget:SetVisibility(Value)
                end
            end,
        })

        OtherSection:Toggle({
            Name = "show keybind list",
            Flag = "ui_show_keybinds",
            Default = true,
            Callback = function(Value)
                if Library.KeybindListWidget then
                    Library.KeybindListWidget:SetVisibility(Value)
                end
            end,
        })

        OtherSection:Slider({
            Name = "ui scale",
            Flag = "ui_scale",
            Min = 0.75,
            Max = 1.35,
            Default = 1,
            Decimals = 0.05,
            Suffix = "x",
            Callback = function(Value)
                Library.Scale = Value
                if Library.WindowScale and Library.WindowScale.Instance then
                    Library.WindowScale.Instance.Scale = IsMobile and (Value * 0.72) or Value
                end
            end,
        })

        OtherSection:Dropdown({
            Name = "animation style",
            Items = { "Linear", "Quad", "Quart", "Back", "Bounce", "Circular", "Cubic", "Elastic", "Exponential", "Sine", "Quint" },
            Default = Library.Animation.Style,
            Callback = function(Value)
                Library.Animation.Style = Value
            end,
        })

        OtherSection:Dropdown({
            Name = "animation direction",
            Items = { "In", "Out", "InOut" },
            Default = Library.Animation.Direction,
            Callback = function(Value)
                Library.Animation.Direction = Value
            end,
        })

        OtherSection:Slider({
            Name = "animation time",
            Min = 0,
            Max = 1,
            Default = Library.Animation.Time,
            Decimals = 0.01,
            Suffix = "s",
            Callback = function(Value)
                Library.Animation.Time = Value
            end,
        })

        task.defer(function()
            if safeIsFile(AutoloadFile) then
                local autoName = safeReadFile(AutoloadFile)
                if autoName then
                    autoName = autoName:gsub("%s+$", "")
                    local cfgPath = ConfigsFolder .. autoName .. ".json"
                    if autoName ~= "" and safeIsFile(cfgPath) then
                        local content = safeReadFile(cfgPath)
                        if content then
                            local ok = Library:LoadConfig(content)
                            if ok then
                                Library:Notification({ Name = "autoloaded: " .. autoName, Time = 3 })
                            end
                        end
                    end
                end
            end
        end)
    end
end

getgenv().Library = Library
return Library
