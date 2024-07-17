require('job')
require('fixed_partitions')
require('dynamic_partitions')

function love.load()
	love.window.setTitle("Memory Management Visualization")
  math.randomseed(os.time())
  love.window.setMode(900, 600)
  windowWidth, windowHeight = love.graphics.getDimensions()
  love.graphics.setBackgroundColor(0.2, 0.2, 0.35, 1)

  --memory = FP:Create({20, 20, 20, 20, 20, 20}, 'firstFit')
  memory = FP:Create({5, 10, 15, 20, 30, 40}, 'bestFit')
  --memory = DynP:Create(120, 'firstFit')
  --j = Job:Create(15, 5)
  --memory:addJobToQueue(j)
  paused = false
end

function love.update(dt)
  if not paused then 
    memory:update(dt)
  end
end

function love.draw()
  memory:draw()
  if paused then
    drawPause()
  end
end

function drawInstructions()
  local x = 640
  local y = 178 + 18
  love.graphics.print("Instructions", x, y)
  love.graphics.print("'p' - Switch to Fixed Partitions", x, y + (18*1))
  love.graphics.print("'d' - .. Dynamic Partitions", x, y + (18*2))
  love.graphics.print("'f' - .. First Fit Allocation", x, y + (18*3))
  love.graphics.print("'b' - .. Best Fit Allocation", x, y + (18*4))
  love.graphics.print("'w' - .. Worst Fit Allocation", x, y + (18*5))
  love.graphics.print("'q' - Quit", x, y + (18*6))
  love.graphics.print("'Tab' - Pause/Unpause", x, y + (18*7))
  love.graphics.print("'Spacebar' - Add New Job", x, y + (18*9))
end 

function drawPause()
  local width = 80
  local height = 40
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle("fill", math.floor(windowWidth/2)-(width/2), 300-(height/2), width, height, 4, 4)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("PAUSED", math.floor(windowWidth/2)-(width/2), 300-(height/2)+12, width, "center")
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'tab' then 
    paused = not paused
  elseif key == 'q' then
    love.event.quit()
  else
    if not paused then 
      if key == 'space' then
        local j = Job:Create(math.random(2, 35), math.random(4,15))
        memory:addJobToQueue(j)
      elseif key == 'p' then
        memory = FP:Create({5, 10, 15, 20, 30, 40}, 'bestFit')
        j = Job:Create(15, 5)
        memory:addJobToQueue(j)
      elseif key == 'd' then
        memory = DynP:Create(120, 'firstFit')
        j = Job:Create(15, 5)
        memory:addJobToQueue(j)
      elseif key == 'b' then
        memory:setAllocationAlgorithm('bestFit')
      elseif key == 'w' then 
        memory:setAllocationAlgorithm('worstFit')
      elseif key == 'f' then
        memory:setAllocationAlgorithm('firstFit')
      end
    end
  end
end
