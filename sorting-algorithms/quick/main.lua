local ffi = require("ffi")

function love.load()
    love.window.setTitle("QuickSort Visualization")
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
            targetY = yPos,
            pivot = false
        })
    end

    sorting = false
    animationComplete = true
    quickSortQueue = {} 
    pivotIndex = nil
    stepTimer = 0
    stepDelay = 0.8  -- **Delay for pivot marking**
    debug = "Press Q to QuickSort"
end

function getStavePosition(pitch)
    local notePositions = {
        [60] = 360, [61] = 355, [62] = 350, [63] = 345, [64] = 340,
        [65] = 330, [66] = 325, [67] = 320, [68] = 315, [69] = 310,
        [70] = 305, [71] = 300, [72] = 290
    }
    
    return notePositions[pitch] or (300 - (pitch - 60) * 5)
end

function updatePositions()
    for i, note in ipairs(notes) do
        note.targetX = 80 + (i - 1) * 60
        note.targetY = getStavePosition(note.pitch)
    end
end

function resetPivot()
    for _, note in ipairs(notes) do
        note.pivot = false  -- **Reset all pivots**
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

    local baseFreq = 440
    local pitchFactor = 2 ^ ((pitch - 69) / 12)

    source:setPitch(pitchFactor)
    source:play()
end

function quickSort(startIdx, endIdx)
    if startIdx >= endIdx then return end
    table.insert(quickSortQueue, {startIdx, endIdx})
end

function partition(startIdx, endIdx)
    -- **Reset ALL previous pivots first**
    resetPivot()  

    pivotIndex = endIdx  -- **New Pivot**
    notes[pivotIndex].pivot = true

    local pivot = notes[endIdx]
    local i = startIdx - 1
    for j = startIdx, endIdx - 1 do
        if notes[j].pitch <= pivot.pitch then
            i = i + 1
            notes[i], notes[j] = notes[j], notes[i] -- Swap elements
            playNoteForSorting(notes[i].pitch)
            updatePositions()
        end
    end

    notes[i + 1], notes[endIdx] = notes[endIdx], notes[i + 1] -- Swap pivot
    pivotIndex = i + 1  -- Update pivot position
    return i + 1
end

function quickSortStep()
    if #quickSortQueue == 0 then
        sorting = false
        debug = "QuickSort Complete!"
        return
    end

    local step = table.remove(quickSortQueue, 1)
    local pivotIdx = partition(step[1], step[2])

    if step[1] < pivotIdx - 1 then
        table.insert(quickSortQueue, {step[1], pivotIdx - 1})
    end
    if pivotIdx + 1 < step[2] then
        table.insert(quickSortQueue, {pivotIdx + 1, step[2]})
    end

    updatePositions()
end

function love.update(dt)
    if sorting then
        stepTimer = stepTimer + dt
        if stepTimer >= stepDelay then
            stepTimer = 0
            quickSortStep()
        end

        animationComplete = true
        for _, note in ipairs(notes) do
            local dx = note.targetX - note.x
            local dy = note.targetY - note.y
            if math.abs(dx) > 0.1 or math.abs(dy) > 0.1 then
                note.x = note.x + dx * dt * 5
                note.y = note.y + dy * dt * 5
                animationComplete = false
            end
        end
    end
end

function love.keypressed(key)
    if key == "q" then
        sorting = true
        animationComplete = true
        quickSortQueue = {}
        pivotIndex = nil
        quickSort(1, #notes)
        debug = "QuickSort in progress..."
    end
end

function love.draw()
    love.graphics.setColor(0, 0, 0)
    for i = -2, 2 do
        love.graphics.line(50, staveY + i * 10, 750, staveY + i * 10)
    end
    
    for _, note in ipairs(notes) do
        if note.pivot then
            love.graphics.setColor(1, 0, 0)  -- **Pivot is red**
            love.graphics.print("Pivot", note.x - 10, note.y - 20)
        else
            love.graphics.setColor(getPitchColor(note.pitch))
        end
        love.graphics.circle("fill", note.x, note.y, 10)
    end

    love.graphics.setColor(0, 0, 0)
    love.graphics.print(debug, 10, 10)
end
