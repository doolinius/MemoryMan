require('job')
require('fixed_partitions')
require('dynamic_partitions')

function love.load()
  math.randomseed(os.time())
  windowWidth, windowHeight = love.graphics.getDimensions()
  love.graphics.setBackgroundColor(0.2, 0.2, 0.35, 1)

  --memory = FP:Create({20, 20, 20, 20, 20, 20}, 'firstFit')
  --memory = FP:Create({5, 10, 15, 20, 30, 40}, 'bestFit')
  memory = DynP:Create(120, 'firstFit')
  j = Job:Create(15, 5)
  memory:addJobToQueue(j)
end

function love.update(dt)
  memory:update(dt)
end

function love.draw()
  memory:draw()
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'space' then
    local j = Job:Create(math.random(2, 35), math.random(4,15))
    memory:addJobToQueue(j)
  end
end
