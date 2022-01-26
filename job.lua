Job = {}
Job.__index = Job

function Job:Create(size, duration)
  local this = {
    size = size,
    duration = duration,
    timeRemaining = duration,
    running = false,
    finished = false,
    timeWaiting = 0,
    color = {math.random(), math.random(), math.random()}
  }

  setmetatable(this, self)
  return(this)
end

function Job:run()
  self.running = true
end

function Job:update(dt)
  if self.running then
    self.timeRemaining = self.timeRemaining - dt
    if self.timeRemaining <= 0 then
      self.finished = true
    end
  else
    self.timeWaiting = self.timeWaiting + dt
  end
end
