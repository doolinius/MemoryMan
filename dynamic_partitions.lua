bigFont = love.graphics.newFont(24)

DynP = {}
DynP.__index = DynP

-- algorithm is first fit, best fit or worst fit
function DynP:Create(size, algorithm)
  local this = {
    partitions = {},
    free = {},
    busy = {},
    waiting = {},
    rejected = {},
    algorithm = algorithm,
    total = size,
    tick = 1, -- seconds
    timer = 1,
    x = 40,
    y = 70,
    width = 240
  }
  this.maxSize = size
  local part = {}
  part.size = size 
  part.busy = false
  part.job = nil 
  this.partitions[1] = part
  --[[
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
  ]]

  this.allocate = DynP[algorithm]

  setmetatable(this, self)
  return(this)
end

function DynP:setAllocationAlgorithm(algorithm)
	self.algorithm = algorithm
	self.allocate = DynP[algorithm]
end

function DynP:getSize()
  local size = 0
  for i, p in ipairs(self.partitions) do 
    size = size + p.size 
  end 
  return(size)
end 

function DynP:addJobToQueue(job)
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

-- Add a new job to a partition larger
-- Creates a new empty partition in the available space
-- Will be used by both firstFit and bestFit
function DynP:addSplit(job, partition, index)
  -- split partition in two
  local newpart = {}
  newpart.size = partition.size - job.size -- new partition is what's left after adding job
  newpart.busy = false -- not busy
  newpart.job = nil -- no job running
  -- resize current partition
  partition.size = job.size -- must equal size of current job
  partition.job = job 
  partition.busy = true 
  partition.job:run()
  -- add new partition in next slot
  table.insert(self.partitions, index+1, newpart)
end

function DynP:firstFit(job)
  for i, p in ipairs(self.partitions) do
    if not p.busy and p.size == job.size then
      print("Partition is same size")
      p.job = job
      p.job:run()
      p.busy = true
      return(true)
    elseif not p.busy and p.size > job.size then
      print("partition is larger")
      self:addSplit(job, p, i)
      return(true)
      -- split partition in two
      --[[
      local newpart = {}
      newpart.size = p.size - job.size -- new partition is what's left after adding job
      newpart.busy = false -- not busy
      newpart.job = nil -- no job running
      -- resize current partition
      p.size = job.size -- must equal size of current job
      -- add new partition in next slot
      table.insert(self.partitions, i+1, newpart)
      ]]
    end
  end
  return(false)
end

function DynP:bestFit(job)
  local best, best_index
  for i, p in ipairs(self.partitions) do
    -- If the job fits and the partition is not busy 
    if not p.busy and p.size >= job.size then
      -- If we haven't found a best candidate yet 
      if not best then 
        best = p -- Then the first one is it
        best_index = i
      else
        -- Otherwise we need to compare the size and take
        -- the smallest that fits 
        if p.size < best.size then 
          best = p
          best_index = i
        end 
      end 
    end
  end
  -- If there was an available partition 
  if best then 
    -- add and run the job
    if best.size == job.size then 
      best.job = job
      best.job:run()
      best.busy = true
    else 
      self:addSplit(job, best, best_index)
    end
    return(true)
  else
    return(false)
  end
end

function DynP:worstFit(job)
  local best, best_index
  for i, p in ipairs(self.partitions) do
    -- If the job fits and the partition is not busy 
    if not p.busy and p.size >= job.size then
      -- If we haven't found a best candidate yet 
      if not best then 
        best = p -- Then the first one is it 
        best_index = i 
      else
        -- Otherwise we need to compare the size and take
        -- the smallest that fits 
        if p.size > best.size then 
          best = p
          best_index = i
        end 
      end 
    end
  end
  -- If there was an available partition 
  if best then 
    -- add and run the job 
    if best.size == job.size then 
      best.job = job
      best.job:run()
      best.busy = true
    else 
      self:addSplit(job, best, best_index)
    end
    return(true)
  else
    return(false)
  end
end

function partition_busy(p)
  if p then 
    if p.busy then
      return(true)
    else
      return(false)
    end 
  else
    return(true)
  end
end

function DynP:mergePartitions(p1_index, p1, p2, p3)
  if p3 then 
    p1.size = p1.size + p2.size + p3.size
    p1.busy = false 
    p1.job = nil 
    table.remove(self.partitions, p1_index+2)
    table.remove(self.partitions, p1_index+1)
  else
    p1.size = p1.size + p2.size 
    p1.busy = false
    p1.job = nil
    table.remove(self.partitions, p1_index+1)
  end
end

function DynP:deallocate(partition, index)
  print("Deallocating partition " .. index)
  local old_size = self:getSize()

  local before_part, next_part
  if index > 1 then 
    before_part = self.partitions[index-1]
  end 
  if index < #self.partitions then 
    next_part = self.partitions[index+1]
  end

  if partition_busy(before_part) and partition_busy(next_part) then    
    print("Deallocated partition is isolated")
    partition.job = nil 
    partition.busy = false
  elseif partition_busy(before_part) and not partition_busy(next_part) then
    print("Deallocated partition is adjacent to an open partition BEFORE")
    self:mergePartitions(index, partition, next_part)
  elseif not partition_busy(before_part) and partition_busy(next_part) then 
    -- merge partitions 
    print("Deallocated partition is adjacent to an open partition BEFORE")
    self:mergePartitions(index-1, before_part, partition) 
  else
    -- merge all three 
    print("Deallocated partition is between two open partitions")
    self:mergePartitions(index-1, before_part, partition, next_part)
  end

  local new_size = self:getSize()
  assert(old_size == new_size, "Memory size changed")

end

function DynP:allocateJobs()
  for i=#self.waiting, 1, -1 do -- in ipairs(self.waiting) do
    local job = self.waiting[i]
    if self:allocate(job) then 
      table.remove(self.waiting, i)
    end
  end
end

function DynP:updateJobs(dt)
  self:allocateJobs()
  for i, p in ipairs(self.partitions) do
    if p.busy then
      if p.job.finished then
        self:deallocate(p, i)
      else
        p.job:update(dt)
      end
    end
  end
end

function DynP:update(dt)
  self.timer = self.timer - dt
  if self.timer <= 0 then
    self.timer = self.tick
  end
  self:updateJobs(dt)
end

function DynP:drawMemory()
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

function DynP:drawWaiting()
  local yOffset = 0
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Waiting Jobs", self.x + 305, self.y - 18)
  for i=#self.waiting, 1, -1 do
    local job = self.waiting[i]
    love.graphics.setColor(job.color)
    love.graphics.rectangle('fill', self.x + 300, self.y+yOffset, self.width, job.size * 4)
    yOffset = yOffset + job.size * 4 + 10
  end
end

function DynP:drawStats()
  local xOffset = self.x + 600
  local stats = self:stats()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print("Stats", xOffset, self.y - 18)
  love.graphics.print("Total Memory: " .. stats.total, xOffset, self.y)
  love.graphics.print("Total Used  : " .. stats.used, xOffset, self.y + 18)
  love.graphics.print("% Used: " .. percent(stats.used / stats.total), xOffset, self.y + 36)
  love.graphics.print("Fragmentation: " .. stats.externalFrag, xOffset, self.y + (18 *3))
  love.graphics.print("% Fragmentation " .. percent(stats.externalFrag / stats.total), xOffset, self.y + (18*4))
  love.graphics.print("Jobs Rejected (size): " .. stats.rejected, xOffset, self.y + (18*5))
end

function DynP:draw()
  local f = love.graphics.getFont()
  love.graphics.setFont(bigFont)
  love.graphics.printf("Dynamic Partitions - " .. algorithms[self.algorithm], 0, self.y - 56, windowWidth, 'center')
  love.graphics.setFont(f)
  self:drawMemory()
  self:drawWaiting()
  self:drawStats()
  drawInstructions()
end

function DynP:stats()
  local stats = {}
  stats.total = self.total
  stats.rejected = #self.rejected
  stats.used = 0
  stats.externalFrag = 0
  for i, p in ipairs(self.partitions) do
    if p.busy then
      stats.used = stats.used + p.job.size
    else
      stats.externalFrag = stats.externalFrag + p.size
    end
  end
  stats.unused = self.total - stats.used
  return(stats)
end
