-- Hold Control and scroll to send Control + Arrow.
-- Vertical scroll:   up/down
-- Horizontal scroll: left/right

local eventtap = hs.eventtap
local eventTypes = eventtap.event.types
local properties = eventtap.event.properties

local arrowKeyCodes = {
    left = 123,
    right = 124,
    down = 125,
    up = 126,
}

local function sendControlArrow(arrow)
    local script = string.format(
        'tell application "System Events" to key code %d using control down',
        arrowKeyCodes[arrow]
    )
    hs.osascript.applescript(script)
end

local function scrollDelta(event, legacyProperty, pointProperty, fixedProperty)
    local delta = event:getProperty(legacyProperty) or 0
    if delta == 0 then
        delta = event:getProperty(pointProperty) or 0
    end
    if delta == 0 then
        delta = event:getProperty(fixedProperty) or 0
    end
    return delta
end

local controlScrollArrows = eventtap.new({ eventTypes.scrollWheel }, function(event)
    local flags = event:getFlags()

    if not flags.ctrl then
        return false
    end

    local momentumPhase = event:getProperty(properties.scrollWheelEventMomentumPhase) or 0
    if momentumPhase ~= 0 then
        return true
    end

    -- Use every available delta format so even the smallest movement fires.
    local vertical = scrollDelta(
        event,
        properties.scrollWheelEventDeltaAxis1,
        properties.scrollWheelEventPointDeltaAxis1,
        properties.scrollWheelEventFixedPtDeltaAxis1
    )
    local horizontal = scrollDelta(
        event,
        properties.scrollWheelEventDeltaAxis2,
        properties.scrollWheelEventPointDeltaAxis2,
        properties.scrollWheelEventFixedPtDeltaAxis2
    )

    local arrow
    if math.abs(vertical) >= math.abs(horizontal) and vertical ~= 0 then
        arrow = vertical > 0 and "up" or "down"
    elseif horizontal ~= 0 then
        arrow = horizontal > 0 and "left" or "right"
    end

    if arrow then
        sendControlArrow(arrow)
    end

    return true
end)

controlScrollArrows:start()

-- Keep a global reference so the event tap is not garbage-collected.
_G.controlScrollArrows = controlScrollArrows
