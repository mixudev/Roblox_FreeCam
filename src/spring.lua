-- src/spring.lua
-- Spring physics library for smoothing vectors and CFrames

local math = math

local Spring = {}
Spring.__index = Spring

function Spring.new(mass, damping, stiffness, target)
    local self = setmetatable({}, Spring)
    
    self.mass = mass or 1       -- m
    self.damping = damping or 1 -- c // damping > 1 over-damped, < 1 under-damped (bouncy)
    self.stiffness = stiffness or 1 -- k // how snappy it is
    
    self.target = target
    self.velocity = type(target) == "number" and 0 or target * 0
    self.position = target

    return self
end

function Spring:Update(dt)
    local f = self.stiffness * (self.target - self.position)
    local damp = self.damping * self.velocity
    
    local accel = (f - damp) / self.mass
    self.velocity = self.velocity + accel * dt
    self.position = self.position + self.velocity * dt
    
    return self.position
end

return Spring
