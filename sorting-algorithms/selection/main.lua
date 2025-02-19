local ffi = require("ffi")

function love.load()
    love.window.setTitle("MIDI Stave Visualization")
    love.window.setMode(800, 600)
    love.graphics.setBackgroundColor(1, 0.85, 0.9)

    staveY = 300
    notes = {}

    -- Pink & Purple gradient shades
    colorStart = {1, 0.7, 0.8}
    colorMiddle = {0.8, 0, 0.6}
    colorEnd = {0.5, 0, 0.8}

    -- Load sound file
    source = love.audio.newSource("note.wav", "static")

    -- Generate random notes within a valid stave range
    for i = 1, 10 do
        local pitch = love.math.random(60, 72) -- MIDI notes from C4 to C5
        local yPos = getStavePosition(pitch)

        table.insert(notes, {
            pitch = pitch,
            x = 80 + (i - 1) * 60,
            targetX = 80 + (i - 1) * 60,
            y = yPos,
            targetY = yPos
        })
    end

    sorting = false
    selectionSortStep = 1 -- Track which step we are on
    animationComplete = true
    debug = "Press 'S' to sort notes (Selection Sort)"
end

function getStavePosition(pitch)
    local notePositions = {
        [60] = 360, -- C4 (Below stave)
        [61] = 355, -- C#4/Db4
        [62] = 350, -- D4
        [63] = 345, -- D#4/Eb4
        [64] = 340, -- E4 (First line)
        [65] = 330, -- F4
        [66] = 325, -- F#4/Gb4
        [67] = 320, -- G4 (Second line)
        [68] = 315, -- G#4/Ab4
        [69] = 310, -- A4
        [70] = 305, -- A#4/Bb4
        [71] = 300, -- B4 (Third line)
        [72] = 290  -- C5 (Above stave)
    }
    
    return notePositions[pitch] or (300 - (pitch - 60) * 5)
end

function updatePositions()
    for i, note in ipairs(notes) do
        note.targetX = 80 + (i - 1) * 60
        note.targetY = getStavePosition(note.pitch)
    end
end

function getPitchColor(pitch)
    local t = (pitch - 60) / 12
    local color = {}

    if t < 0.5 then
        local t2 = t * 2
        for i = 1, 3 do
            color[i] = colorStart[i] + (colorMiddle[i] - colorStart[i]) * t2
        end
    else
        local t2 = (t - 0.5) * 2
        for i = 1, 3 do
            color[i] = colorMiddle[i] + (colorEnd[i] - colorMiddle[i]) * t2
        end
    end
    return color
end

function playNoteForSorting(pitch)
    if source:isPlaying() then
        source:stop()
    end

    -- Convert MIDI note to frequency shift
    local baseFreq = 440 -- A4 reference
    local pitchFactor = 2 ^ ((pitch - 69) / 12)

    source:setPitch(pitchFactor) -- Adjust playback speed
    source:play()
end

function selectionSortStepFunc()
    if not animationComplete then return end
    if selectionSortStep > #notes then
        sorting = false
        debug = "Sorting complete!"
        return
    end

    local minIndex = selectionSortStep
    for j = selectionSortStep + 1, #notes do
        if notes[j].pitch < notes[minIndex].pitch then
            minIndex = j
        end
    end

    if minIndex ~= selectionSortStep then
        -- Swap the lowest note with current selection step
        notes[selectionSortStep], notes[minIndex] = notes[minIndex], notes[selectionSortStep]
        
        updatePositions()
        playNoteForSorting(notes[selectionSortStep].pitch) -- Play sound of the correct-placed note
    end

    selectionSortStep = selectionSortStep + 1
    debug = string.format("Sorting... Step %d/%d", selectionSortStep, #notes)
end

function love.update(dt)
    if sorting then
        animationComplete = true
        for _, note in ipairs(notes) do
            local dx = note.targetX - note.x
            local dy = note.targetY - note.y
            if math.abs(dx) > 0.1 or math.abs(dy) > 0.1 then
                note.x = note.x + dx * dt * 5 -- Animation speed = 5
                note.y = note.y + dy * dt * 5
                animationComplete = false
            end
        end
        
        if animationComplete then
            selectionSortStepFunc()
        end
    end
end

function love.keypressed(key)
    if key == "s" then
        sorting = true
        selectionSortStep = 1
        animationComplete = true
        debug = "Starting Selection Sort..."
    end
end

function love.draw()
    -- Draw the musical stave
    love.graphics.setColor(0, 0, 0)
    for i = -2, 2 do
        love.graphics.line(50, staveY + i * 10, 750, staveY + i * 10)
    end
    
    -- Draw the notes
    for _, note in ipairs(notes) do
        local color = getPitchColor(note.pitch)
        love.graphics.setColor(color)
        love.graphics.circle("fill", note.x, note.y, 10)
    end
    
    -- Draw debug info
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(debug, 10, 10)
    
    -- Draw all pitches for debugging
    local pitchStr = "Pitches: "
    for _, note in ipairs(notes) do
        pitchStr = pitchStr .. note.pitch .. " "
    end
    love.graphics.print(pitchStr, 10, 30)
end
