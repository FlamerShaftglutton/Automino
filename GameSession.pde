class GameSession extends GridGameFlowBase
{
  int rounds_completed = 0;
  ArrayList<WinCondition> win_conditions = new ArrayList<WinCondition>();
  ArrayList<RewardGriddle> rewards = new ArrayList<RewardGriddle>();
  GameState state = GameState.MENU;
  Griddle to_upgrade = null;
  //curses/boons
  
  void update()
  {
    super.update();
    
    switch (state)
    {
      case STARTING_PLAYLEVEL: start_level(); break;
      case PLAYLEVEL: check_for_level_end(); if (globals.keyReleased && key == 'q') globals.game.pop(); break;
      case LEVELEDITOR: level_editor(); break;
      case WON_PLAYLEVEL: globals.game.push(new MessageScreenGameFlow(), "You won!"); player.ng = null; nongriddles.clear(); nongriddles_to_delete.clear(); grid = get_LevelEditor_from_level(grid); state = GameState.LEVELEDITOR; break;  //TODO: add in curse / boon stuff
      case LOST_PLAYLEVEL: globals.game.push(new MessageScreenGameFlow(), "You lose..."); break;
      case MENU: grid = get_LevelEditor_from_level(grid); state = GameState.LEVELEDITOR; break;
    }
  }
  
  void level_editor()
  {
    if (globals.keyReleased  && key == 'y') 
    { 
      save(); 
      nongriddles.clear(); 
      nongriddles_to_delete.clear();
      load(); 
      state = GameState.STARTING_PLAYLEVEL; 
    }
  }
  
  void onFocus(String message)
  {
    if (message.contains("lose") || message.contains("lost"))
      globals.game.pop();
    else if (to_upgrade != null)
    {
      Griddle griddy = globals.gFactory.create_griddle(message, this);
      
      if (!(griddy instanceof NullGriddle))
      {
        JSONObject tggo = griddy.serialize();
        LevelEditorNonGriddle leng = globals.ngFactory.create_le_ng(tggo.getString("_template"));
        leng.as_json = tggo;
        leng.shape = globals.sprites.get_sprite(tggo.getString("sprite"));
        leng.visible = false;
        register_ng(leng);
        
        to_upgrade.remove_ng();
        to_upgrade.receive_ng(leng);
        
        destroy_ng(player.ng);
        player.ng = null;
      }
      
      to_upgrade = null;
    }
  }
  
  void handle_message(Message message)
  {
    if (message.target.equals("upgrade"))
    {
      to_upgrade = (Griddle)message.sender;
      
      //IntVec griddy_pos = grid.get_grid_pos_from_object(griddy);
      
      StringList upgrades = globals.gFactory.get_upgrades(message.value);
      
      if (upgrades.size() > 0)
      {
        UpgradeMenuGameFlow upmenu = new UpgradeMenuGameFlow();
        
        upmenu.options = upgrades;
        
        upmenu.load();
        
        globals.game.push(upmenu);
      }
    }
    if (message.target.equals("info"))
      toasts.add(new Toast(message.value, 5f));
  }
  
  String exit()
  {
    return save_path;
  }
  
  JSONObject serialize()
  {
    JSONObject root = super.serialize();
    
    root.setInt("rounds_completed", rounds_completed);
    
    return root;
  }
  
  void deserialize(JSONObject root)
  {    
    super.deserialize(root);
    
    rounds_completed = root.getInt("rounds_completed");
    
    win_conditions.clear();
    
    for (int x = 1; x < grid.w; ++x)
    {
      Griddle gr = grid.get(x, grid.h - 1);
      
      if (gr instanceof CountingOutputResourcePool)
      {
        CountingOutputResourcePool cgr = (CountingOutputResourcePool)gr;
        
        if (cgr.required > 0)
        {
          WinCondition wc = new WinCondition(cgr.ng_type, cgr.required, cgr);
          win_conditions.add(wc);
        }
      }
    }
    
    //state = GameState.STARTING_PLAYLEVEL;
  }
  
  void create_new()
  {
    int w = (int)random(10, 16);
    int h = (int)random(10, 16);
    
    String req_type   = random(10) > 4 ? "Iron Ingot" : "Cobalt Ingot";
    int    req_amount = 1;
    
    JSONObject ov = new JSONObject();
    ov.setString("ng_type", req_type);
    ov.setInt("required", req_amount);
    
    WinCondition win_condition = new WinCondition(req_type, req_amount, (CountingOutputResourcePool)globals.gFactory.create_griddle("Output", ov, this));
    win_conditions.add(win_condition);
    
    Grid gg = new Grid(new PVector(20,20), new PVector(width - 40, height - 40), w, h, this);
    
    for (int y = 1; y < h; ++y)
      gg.set(0,y,new NullGriddle());
    
    gg.set(0,h-1, new NullGriddle());
    gg.set(1,h-1, win_condition.to_check);
    gg.set(2,h-1, globals.gFactory.create_griddle("GoldIngotOutput", this));
    
    for (int x = 3; x < w; ++x)
      gg.set(x, h-1, new NullGriddle());
    
    ov = JSONObject.parse("{ 'resources': { 'Iron Ore': 5, 'Cobalt Ore': 5, 'Gold Speck': 1 } }");
    gg.set(0,0,globals.gFactory.create_griddle("RandomResourcePool", ov, this));
    
    for (int x = 1; x < w - 1; ++x)
      gg.set(x,0, globals.gFactory.create_griddle("GrabberBelt", this));
    
    ov = JSONObject.parse("{ 'automatic': true, 'speed': 0.005 }");
    gg.set(w - 1, 0, globals.gFactory.create_griddle("TrashCompactor",ov, this));
    
    for (int y = 1; y < h - 6; ++y)
      gg.set(w - 1, y, new NullGriddle(this));
    
    
    String[] to_place = { "Smelter", "Crusher", "Refiner", "Player" };
    ArrayList<IntVec> used_spots = new ArrayList<IntVec>();
    ov = JSONObject.parse("{ 'automatic': false }");
    
    for (int i = 0; i < to_place.length; ++i)
    {
      boolean placed = false;
      
      String tps = to_place[i];
      
      while (!placed)
      {
        int xx = (int)random(2,w - 2);
        int yy = (int)random(2,h - 2);
        
        boolean used = false;
        for (int ii = 0; !used && ii < used_spots.size(); ++ii)
          used = (used_spots.get(ii).x == xx && used_spots.get(ii).y == yy);
        
        if (!used)
        {
          if (tps.equals("Player"))
          {
            player = new Player(this);
            
            player.spritename = globals.gFactory.get_spritename("Player");
            player.sprite = globals.sprites.get_sprite(player.spritename);
            player.pos = gg.absolute_pos_from_grid_pos(new IntVec(xx,yy));
            player.dim = gg.get_square_dim();
            
          }
          else
            gg.set(xx,yy, globals.gFactory.create_griddle(tps, ov, this));
          
          used_spots.add(new IntVec(xx,yy));
          placed = true;
        }
      }
    }
    
    grid = gg;
  }
  
  void refresh_rewards()
  {
    rewards.clear();
    for (int y = grid.h - 6; y < grid.h - 1; ++y)
    {
      RewardGriddle rg = new RewardGriddle(this);
      rewards.add(rg);
      grid.set(grid.w-1,y, rg);
    }
    
    StringList types = globals.gFactory.all_reward_names();
    
    for (int i = 0; i < rewards.size(); ++i)
    {
      RewardGriddle rg = rewards.get(i);
      
      int p = (int)random(types.size());
      
      rg.reward_griddle_name = types.get(p);
      rg.time_used = 0f;
      rg.time_needed = 48;
      
      rg.finished = false;
      rg.running = false;
    }
  }
  
  void start_level()
  {
    refresh_rewards();
    
    rewards.get(0).running = true;
    
    for (WinCondition wc : win_conditions)
    {
      wc.to_check.count = 0;
      wc.to_check.required = wc.amount;
    }
    
    state = GameState.PLAYLEVEL;
    
    grid.apply_alterations();
  }
  
  void check_for_level_end()
  {
    //check for a win
    boolean won = true;
    for (WinCondition wc : win_conditions)
    {
      if (wc.to_check.get_count() < wc.amount)
      {
        won = false;
        break;
      }
    }
    
    if (won)
      win_level();
    
    //check for a loss
    boolean all_finished = true;
    for (int i = 0; i < rewards.size(); ++i)
    {
      RewardGriddle rg = rewards.get(i);
      
      if (all_finished && !rg.running)
        rg.running = true;
      
      all_finished &= rg.finished;
    }
    
    if (all_finished)
      lose_level();
  }
  
  void win_level()
  {
    ++rounds_completed;
    
    for (WinCondition wc : win_conditions)
      wc.increment();

    state = GameState.WON_PLAYLEVEL;
  }
  
  void lose_level()
  {
    //TODO: fill this in
    
    state = GameState.LOST_PLAYLEVEL;
  }
  
  Grid get_LevelEditor_from_level(Grid tg)
  {
    Grid le_grid = new Grid(tg.original_pos, tg.dim, tg.w, tg.h, this);
    
    for (int y = 0; y < tg.h; ++y)
    {
      for (int x = 0; x < tg.w; ++x)
      {
        Griddle tgg = tg.get(x,y);
        
        if (tgg instanceof NullGriddle)
          le_grid.set(x,y,new NullGriddle());
        else if (tgg instanceof CountingOutputResourcePool)
        {
          CountingOutputResourcePool output = new CountingOutputResourcePool(this);
          output.deserialize(tgg.serialize());
          
          if (!output.ng_type.equals("Gold Ingot"))
            output.count = 0;
          
          le_grid.set(x,y, output);
        }
        else
        {
          boolean lock = (x == 0 || y == 0 || y == tg.h - 1 || x == tg.w - 1);
          
          LevelEditorGriddle leg = new LevelEditorGriddle(this);
          
          if (!(tgg instanceof EmptyGriddle || tgg instanceof RewardGriddle))
          {
            JSONObject tggo = tgg.serialize();
            LevelEditorNonGriddle leng = globals.ngFactory.create_le_ng(tggo.getString("_template",tggo.getString("type")));
            leng.as_json = tggo;
            leng.shape = globals.sprites.get_sprite(tggo.getString("sprite"));
            leng.visible = false;
            register_ng(leng);
            leg.receive_ng(leng);
          }
          
          leg.locked = lock;
          leg.traversable = !lock;
          leg.quarter_turns = tgg.quarter_turns;
          
          le_grid.set(x,y,leg);
        }
      }
    }
    
    
    for (int y = 1; y < tg.h - 1; ++y)
    {
      Griddle tgg = tg.get(tg.w - 1, y);
      
      if (tgg instanceof RewardGriddle)
      {
        RewardGriddle rg = (RewardGriddle)tgg;
        
        if (!rg.finished)
        {
          LevelEditorGriddle leg = new LevelEditorGriddle(this);
          
          JSONObject tggo = globals.gFactory.create_griddle(rg.reward_griddle_name, this).serialize();
          
          LevelEditorNonGriddle leng = globals.ngFactory.create_le_ng(tggo.getString("type"));
          leng.as_json = tggo;
          leng.shape = globals.sprites.get_sprite(tggo.getString("sprite"));
          leng.visible = false;
          register_ng(leng);
          leg.receive_ng(leng);
          
          leg.locked = false;
          leg.traversable = true;
          
          le_grid.set(tg.w - 1,y,leg);
        }
      }
    }
    
    return le_grid;
  }
}

enum GameState
{
  PLAYLEVEL,
  LEVELEDITOR,
  MENU,
  STARTING_PLAYLEVEL,
  WON_PLAYLEVEL,
  LOST_PLAYLEVEL
}

class WinCondition
{
  String ng_type;
  int    amount;
  CountingOutputResourcePool to_check;
  
  WinCondition() { ng_type = ""; amount = 0; to_check = null; }
  WinCondition(String ng_type, int amount, CountingOutputResourcePool to_check) { this.ng_type = ng_type; this.amount = amount; this.to_check = to_check; }
  
  void advance_amount(int to_add) { amount += to_add; to_check.required = amount; }
  void increment() { advance_amount(1); }
}
