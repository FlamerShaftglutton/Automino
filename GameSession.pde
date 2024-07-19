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
    
    if (globals.keyboard.is_key_released('p'))
      globals.game.push(new PauseMenu(this));
    
    switch (state)
    {
      case STARTING_PLAYLEVEL: start_level(); break;
      case PLAYLEVEL: check_for_level_end(); break;
      case LEVELEDITOR: level_editor(); break;
      case WON_PLAYLEVEL: win_level(); break;
      case LOST_PLAYLEVEL: lose_level(); break;
      case MENU: start_level_editor(); break;
    }
  }
  
  void level_editor()
  {
    if (globals.keyboard.is_key_released('y')) 
    { 
      boolean is_free_to_start = false;
      
      IntVec player_grid_pos = grid.grid_pos_from_absolute_pos(player.pos);
      Griddle griddle_player_is_standing_on = grid.get(player_grid_pos);
      if (player_grid_pos.x > 0 && player_grid_pos.y > 0 && player_grid_pos.x < grid.w - 1 && player_grid_pos.y < grid.h - 1 && griddle_player_is_standing_on instanceof LevelEditorGriddle)
      {
        LevelEditorGriddle leg_player_is_standing_on = (LevelEditorGriddle)griddle_player_is_standing_on;
        
        is_free_to_start = leg_player_is_standing_on.ngs.isEmpty();
      }
      
      if (is_free_to_start)
      {
        save(); 
        nongriddles.clear(); 
        nongriddles_to_delete.clear();
        load(); 
        state = GameState.STARTING_PLAYLEVEL; 
      }
    }
  }
  
  void onFocus(Message message)
  {
    if (message.target.equals("lose") || message.target.equals("quit"))
      globals.game.pop();
    else if (message.target.equals("upgrade") && !message.value.equals("cancel") && to_upgrade != null)
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
      float internal_walls_old = rules.get_float("Walls:Internal",0.125f);
      int gold_offset_old = rules.get_int("Gold");
      
      rules.put(globals.ruleFactory.get_rule(message.value));
      
      float internal_walls_new = rules.get_float("Walls:Internal",0.125f);
      int gold_offset_new = rules.get_int("Gold");
      
      if (abs(internal_walls_old - internal_walls_new) > 0.01f)
        update_internal_walls(internal_walls_old, internal_walls_new);
      
      if (gold_offset_new != gold_offset_old)
        spend_gold(gold_offset_old - gold_offset_new);
      
      conform_to_rules();
    }
  }
  
  void update_internal_walls(float old_value, float new_value)
  {
    grid.apply_alterations();
    
    //erase all walls if the value lowered. This should be more granular, but it won't be anytime soon.
    if (old_value > new_value)
    {
      for (int y = 1; y < grid.h - 1; ++y)
      {
        for (int x = 1; x < grid.w - 1; ++x)
        {
          Griddle walley = grid.get(x,y);
          
          if (walley instanceof WallGriddle)
          {
            if (state == GameState.LEVELEDITOR)
              grid.set(x,y,new LevelEditorGriddle(this));
            else
              grid.set(x,y,globals.gFactory.create_griddle("EmptyGriddle",this));
          }
        }
      }
    }
    //add new walls
    else if (old_value < new_value)
    {
      //this could be very easy, just grab the list of EmptyGriddles from the grid, shuffle it, and plop a WallGriddle in the top X spots.
      //But this could lead to inaccessible points, especially points containing vital griddles. So we're going to do some pathfinding to ensure each addition does not lock the player out of anything
      float extra_walls_percent = new_value - old_value;
      
      int num_extra_walls = (int)random(1, grid.w * grid.h * extra_walls_percent);
      int r = 0;
      
      //set up a bitmap of the existing walls to A: make sure we don't overlap and B: do some basic pathfinding to make sure nothing is locked behind walls.
      BitGrid walls = grid.get_map_of_type(WallGriddle.class);
      while (r < num_extra_walls)
      {
        IntVec random_pos = new IntVec((int)random(2,grid.w - 2), (int)random(2,grid.h-2));
        
        Griddle gg = grid.get(random_pos);
        
        if (!walls.get_bit(random_pos.x, random_pos.y) && gg instanceof EmptyGriddle || (gg instanceof LevelEditorGriddle && ((LevelEditorGriddle)gg).ngs.isEmpty()))
        {
          //pathfind from each of the four surrounding spots to 0,0 to make sure this doesn't trap anything
          boolean traps_spaces = false;
          for (IntVec offset : orthogonal_offsets())
          {
            IntVec off = offset.copy().add(random_pos);
            if (!walls.get_bit(off.x, off.y) && shortest_path(off, new IntVec(0,0), walls).size() == 0)
            {
              traps_spaces = true;
              break;
            }
          }
          
          if (!traps_spaces)
          {
            grid.set(random_pos, globals.gFactory.create_griddle("WallGriddle", this));
            walls.set_bit(random_pos.x, random_pos.y);
            ++r;
          }
        }
      }
    }
    
    grid.apply_alterations();
  }
  
  void handle_message(Message message)
  {
    if (message.target.equals("upgrade"))
    {
      to_upgrade = (Griddle)message.sender;
      
      StringList upgrades = globals.gFactory.get_upgrades(message.value);
      
      if (upgrades.size() > 0)
      {
        CardPickMenu cpm = new CardPickMenu();
        for (String s : upgrades)
          cpm.addCard(s, globals.gFactory.get_description(s), globals.sprites.get_sprite(globals.gFactory.get_spritename(s)));
        
        cpm.addCard("Cancel", "Return without upgrading or spending your gold"); //<>//
        
        globals.game.push(cpm, new Message("upgrade","Choose an upgrade"));
      }
    }
    if (message.target.equals("info"))
      toasts.add(new Toast(message.value, 5f));
  }
  
  //note that this can be called during game creation or during level editing
  void conform_to_rules()
  {
    grid.apply_alterations(); //<>//
    
    StringList required_operations = rules.get_strings("Required:Operations");
    StringList required_outputs    = rules.get_strings("Required:Outputs");
    
    StringList found_outputs = new StringList();
    StringList found_operations = new StringList();
    for (int x = 0; x < grid.w; ++x)
    {
      for (int y = 0; y < grid.h; ++y)
      {
        Griddle eg = grid.get(x,y);
        
        if (eg instanceof Transformer)
        {
          found_operations.append(((Transformer)eg).operations);
        }
        else if (eg instanceof CountingOutputResourcePool)
        {
          found_outputs.append(((CountingOutputResourcePool)eg).ng_type);
        }
        else if (eg instanceof LevelEditorGriddle)
        {
          LevelEditorGriddle leg = (LevelEditorGriddle)eg;
          
          if (leg.ng() != null)
          {
            LevelEditorNonGriddle leng = (LevelEditorNonGriddle)leg.ng();
            
            found_operations.append(getStringList("operations", leng.as_json));
          }
        }
      }
    }
    
    StringList basic_griddles = globals.gFactory.get_names_by_tag("basic");
    for (String operation : required_operations)
    {
      if (!found_operations.hasValue(operation))
      {
        //create the missing thing in a random spot
        String basic_griddle_name = "";
        for (String basic_griddle : basic_griddles)
        {
          if (globals.gFactory.get_operations(basic_griddle).hasValue(operation))
          {
            basic_griddle_name = basic_griddle;
            //new_griddle = globals.gFactory.create_griddle(basic_griddle,this);
            break;
          }
        }
        
        if (basic_griddle_name.length() == 0)
        {
          println("Couldn't find a griddle with the 'basic' tag that had the required operation of '" + operation + "'. No transformer with this operation exists on the board, so the player will not be able to win.");
        }
        
        boolean placed = false;
        
        while (!placed)
        {
          int xx = (int)random(1,grid.w - 2);
          int yy = (int)random(1,grid.h - 2);
          
          Griddle gxxyy = grid.get(xx,yy);

          if (gxxyy instanceof LevelEditorGriddle) //<>//
          {
            LevelEditorGriddle legxxyy = (LevelEditorGriddle)gxxyy;
            
            if (legxxyy.ng() == null)
            {
              LevelEditorNonGriddle lengxxyy = globals.ngFactory.create_le_ng(basic_griddle_name);
              lengxxyy.visible = false;
              register_ng(lengxxyy);
              legxxyy.receive_ng(lengxxyy);
              
              placed = true;
            }
          }
          else if (gxxyy instanceof EmptyGriddle)
          {
            grid.set(xx,yy, globals.gFactory.create_griddle(basic_griddle_name,this));
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
        
        boolean output_placed = false;
        
        while (!output_placed)
        {
          int x = (int)random(2,grid.w - 3);
          Griddle existing_griddle = grid.get(x, grid.h - 1);
          
          if (existing_griddle instanceof WallGriddle)
          {
            CountingOutputResourcePool corp = (CountingOutputResourcePool)new_output;
            WinCondition wc = new WinCondition(output, 0, corp);
            wc.increment();
            win_conditions.add(wc);
            
            grid.set(x,grid.h - 1, corp);
            output_placed = true;
          }
        }
      }
    }
  } //<>//
  
  void create_new()
  {
    int w = (int)random(7, 40);
    int h = (int)random(7, 28);
    
    if (rules == null || rules.get_rules().size() == 0)
    {
      Rule rule = globals.ruleFactory.get_all().filter_by_all_tags("curse","basic", "recipe").get_random();
      rules = new RuleManager();
      rules.put(rule);
    }
    
    JSONObject ov = new JSONObject();
    
    grid = new Grid(new PVector(20,20), new PVector(width -40f, height - 40),w,h, this);
    
    for (int y = 1; y < h; ++y)
    {
      grid.set(0,  y,globals.gFactory.create_griddle("WallGriddle", this));
      grid.set(w-1,y,globals.gFactory.create_griddle("WallGriddle", this));
    }
    
    for (int x = 1; x < w - 1; ++x)
      grid.set(x, h-1, globals.gFactory.create_griddle("WallGriddle", this));
    
    grid.set((int)random(2,w-3),h-1, globals.gFactory.create_griddle("GoldIngotOutput", this));
    
    ov = JSONObject.parse("{ 'resources': { 'Iron Ore': 5, 'Cobalt Ore': 5, 'Gold Speck': 1 } }");
    grid.set(0,0,globals.gFactory.create_griddle("RandomResourcePool", ov, this));
    
    for (int x = 1; x < w - 1; ++x)
      grid.set(x,0, globals.gFactory.create_griddle("GrabberBelt", this));
    
    ov = JSONObject.parse("{ 'automatic': true, 'speed': 0.005 }");
    grid.set(w - 1, 0, globals.gFactory.create_griddle("TrashCompactor",ov, this));
    
    for (int y = 1; y < h - 6; ++y)
      grid.set(w - 1, y, globals.gFactory.create_griddle("WallGriddle", this));
      
    update_internal_walls(0f, rules.get_float("Walls:Internal",0.125f));
    
    player = new Player(this);
            
    player.spritename = globals.profiles.current().sprite;
    player.sprite = globals.sprites.get_sprite(player.spritename);
    player.pos = grid.absolute_pos_from_grid_pos(new IntVec(w / 2,h / 2));
    player.dim = grid.get_square_dim();
    
    grid.apply_alterations();
    conform_to_rules();
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
    int upgrades = rules.get_int("Reward:upgrades");
    
    for (int i = 0; i < rewards.size(); ++i)
    {
      RewardGriddle rg = rewards.get(i);
      String type_name;
      
      if (i == rewards.size() - 1 && rules.get_int("Reward:conveyor") > 0)
        type_name = "ConveyorBelt";
      else
        type_name = types.get((int)random(types.size()));
      
      if (i >= 5 - upgrades)
      {
        StringList uppies = globals.gFactory.get_upgrades(type_name);
        
        if (uppies.size() > 0)
        {
          uppies.shuffle();
          type_name = uppies.get(0);
        }
      }
      
      rg.reward_griddle_name = type_name;
      rg.time_used = 0f;
      rg.time_needed = 32;
      
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
      CardPickMenu cpm = new CardPickMenu();
      RuleList options = rules.get_available_boons().shuffle().top(3);
      color boon_color = #f6edba;
      for (int i = 0; i < options.size(); ++i)
        cpm.addCard(options.get(i).name, options.get(i).description, random_color(boon_color, 0.05));
      
      globals.game.push(cpm, new Message("rule", "Congrats! Choose a boon."));
    }
    
    //get a curse every 4 rounds (ignored during boon rounds, such as round 20 and 40)
    else if (rounds_completed % 4 == 0)
    {
      CardPickMenu cpm = new CardPickMenu();
      RuleList options = rules.get_available_curses().shuffle().top(3);
      color curse_color = #babaf6;
      for (int i = 0; i < options.size(); ++i)
        cpm.addCard(options.get(i).name, options.get(i).description, random_color(curse_color, 0.05));
      
      globals.game.push(cpm, new Message("rule", "Congrats! Choose a curse."));
    }
    
    globals.game.push(new MessageScreenGameFlow(), new Message("win","You won!")); 
    
    start_level_editor();
  }
  
  void start_level_editor()
  {
    player.ng = null; 
    nongriddles.clear(); 
    nongriddles_to_delete.clear();
    
    grid = get_LevelEditor_from_level(grid);
    
    state = GameState.LEVELEDITOR;
  }
  
  void lose_level()
  {
    for (String rule_name : rules.get_rules().names())
      globals.profiles.current().discovered_rules.appendUnique(rule_name);
   
    globals.profiles.current().highest_round = max(globals.profiles.current().highest_round, rounds_completed);
    globals.profiles.save();
    
    File f = new File(save_path);
    
    f.delete();
    
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
        
        if (tgg instanceof WallGriddle)
          le_grid.set(x,y,globals.gFactory.create_griddle("WallGriddle", this));
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
        
        LevelEditorGriddle leg = new LevelEditorGriddle(this);
        leg.background_color = #E09E9E;
        
        if (!rg.finished)
        {
          JSONObject tggo = globals.gFactory.create_griddle(rg.reward_griddle_name, this).serialize();
          
          LevelEditorNonGriddle leng = globals.ngFactory.create_le_ng(tggo.getString("type"));
          leng.as_json = tggo;
          leng.shape = globals.sprites.get_sprite(tggo.getString("sprite"));
          leng.visible = false;
          register_ng(leng);
          leg.receive_ng(leng);
        }
        
        leg.locked = false;
        leg.traversable = true;
        
        le_grid.set(tg.w - 1,y,leg);
      }
    }
    
    return le_grid;
  }
  
  boolean spend_gold(int amount)
  {
    ArrayList<CountingOutputResourcePool> corps = grid.get_all_of_type(CountingOutputResourcePool.class);
    
    for (CountingOutputResourcePool corp : corps)
    {
      if (corp.ng_type == "Gold Ingot")
        return corp.set_count(corp.get_count() - amount);
    }
    
    return false;
  }
  
    JSONObject serialize()
  {
    JSONObject root = super.serialize();
    
    root.setInt("rounds_completed", rounds_completed);
    
    JSONArray jarules = new JSONArray();
    for (String rule : rules.get_rules().names())
      jarules.append(rule);
    
    root.setJSONArray("Rules", jarules);
    
    return root;
  }
  
  void deserialize(JSONObject root)
  {    
    super.deserialize(root);
    
    rules = new RuleManager();
    
    rounds_completed = root.getInt("rounds_completed");
    
    JSONArray jarules = root.getJSONArray("Rules");
    
    for (int i = 0; i < jarules.size(); ++i)
      rules.put(globals.ruleFactory.get_rule(jarules.getString(i)));
    
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
