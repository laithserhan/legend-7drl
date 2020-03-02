function update_game()
   update_player(player)
   for mob in all(mobs) do
     update_mob(mob)
   end
end

function draw_game()
  cls(0)
  do_shake()

  clip(32, 32, 128-56, 128-56)
  map(0, 0, 0,0, size, size)


  -- foreach(enviro,draw_enviro)
  foreach(items,item_draw)
  foreach(entities,entity_draw)
  clip()
  -- foreach(particles,draw_part)
  foreach(float, draw_float)
  if (dev) minimap_draw()

  camera()
  draw_inventory()
  draw_health()
  draw_stats()
  zel_draw()
end

function draw_inventory()
  local j = 0
  for item in all(inventory) do
    drawspr(item.spr, 40 + j, 106, item.col, false, false, true)
    j += 8
  end
end

function draw_stats()
  cursor(2, 20)
  print("atk " .. player.atk)
  cursor(2, 28)
  if (gold > 0) print("gold " .. gold)
end

function draw_health()
  -- rectfill(0, 0, 11, 22, 0)
  local hearts = ""
  for i=1,player.hp do
   hearts = hearts .. "\x87"
  end
  print(hearts, 1, 1, 8)
  local armour = ""
  for i=1,player.def do
   armour = armour .. "\x87"
  end
  print(armour, 1, 10, 6)
end

function update_player(player)
  if (player.hp <= 0) gameover()
  local endturn = input(getbutt())

  if endturn then
    --animate()
    animate(update_end_turn)
  end
end

function update_mob(mob)

end

function pickup_item(item)
  del(items, item)

  if item.type == 'g' then
    gold += item.amount
    addfloat("+" .. item.amount .. ' gold', player.x * 8, player.y * 8, 9)
    return
  elseif item.atk then
    local atk = player.atk
    local dif = item.atk - atk
    local pos = dif > 0 and ' +' or ' '

    addfloat(item.name .. pos .. dif .. 'atk', player.x * 8, player.y * 8, 7)

    player.atk = item.atk or atk
  elseif item.hp then
    local hp = player.hp
    local dif = item.hp - hp
    local pos = dif > 0 and ' +' or ' '

    addfloat(item.name .. pos .. dif .. 'hp', player.x * 8, player.y * 8, 7)

    player.hp = item.hp or hp
  end

  add(inventory, item)
end

function update_end_turn()

 room = zgetar()
 if not room.spawn then
   zel_spawn(room)
 end

 item = item_at(player.x, player.y)
 if (item) pickup_item(item)

 for entity in all(entities) do
   entity.mov = nil
   local tile = mget(entity.x,entity.y)
   if tile == t_stairs and entity == player then
     depth += 1
     zel_generate()
     player.x, player.y = start[1] * 8 - 4, start[2] * 8 -4
   --elseif fget(tile, 5) then
    -- tip = 'watch your step'
    --if (not entity.flying) atk(entity, 2, 'the void')
   else
    --local env = env_at(entity.x,entity.y)
    --if env then
     ---- add(debug, entity.name .. "=" .. env.type)
     --if (entity.name != env.type) atk(entity, 1, env.name)
    --end
   end
  if (entity.hp <= 0) then
   on_death(entity)
  end
 end
 for env in all(enviro) do
  env.turns -= 1
  if(env.turns <= 0) del(enviro, env)
 end
 _upd = update_ai
  --_upd =
end

function on_death(ent)
  if ent != player then
    del(entities, ent)
    if rand(0,10) == 1 then
      drop_item(ent.x, ent.y)
    end
  end
end

function drop_item(x,y)
  local random = rand(1,4)
  local item = "i5"
  if random == 1 then
    item = randa(t_items)
  elseif random == 2 then
    item = randa(t_weapons)
  elseif random == 3 then
    item = "g5"
  end
  item_create({x,y}, item)
end

function update_ai()
  --buffer()

  for entity in all(entities) do
   if entity != player and entity.hp > 0 then
    if entity.stun > 0 then
     entity.stun -= 1
    else
     -- add(debug, "action " .. entity.name)
     --if entity.boss then
      --boss_action(entity)
     --else
      if entity.ai then
        entity.ai(entity)
      end
     --end
    end
    if (entity.roots > 0) entity.roots -= 1
   end
  end

  animate()
end

function ai_action(entity)
 if (distance(entity.x, entity.y, player.x, player.y) > 10) return
 move_towards(entity)
end

function move_towards(entity)
 local shuffled = shuffle({1,2,3,4})
 local moves = {}
 for i in all(shuffled) do
  local dir = dirs[i]
  local dx,dy = dir[1], dir[2]
  local x, y = entity.x + dx, entity.y + dy
  local dist = distance(x, y, player.x, player.y)
  if dist == 0 then
   mobbump(entity, dx, dy)
   atk(player, entity.atk, entity.name)
   return
  elseif walkable(x, y, "entities") then
   if (entity.roots > 0) return
   if (mget(x,y) != 81 or entity.stupid) insert(moves, dir, dist)
  end
 end

 if #moves > 0 then
  local move = pop(moves)[1]
  -- add(debug, "move " .. move[1])
  if (entity.trail) add_enviro(entity.x, entity.y, entity.trail, 2)
  mobwalk(entity, move[1], move[2])
 end
end

function atk(entity, amount, cause)
  amount -= entity.def
 if amount <= 0 then
   return
  -- addfloat('+'.. abs(amount), entity.x * 8, entity.y * 8, 11)
 else
  addfloat('-'.. amount, entity.x * 8, entity.y * 8, 8)
 end
 entity.hp -= amount
 entity.flash = 10
 shake=.5
 if (entity == player) killer = cause or "something"
end

function entity_draw(self)
 local col = self.col
 if self.flash>0 then
  self.flash-=1
  col=7
 end
 local frame = self.stun != 0 and self.ani[1] or getframe(self.ani)
 local x, y = self.x*8+self.ox, self.y*8+self.oy
 drawspr(frame, x, y, col, self.flp, self.flash > 0, self.outline)

 --if (self.stun !=0) draws(10, x, y, 0, false)
 --if (self.roots !=0) draws(11, x, y, 0, false)
 --if (self.linked) draws(12, x, y, 0, false)
end

function item_draw(self)
 local col = self.col
 -- if self.flash>0 then
 --  self.flash-=1
 --  col=7
 -- end
 local frame = self.spr -- self.stun != 0 and self.ani[1] or getframe(self.ani)
 local x, y = self.x*8, self.y*8
 drawspr(frame, x, y, col, false, false, true)

 --if (self.stun !=0) draws(10, x, y, 0, false)
 --if (self.roots !=0) draws(11, x, y, 0, false)
 --if (self.linked) draws(12, x, y, 0, false)
end

function getframe(ani)
 return ani[flr(t/15)%#ani+1]
end

function getbutt()
 for i=0,5 do
  if (btnp(i)) return i
 end
 return -1
end

function input(butt)
 if butt<0 then return false end
 if butt<4 then
  --if aiming then
   --return fireprojectile(player, dirs[butt+1])
  --else
   return moveplayer(dirs[butt+1])
  --end
 elseif butt==4 then
  --return toogleshoot()
 elseif butt==5 then
  --if aiming then
   --return false -- maybe discharge if #enemies == 0
  --else
   --return switchitem()
  --end
 end
end

function find(array, key, value)
  -- log("find ["..key.."]="..value)
  -- log(array)

  for m in all(array) do
   if m[key] == value then
    -- log("found " .. value)
    return m
   end
  end
end

function moveplayer(dir)
  local dx, dy = dir[1], dir[2]
  local destx,desty=player.x+dx,player.y+dy
  --local tle=mget(destx,desty)

  if walkable(destx, desty, "entities") then
  -- sfx(63)
    mobwalk(player,dx,dy)
  --animate()
  elseif locked(destx,desty) and find(inventory, "type", "k") then
    -- log("unlocked")
    key = find(inventory, "type", "k")
    del(inventory, key)
    mset(destx, desty, mget(destx,desty)-1)
    -- mobwalk(player,dx,dy)
  elseif entity_at(destx,desty) then
    entity = entity_at(destx,desty)
    atk(entity, player.atk, player.name)
    mobbump(player,dx,dy)
  else
  -- sfx(63)
    mobbump(player,dx,dy)
    -- return false
  end
  return true
end

function locked(x, y)
  local locked = fget(mget(x,y), 2)
  -- log("locked " .. to_s(locked))
  return locked
end

function walkable(x, y, mode)
 if(dev) return true

 local mode = mode or ""
 local floor = not fget(mget(x,y), 0)
 -- TODO improve this
 if mode == "entities" then
  if (floor) return entity_at(x,y) == nil
 end
 if mode == "player" then
  if (floor) return player.x == x and player.y == y
 end
 return floor
end

function blank_at(x,y, array)
  for m in all(array) do
   if m.x==x and m.y==y then
    return m
   end
  end
end

function entity_at(x,y)
  return blank_at(x,y, entities)
end

function item_at(x,y)
  return blank_at(x,y, items)
end

function mobwalk(mb,dx,dy)
 mb.x+=dx --?
 mb.y+=dy

 mobflip(mb,dx)
 mb.sox,mb.soy=-dx*8,-dy*8
 mb.ox,mb.oy=mb.sox,mb.soy
 mb.mov=mov_walk
end

function mobbump(mb,dx,dy)
 mobflip(mb,dx)
 mb.sox,mb.soy=dx*8,dy*8
 mb.ox,mb.oy=0,0
 mb.mov=mov_bump
end

function mobflip(mb,dx)
 mb.flp = dx==0 and mb.flp or dx<0
end

function mov_walk(self)
 local tme=1-p_t
 self.ox=self.sox*tme
 self.oy=self.soy*tme
end

function mov_bump(self)
 local tme= p_t>0.5 and 1-p_t or p_t
 self.ox=self.sox*tme
 self.oy=self.soy*tme
end

function update_animate()
 --buffer()
 p_t=min(p_t+0.6,1)  -- 0.125

 for entity in all(entities) do
  if entity.mov then
   entity:mov()
  end
 end

 if p_t==1 then
    if (_push_wait) wait(_push_wait)
    _upd=_push_upd or update_game
  end
end

function animate(push_upd)
 p_t=0
 _push_upd = push_upd
 _upd=update_animate
end
