class GameSession extends GridGameFlowBase
{
  int rounds_completed = 0;
  ArrayList<WinCondition> win_conditions = new ArrayList<WinCondition>();
  ArrayList<RewardGriddle> rewards = new ArrayList<RewardGriddle>();
  GameState state = GameState.MENU;
  Griddle to_upgrade = null;
  RuleManager rules = new RuleManager();
  
  void update()
  {
    super.update();
    
    switch (state)
    {
      case STARTING_PLAYLEVEL: start_level(); break;
      case PLAYLEVEL: check_for_level_end(); if (globals.keyReleased && key == 'q') globals.game.pop(); break;
      case LEVELEDITOR: level_editor(); break;
      case WON_PLAYLEVEL: win_level(); break;
      case LOST_PLAYLEVEL: lose_level(); break;
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
  
  void onFocus(Message message)
  {
    if (message.target.equals("lose"))
      globals.game.pop();
    else if (message.target.equals("upgrade") && to_upgrade != null)
    {
      Griddle griddy = globals.gFactory.create_griddle(message.value, this);
      
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
    else if (message.target.equals("rule"))
    {
      rules.put(globals.ruleFactory.get_rule(message.value));
      
      conform_to_rules();
    }
  }
  
  void handle_message(Message message)
  {
    if (message.target.equals("upgrade"))
    {
      to_upgrade = (Griddle)message.sender;
      
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
  
  Message exit()
  {
    return new Message("save",save_path);
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
  }
  
  void conform_to_rules()
  {
    StringList required_operations = rules.get_strings("Required:Operations");
    StringList required_outputs    = rules.get_strings("Required:Outputs");
    
    StringList found_outputs = new StringList();
    StringList found_operations = new StringList();
    for (int x = 0; x < grid.w; ++x)
    {
      for (int y = 0; y < grid.h; ++y)
      {
        Griddle eg = grid.get(x,y);
        //String tname = eg.template;
        //found_tags.append(globals.gFactory.get_tags(tname));
        //found_operations.append(globals.gFactory.get_operations(tname));
        
        if (eg instanceof Transformer)
          found_operations.append(((Transformer)eg).operations);
        else if (eg instanceof CountingOutputResourcePool)
          found_outputs.append(((CountingOutputResourcePool)eg).ng_type);
      }
    }
    
    StringList basic_griddles = globals.gFactory.get_names_by_tag("basic");
    for (String operation : required_operations)
    {
      if (!found_operations.hasValue(operation))
      {
        //create the missing thing in a random spot
        Griddle new_griddle = null;
        for (String basic_griddle : basic_griddles)
        {
          if (globals.gFactory.get_operations(basic_griddle).hasValue(operation))
          {
            new_griddle = globals.gFactory.create_griddle(basic_griddle,this);
            break;
          }
        }
        
        if (new_griddle == null)
        {
          new_griddle = new NullGriddle(this);
          println("Couldn't find a griddle with the 'basic' tag that had the required operation of '" + operation + "'. No transformer with this operation exists on the board, so the player will not be able to win.");
        }
        
        boolean placed = false;
        
        while (!placed)
        {
          int xx = (int)random(1,grid.w - 2);
          int yy = (int)random(1,grid.h - 2);
          
          if (grid.get(xx,yy) instanceof EmptyGriddle)
          {
            grid.set(xx,yy, new_griddle);
            placed = true;
          }
        }
      }
    }
    
    
    for (String output : required_outputs)
    {
      if (!found_outputs.hasValue(output))
      {
        Griddle new_output = null;
        
        for (String basic_griddle : basic_griddles)
        {
          if (globals.gFactory.get_string(basic_griddle, "ng_type").equals(output))
          {
            new_output = globals.gFactory.create_griddle(basic_griddle, this);
            break;
          }
        }
        
        if (new_output == null || new_output instanceof NullGriddle)
        {
          new_output = new NullGriddle(this);
          println("Couldn't find a griddle with the 'basic' tag that had the required ng_type of '" + output + "'. No CountingOutputResourcePool with this operation exists on the board, so the player will not be able to win.");
        }
        
        for (int x = 2; x < grid.w - 3; ++x)
        {
          Griddle existing_griddle = grid.get(x, grid.h - 1);
          
          if (!(existing_griddle instanceof CountingOutputResourcePool))
          {
            CountingOutputResourcePool corp = (CountingOutputResourcePool)new_output;
            WinCondition wc = new WinCondition(output, 0, corp);
            wc.increment();
            win_conditions.add(wc); //<>//
            
            grid.set(x,grid.h - 1, corp);
            break;
          }
        }
      }
    }
  }
  
  void create_new()
  {
    int w = (int)random(10, 16);
    int h = (int)random(10, 16);
    
    Rule rule = globals.ruleFactory.get_all_curses().filter_by_all_tags(new String[]{"basic", "recipe"}).get_random();
    rules = new RuleManager();
    rules.put(rule);
    
    JSONObject ov = new JSONObject();
    
    Grid gg = new Grid(new PVector(20,20), new PVector(width - 40, height - 40), w, h, this);
    
    for (int y = 1; y < h; ++y)
    {
      gg.set(0,  y,new NullGriddle());
      gg.set(w-1,y,new NullGriddle());
    }

    gg.set(1,h-1, globals.gFactory.create_griddle("GoldIngotOutput", this));
    
    for (int x = 2; x < w - 1; ++x)
      gg.set(x, h-1, new NullGriddle());
    
    ov = JSONObject.parse("{ 'resources': { 'Iron Ore': 5, 'Cobalt Ore': 5, 'Gold Speck': 1 } }");
    gg.set(0,0,globals.gFactory.create_griddle("RandomResourcePool", ov, this));
    
    for (int x = 1; x < w - 1; ++x)
      gg.set(x,0, globals.gFactory.create_griddle("GrabberBelt", this));
    
    ov = JSONObject.parse("{ 'automatic': true, 'speed': 0.005 }");
    gg.set(w - 1, 0, globals.gFactory.create_griddle("TrashCompactor",ov, this));
    
    for (int y = 1; y < h - 6; ++y)
      gg.set(w - 1, y, new NullGriddle(this));
    
    player = new Player(this);
            
    player.spritename = globals.gFactory.get_spritename("Player");
    player.sprite = globals.sprites.get_sprite(player.spritename);
    player.pos = gg.absolute_pos_from_grid_pos(new IntVec(w / 2,h / 2));
    player.dim = gg.get_square_dim();
    
    grid = gg;
    
    grid.apply_alterations();
    conform_to_rules(); //TODO: this might not need to be here, but need to confirm
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
      state = GameState.WON_PLAYLEVEL;
    
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
      state = GameState.LOST_PLAYLEVEL;
  }
  
  void win_level()
  {
    ++rounds_completed;
    
    for (WinCondition wc : win_conditions)
      wc.increment();

    //get a boon every 10 rounds
    if (rounds_completed % 10 == 0)
    {
      RuleMenuGameFlow rmgf = new RuleMenuGameFlow();
      rmgf.ruletype = RuleType.BOON;
      rmgf.options = rules.get_available_boons().shuffle().top(3).names();
      rmgf.load();
      
      globals.game.push(rmgf, new Message("boon", "Congrats! Choose a boon."));
    }
    
    //get a curse every 4 rounds (ignored during boon rounds, such as round 20 and 40)
    else if (rounds_completed % 4 == 0)
    {
      RuleMenuGameFlow rmgf = new RuleMenuGameFlow();
      rmgf.ruletype = RuleType.CURSE;
      rmgf.options = rules.get_available_curses().shuffle().top(3).names();
      rmgf.load();
      
      globals.game.push(rmgf, new Message("curse", "Congrats! Choose a curse."));
    }
    globals.game.push(new MessageScreenGameFlow(), new Message("win","You won!")); 
    
    player.ng = null; 
    nongriddles.clear(); 
    nongriddles_to_delete.clear(); 
    
    grid = get_LevelEditor_from_level(grid); 
    
    state = GameState.LEVELEDITOR;
  }
  
  void lose_level()
  {
    globals.game.push(new MessageScreenGameFlow(), new Message("lose", "You lost!"));
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
