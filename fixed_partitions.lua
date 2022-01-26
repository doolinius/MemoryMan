bigFont = love.graphics.newFont(24)
algorithms = {
  firstFit = "First Fit Allocation",
  bestFit = "Best Fit Allocation",
  worstFit = "Worst Fit Allocation"
}

FP = {}
FP.__index = FP

-- algorithm is first fit, best fit or worst fit
function FP:Create(partitionSizes, algorithm)
  local this = {
    partitions = {},
    free = {},
    busy = {},
    waiting = {},
    rejected = {},
    algorithm = algorithm,
    total = 0,
    tick = 1, -- seconds
    timer = 1,
    x = 40,
    y = 70,
    width = 240
  }
  this.maxSize = 0
  for i, size in ipairs(partitionSizes) do
    this.total = this.total + size
    local part = {}
    part.size = size
    part.busy = false
    part.job = nil
    this.partitions[i] = part
    if size > this.maxSize then
      this.maxSize = size
    end
  end

  this.allocate = FP[algorithm]

  setmetatable(this, self)
  return(this)
end

function FP:addJobToQueue(job)
  if job.size > self.maxSize then
    table.insert(self.rejected, job)
  else
    if not self:allocate(job) then
      -- insert at BEGINNING of list
      -- because we have to traverse it backwards
      -- when allocating jobs 
      -- the first job in the table is the last that was entered 
      table.insert(self.waiting, 1, job)
    end
  end
end

function FP:firstFit(job)
  for i, p in ipairs(self.partitions) do
    if not p.busy and p.size >= job.size then
      p.job = job
      p.job:run()
      p.busy = true
      return(true)
    end
  end
  return(false)
end

function FP:bestFit(job)
  local best
  for i, p in ipairs(self.partitions) do
    -- If the job fits and the partition is not busy 
    if not p.busy and p.size >= job.size then
      -- If we haven't found a best candidate yet 
      if not best then 
        best = p -- Then the first one is it 
      else
        -- Otherwise we need to compare the size and take
        -- the smallest that fits 
        if p.size < best.size then 
          best = p
        end 
      end 
    end
  end
  -- If there was an available partition 
  if best then 
    -- add and run the job 
    best.job = job
    best.job:run()
    best.busy = true
    return(true)
  else
    return(false)
  end
end

function FP:worstFit(job)
  local best
  for i, p in ipairs(self.partitions) do
    -- If the job fits and the partition is not busy 
    if not p.busy and p.size >= job.size then
      -- If we haven't found a best candidate yet 
      if not best then 
        best = p -- Then the first one is it 
      else
        -- Otherwise we need to compare the size and take
        -- the smallest that fits 
        if p.size > best.size then 
          best = p
        end 
      end 
    end
  end
  -- If there was an available partition 
  if best then 
    -- add and run the job 
    best.job = job
    best.job:run()
    best.busy = true
    return(true)
  else
    return(false)
  end
end

function FP:deallocate(partition)
  for _, p in ipairs(self.partitions) do
    if (p == partition) then
      p.job = nil
      p.busy = false
      -- This should not be here.  
      -- This makes it an automatic first fit algorithm 
      --[[
      for k, j in ipairs(self.waiting) do
        if j.size <= p.size then
          p.job = j
          p.job:run()
          p.busy = true
          table.remove(self.waiting, k)
          return
        end
      end
      ]]
    end
  end
end

function FP:allocateJobs()
  for i=#self.waiting, 1, -1 do -- in ipairs(self.waiting) do
    local job = self.waiting[i]
    if self:allocate(job) then 
      table.remove(self.waiting, i)
    end
  end
end

function FP:updateJobs(dt)
  self:allocateJobs()
  for i, p in ipairs(self.partitions) do
    if p.busy then
      if p.job.finished then
        self:deallocate(p)
      else
        p.job:update(dt)
      end
    end
  end
end

function FP:update(dt)
  self.timer = self.timer - dt
  if self.timer <= 0 then
    self.timer = self.tick
  end
  self:updateJobs(dt)
end

function FP:drawMemory()
  local yOffset = 0
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Main Memory", self.x + 5, self.y - 18)
  for i, partition in ipairs(self.partitions) do
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('fill', self.x, self.y+yOffset, self.width, partition.size * 4)
    if (partition.busy) then
      love.graphics.setColor(partition.job.color)
      love.graphics.rectangle('fill', self.x, self.y+yOffset, self.width, partition.job.size * 4)
      love.graphics.setColor(0, 1, 0, 1)
      love.graphics.rectangle('fill', self.x, self.y+yOffset+1, math.floor(self.width * (partition.job.timeRemaining/partition.job.duration)), 2)
    else
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.print("FREE", self.x + 5, self.y+yOffset + 5)
    end
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle('line', self.x, self.y+yOffset, self.width, partition.size * 4)
    love.graphics.setColor(1, 1, 1, 1)
    yOffset = yOffset + partition.size * 4
  end
end

function FP:drawWaiting()
  local yOffset = 0
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Waiting Jobs", self.x + 305, self.y - 18)
  -- TODO: reverse this traversal 
  --for i, job in ipairs(self.waiting) do
  for i=#self.waiting, 1, -1 do 
    local job = self.waiting[i]
    love.graphics.setColor(job.color)
    love.graphics.rectangle('fill', self.x + 300, self.y+yOffset, self.width, job.size * 4)
    yOffset = yOffset + job.size * 4 + 10
  end
end

function FP:drawStats()
  local xOffset = self.x + 600
  local stats = self:stats()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Stats", xOffset, self.y - 18)
  love.graphics.print("Total Memory: " .. stats.total, xOffset, self.y)
  love.graphics.print("Total Used  : " .. stats.used, xOffset, self.y + 18)
  love.graphics.print("% Used: " .. percent(stats.used / stats.total), xOffset, self.y + 36)
  love.graphics.print("Fragmentation: " .. stats.internalFrag, xOffset, self.y + (18 *3))
  love.graphics.print("% Fragmentation " .. percent(stats.internalFrag / stats.total), xOffset, self.y + (18*4))
  love.graphics.print("Jobs Rejected (size): " .. stats.rejected, xOffset, self.y + (18*5))
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function percent(decimal)
  return(round(decimal * 100, 1) .. "%")
end

function FP:draw()
  local f = love.graphics.getFont()
  love.graphics.setFont(bigFont)
  love.graphics.printf("Fixed Partitions - " .. algorithms[self.algorithm], 0, self.y - 56, windowWidth, 'center')
  love.graphics.setFont(f)
  self:drawMemory()
  self:drawWaiting()
  self:drawStats()
end

function FP:stats()
  local stats = {}
  stats.total = self.total
  stats.rejected = #self.rejected
  stats.used = 0
  stats.internalFrag = 0
  for i, p in ipairs(self.partitions) do
    if p.busy then
      stats.used = stats.used + p.job.size
      stats.internalFrag = stats.internalFrag + (p.size - p.job.size)
    end
  end
  stats.unused = self.total - stats.used
  return(stats)
end
