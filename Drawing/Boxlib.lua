local BoxLib = {}
local RunService = game:GetService("RunService")
local cam = workspace.CurrentCamera

BoxLib.Settings = {
    NearZ = -0.1,
    LineThickness = 1.5,
    TeamCheck = false
}

-- Private storage for active boxes to prevent memory leaks
local ActiveBoxes = {}

local function clipLine(p1, p2)
    local l1 = cam.CFrame:PointToObjectSpace(p1)
    local l2 = cam.CFrame:PointToObjectSpace(p2)
    
    if l1.Z > BoxLib.Settings.NearZ and l2.Z > BoxLib.Settings.NearZ then return nil, nil end
    
    if l1.Z > BoxLib.Settings.NearZ or l2.Z > BoxLib.Settings.NearZ then
        local t = (BoxLib.Settings.NearZ - l1.Z) / (l2.Z - l1.Z)
        local clipped = l1:Lerp(l2, t)
        if l1.Z > BoxLib.Settings.NearZ then l1 = clipped else l2 = clipped end
    end
    
    return cam.CFrame:PointToWorldSpace(l1), cam.CFrame:PointToWorldSpace(l2)
end

function BoxLib.Remove(object)
    if ActiveBoxes[object] then
        ActiveBoxes[object].Connection:Disconnect()
        for _, line in ipairs(ActiveBoxes[object].Lines) do
            line:Remove()
        end
        ActiveBoxes[object] = nil
    end
end

function BoxLib.AddBox(object, color, sizeOverride)
    -- Clean up existing box if it exists for this object
    if ActiveBoxes[object] then BoxLib.Remove(object) end

    local box = {Lines = {}, Connection = nil}
    
    for i = 1, 12 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = color or Color3.new(1, 0, 0)
        line.Thickness = BoxLib.Settings.LineThickness
        line.Transparency = 1
        box.Lines[i] = line
    end

    box.Connection = RunService.RenderStepped:Connect(function()
        if not object or not object.Parent then
            BoxLib.Remove(object)
            return
        end

        local cf = object.CFrame
        local size = (sizeOverride or object.Size) / 2
        
        local corners = {
            cf * Vector3.new(-size.X,  size.Y, -size.Z), cf * Vector3.new( size.X,  size.Y, -size.Z),
            cf * Vector3.new( size.X,  size.Y,  size.Z), cf * Vector3.new(-size.X,  size.Y,  size.Z),
            cf * Vector3.new(-size.X, -size.Y, -size.Z), cf * Vector3.new( size.X, -size.Y, -size.Z),
            cf * Vector3.new( size.X, -size.Y,  size.Z), cf * Vector3.new(-size.X, -size.Y,  size.Z)
        }
        
        local edges = {
            {1,2},{2,3},{3,4},{4,1}, -- Top face
            {5,6},{6,7},{7,8},{8,5}, -- Bottom face
            {1,5},{2,6},{3,7},{4,8}  -- Vertical connectors
        }

        for i, edge in ipairs(edges) do
            local p1, p2 = clipLine(corners[edge[1]], corners[edge[2]])
            if p1 and p2 then
                local s1 = cam:WorldToViewportPoint(p1)
                local s2 = cam:WorldToViewportPoint(p2)
                box.Lines[i].From = Vector2.new(s1.X, s1.Y)
                box.Lines[i].To = Vector2.new(s2.X, s2.Y)
                box.Lines[i].Visible = true
            else
                box.Lines[i].Visible = false
            end
        end
    end)
    
    ActiveBoxes[object] = box
    return box
end

return BoxLib
