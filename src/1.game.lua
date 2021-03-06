function update_game()
   update_player(player)
   -- for mob in all(mobs) do
   --   update_mob(mob)
   -- end
   foreach(particles, update_part)
end

function draw_game()
  cls(0)

  do_shake()

  clip(32, 32, 128-56, 128-56)
    rpal()
  map(0, 0, 0,0, size, size)


  foreach(enviro,item_draw)
  foreach(items,item_draw)
  foreach(entities,entity_draw)
  clip()
  foreach(particles, draw_part)
  foreach(float, draw_float)
  -- if (dev) minimap_draw()

  camera()

  draw_inventory()
  draw_health()
  draw_stats()
  zel_draw()
  draw_instructions()
  if message.ticks > 0 then
    local text = message.text
    rectfill(0,60,128, 68, 5)
    print(text, hcenter(text), vcenter(text), 0)
    message.ticks -= 1
  end
end

function draw_instructions()
  cursor(3,116)
  color(13)
  if aiming then
    color(8)
    print("arrows = fire, z = next")
  elseif using then
    color(8)
    print("z = confirm, x = next")
  elseif #inventory > 0 then
    print("z = aim, x = use")
  end
end

function draw_inventory()
  local j = 0
  for item in all(inventory) do
    _item_draw(item.spr,40 + j, 106,item.col)
    j += 8
  end
  if aiming then
    rect(39 + (8*aimingi), 106, 39 + (8*aimingi) + 9, 106 + 8, 11)
  end
  if using then
    rect(39 + (8*usingi), 106, 39 + (8*usingi) + 9, 106 + 8, 11)
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
  for i=1,player.mhp do
   hearts = hearts .. "\x87"
  end
  print(hearts, 1, 1, 3)
  hearts = ""
  for i=1,player.hp do
   hearts = hearts .. "\x87"
  end
  -- debug[1] = player.hp
  print(hearts, 1, 1, 9)
  local armour = ""
  for i=1,player.def do
   armour = armour .. "\x87"
  end
  print(armour, 1, 10, 5)
end

function update_player(player)
  if (player.hp <= 0) gameover()
  local endturn = input(getbutt())

  if endturn then
    --animate()
    animate(update_end_turn)
  end
end

-- function update_mob(mob)
--
-- end

function pickup_item(item)
  -- sfx(pick)
  -- local isgold = item.name == 'gold'
  if item.name == 'gold' then
    del(items, item)
    gold += 1
    addfloat('+gold', player, 10)
    return
  elseif item.name == 'bag' then
    del(items, item)
    invsize += 1
    addfloat('+bag', player, 10)
    return
  elseif item.name == 'heart' then
    del(items, item)
    player.hp = min(player.hp + 1, player.mhp)
    addfloat('+hp', player, 10)
    return
  elseif item.name == 'shield' then
    del(items, item)
    player.def += 1
    addfloat('+def', player, 10)
    return
  end


  local match = find(inventory, "name", item.name)
  if match and not item.stack then
    return
  elseif #inventory == 5 then

    if rand(0,4) == 1 then
      addfloat("fumble", {x=player.x-1,y=player.y-1}, 9)
      inventory = shuffle(inventory)
      local drop = pop(inventory)
      -- drop_item({item.x,item.y}, drop)
      item_create({item.x,item.y}, drop.name) -- bug here, will re charge items if fumbled, maybe leave in :D
    else
      addfloat("full", {x=player.x-1,y=player.y-1}, 9)
      return
    end
  end

  del(items, item)

  addfloat(item.name, player, 10)

  add(inventory, item)
  update_stats()
end

function update_stats()
  player.atk = 1
  player.mhp = 3
  player.def = 0
  for item in all(inventory) do
    if item.atk then
      player.atk = max(player.atk, item.atk)
    elseif item.hp then
      player.mhp = max(player.mhp, item.hp)
    elseif item.def then
      player.def = max(player.def, item.def)
    end
  end
end

function update_end_turn()

 room = zgetar()
 if not room.spawn then
   -- move player in one
   player.x += lastmove[1]
   player.y += lastmove[2]

   zel_spawn(room)
 end

 item = item_at(player.x, player.y)
 if (item) pickup_item(item)

 for entity in all(entities) do
   entity.mov = nil
   local tile = mget(entity.x,entity.y)
   if tile == t_stairs and entity == player then
     depth += 1

     if depth == 5 then
       win_game()
       return
     end

     zel_generate()
     player.x, player.y = start[1] * 8 - 4, start[2] * 8 -4
   --elseif fget(tile, 5) then
    -- tip = 'watch your step'
    --if (not entity.flying) atk(entity, 2, 'the void')
   else
    local env = env_at(entity.x,entity.y)
    if env and not entity.flying then
      log(entity.name .. " stood on env")
      if (env.spr == 31 and not entity.slime) poison(entity, {})
      if (env.spr == 15) flame(entity, {})
     -- add(debug, entity.name .. "=" .. env.type)
     -- if (entity.name != env.type) atk(entity, 1, env.name)
    end
   end
  if (entity.poison > 0) then
    entity.poison -= 1
    atk(entity, 1, 'poison')
  end
  if (entity.flame > 0) then
    entity.flame -= 1
    atk(entity, 1, 'fire')
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
    del(enemies, ent)
    del(entities, ent)
    if rand(0,10) == 1 or ent.loot then
      -- drop_item(ent.x, ent.y)
      item_create({ent.x,ent.y}, randa(t_drops[depth]))
    end
    if(zel_clear()) zel_unlock()
  end
end

-- function drop_item(x,y)
--   local random = rand(1,4)
--   local item = "health potion"
--   if random == 1 then
--     item = randa(t_items)
--   elseif random == 2 then
--     item = randa(t_weapons)
--   elseif random == 3 then
--     item = "gold"
--   end
--   -- log("drop!!!")
--   item_create({x,y}, item)
-- end

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
 elseif walkable(x, y, "entities") or (entity.flying and not enemy_at(x, y)) then
   -- if (entity.roots > 0) return
   insert(moves, dir, dist)
  end
 end

 if #moves > 0 then
  local move = pop(moves)[1]
  -- add(debug, "move " .. move[1])
  -- if (entity.trail) add_enviro(entity.x, entity.y, entity.trail, 2)
  mobwalk(entity, move[1], move[2])
 end
end

function atk(entity, amount, cause)

  local def = entity.def
  if def and def > 0 then
    unblocked = max(amount - def, 0)
    blocked =  amount - unblocked
    entity.def -= blocked
    amount = unblocked
  end
 if amount <= 0 then
   return
  -- addfloat('+'.. abs(amount), entity, 11)
 else
  addfloat('-'.. amount, entity, 8)
 end

 entity.hp -= amount
 entity.flash = 10
 -- sfx(hit)
 shake=.5

 if(entity == player) reason = cause
 log(cause .. " hit " .. entity.name .. " " .. amount)
end

function entity_draw(self)
 local col = self.col
 if self.flash>0 then
  self.flash-=1
  col=13
  elseif self.poison > 0 then
    col=11
  elseif self.flame > 0 then
    col=12
  elseif self.stun > 0 then
    col=7
 end
 local frame = self.stun != 0 and self.ani[1] or getframe(self.ani)
 local x, y = self.x*8+self.ox, self.y*8+self.oy
 drawspr(frame, x, y, col, self.flp, self.flash > 0 or col!=self.col, self.outline)

 --if (self.stun !=0) draws(10, x, y, 0, false)
 --if (self.roots !=0) draws(11, x, y, 0, false)
 --if (self.linked) draws(12, x, y, 0, false)
end

function item_draw(self)
 _item_draw(self.spr, self.x*8, self.y*8, self.col)
end

function _item_draw(s,x,y,col)
  pal(15,col or 10)
  spr(s,x,y)
  rpal()
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
  if aiming then
   return fireprojectile(player, dirs[butt+1])
  elseif using then
    return use()
  else
   return moveplayer(dirs[butt+1])
  end
elseif butt==4 and #inventory > 0 then
  if aiming then
    aimingi += 1
    if aimingi >= #inventory then
      aiming = false
      aimingi = 0
    end
  elseif using then
    return use()
  else
    aiming = true
  end
  return false
 elseif butt==5 and #inventory > 0 then
   if using then
     usingi += 1
     if usingi >= #inventory then
       using = false
       usingi = 0
     end
   else
     using = true
   end
   --return false -- maybe discharge if #enemies == 0
  --else
   --return switchitem()
  --end
 end
end

function use()
  using = false
  local item = inventory[usingi+1]
  -- log("use")
  -- log(item)
  if item.use then
    item.use(player, item)
    del(inventory, item)
    return true
  else
    addfloat('?', player, 9)
    return false
  end
end

function fireprojectile(entity, dir)
  mobflip(entity, dir[1])
  aiming = false
  -- charges[item] -= 1
  local hx, hy = throwtile(dir[1], dir[2]) -- max distance???

  local item = inventory[aimingi+1]
  -- log("fire item")
  -- log(item)

  if item.ammo then
    if item.ammo == 0 then
      addfloat("out of charges", player, 9)
      item.ammo = -1
      item.ratk = nil
      return false
    else
      item.ammo -= 1
    end
  end

  local hit = entity_at(hx, hy)
  local amount = 1

  if item.ratk then
    amount = item.ratk
  else
   if not hit or item.name == 'key' then
     hx -= dir[1]
     hy -= dir[2]
     amount = 0
     -- item_create({hx,hy}, item.name, {ammo=item.ammo})
     item.x, item.y = hx, hy

     if (not item.throw) add(items, item)
   end

   del(inventory, item)
   update_stats()
  end

  if item.throw then
    item.throw(hit or {x=hx,y=hy}, item)
    del(inventory, item)
  elseif hit then
    atk(hit, amount, item.name)
  end

  for i=1,4 do
    -- different colours??
    create_part(hx*8+4, hy*8+4,(rnd(16)-8)/16,(rnd(16)-8)/16, 0, rnd(30)+10,rnd(2)+3, 8)
  end

  -- create_part(hx,hy,rnd(1)-0.5,rnd(0.5)-1,0,rnd(30)+10,rnd(4)+2)
  -- create_part(hx*8+4, hy*8+4, rnd(1)-0.5,rnd(0.5)-1,0,rnd(30)+10,rnd(4)+2,5)


  -- debug[1]= magics[stored[item]]
  -- effects[m](hx, hy, hit, entity)
  return true
end

function aimtile(entity, dx, dy)
 local tx,ty,i = entity.x,entity.y,0
 repeat
  tx += dx
  ty += dy
  i += 1
 until not walkable(tx,ty, "player") or i >= 8
 return tx,ty
end

function throwtile(dx, dy)
 local tx,ty,i = player.x,player.y,0
 repeat
  tx += dx
  ty += dy
  i += 1
 until not walkable(tx,ty, "entities") or i >= 8
 return tx,ty
end

function find(array, key, value)
  for m in all(array) do
   if m[key] == value then
    return m
   end
  end
end

function moveplayer(dir)
  lastmove = dir
  local dx, dy = dir[1], dir[2]
  local destx,desty=player.x+dx,player.y+dy
  --local tle=mget(destx,desty)

  if walkable(destx, desty, "entities") then
  -- sfx(63)
    mobwalk(player,dx,dy)
  --animate()
elseif locked(destx,desty) and find(inventory, "name", "key") then
    -- log("unlocked")
    local key = find(inventory, "name", "key")
    del(inventory, key)
    mset(destx, desty, mget(destx,desty)-7)
    -- mobwalk(player,dx,dy)
  elseif entity_at(destx,desty) then
    entity = entity_at(destx,desty)
    atk(entity, player.atk, player.name)

    -- check inventory for item with hit
    for item in all(inventory) do
      if (item.hit) then
        log("item.hit")
        item.hit(entity, item)
      end
    end

    mobbump(player,dx,dy)
  else
  -- sfx(63)
    mobbump(player,dx,dy)
    return false
  end
  return true
end

function locked(x, y)
  local locked = fget(mget(x,y), 2)
  -- log("locked " .. to_s(locked))
  return locked
end

function walkable(x, y, mode)
 local mode = mode or ""
 local floor = not fget(mget(x,y), 0)

 if mode == "entities" then
  if (floor) return entity_at(x,y) == nil
 end
 if mode == "items" then
  if (floor) return item_at(x,y) == nil
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

function enemy_at(x,y)
  return blank_at(x,y, enemies)
end

function item_at(x,y)
  return blank_at(x,y, items)
end

function env_at(x,y)
  return blank_at(x,y, enviro)
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
