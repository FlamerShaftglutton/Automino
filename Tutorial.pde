class Tutorial extends GameSession
{
  IntDict flags;
  ArrayList<TutorialStep> steps;
  PVector previous_player_pos;
  
  Tutorial() { flags = new IntDict(); steps = new ArrayList<TutorialStep>(); }
  
  int get_flag(String k) { if (!flags.hasKey(k)) return 0; return flags.get(k); }
  void increment_flag(String k) { flags.set(k, get_flag(k) + 1); }
  
  PVector get_toast_window_pos() { return grid.get_pos().add(grid.get_dim().x, 0f); }
  PVector get_toast_window_dim() { return new PVector(width,height).sub(get_toast_window_pos()); }
  
  void start_level()
  {
    if (steps.isEmpty())
    {
      grid.set(0,0,globals.gFactory.create_griddle("RandomResourcePool",this));
      
      save_path = dataPath(save_filename());
      
      save();
      
      GameSession newgame = new GameSession();
      newgame.save_path = save_path;
      newgame.rules = rules;
      newgame.load();
      globals.game.pop();
      globals.game.push(newgame);
    }
    else
      super.start_level();
  }
  
  void update_flags()
  {
    //check on the steps
    TutorialStep step = steps.get(0);
    
    if (step.variable.startsWith("Key"))
    {
      String[] chunks = step.variable.split(":");
      
      switch (chunks[0])
      {
        case "KeyPressed":  flags.set(step.variable, globals.keyboard.is_key_pressed (chunks[1].charAt(0)) ? 1 : 0); break;
        case "KeyHeld":     flags.set(step.variable, globals.keyboard.is_key_held    (chunks[1].charAt(0)) ? 1 : 0); break;
        case "KeyReleased": flags.set(step.variable, globals.keyboard.is_key_released(chunks[1].charAt(0)) ? 1 : 0); break;
      }
    }
    
    
    if (player.pos.dist(previous_player_pos) >= 1f)
      flags.set("PlayerSteps", get_flag("PlayerSteps"));
      
    
    if (step.variable.startsWith("Held"))
    {
      String[] chunks = step.variable.split(":");
      
      if (chunks.length > 2)
      {
        if (chunks[1].equals("Player") || chunks[1].equals("player"))
        {
          if (player.ng != null)
          {
            flags.set("Held:player:none",0);
            flags.set("Held:player:any", 1);
            flags.set("Held:player:" + player.ng.name, 1);
          
            //if (chunks[2].equals("any") || chunks[2].equals(player.ng.name))
            //  flags.set(step.variable, 1);
          }
          else
          {
            flags.set("Held:player:any", 0);
            flags.set("Held:player:none", 1);
            
            if (!chunks[2].equals("any") && !chunks[2].equals("none"))
              flags.set("Held:player:" + chunks[2], 0);
          }
        }
        else
        {
          String[] coords = chunks[1].split(",");
          
          if (coords.length > 1)
          {
            int x = parseInt(coords[0]);
            int y = parseInt(coords[1]);
            
            Griddle griddy = grid.get(x,y);
            
            if (griddy.ngs.isEmpty())
            {
              flags.set(step.variable, 0);
              flags.set(chunks[0] + ":" + chunks[1] + ":any", 0);
              flags.set(chunks[0] + ":" + chunks[1] + ":none", 1);
            }
            else
            {
              flags.set("Held:" + x + "," + y + ":none",0);
              flags.set("Held:" + x + "," + y + ":any",1);
              
              int num_match = 0;
              for (NonGriddle ng : griddy.ngs)
              {
                if (ng.name.equals(chunks[2]))
                  ++num_match;
              }
              
              flags.set(step.variable, num_match);
            }
          }
        }
      }
    }
  }
  
  void check_current_step()
  {
    update_flags();
    
    TutorialStep step = steps.get(0);
    
    //check if the step is complete
    int current_val = get_flag(step.variable);
    
    boolean done = false;
    switch (step.operator)
    {
      case "<"  : done = current_val <  step.amount; break;
      case "<=" : done = current_val <= step.amount; break;
      case ">"  : done = current_val >  step.amount; break;
      case ">=" : done = current_val >= step.amount; break;
      case "=" : case "==": done = current_val == step.amount; break;
      case "!=": case "<>": done = current_val != step.amount; break;
    }
    
    if (done)
    {
      steps.remove(0);
      
      toasts.clear();
      
      if (steps.isEmpty())
      {
        start_level();
        return;
      }
      
      toasts.add(new Toast(steps.get(0).description, 100));
    }
  }
  
  void update()
  {
    super.update();
    
    RewardGriddle rg = rewards.get(4);
    if (rg.running && rg.time_used > rg.time_needed * 0.5f)
      rg.time_used = rg.time_needed * 0.5f;
    
    //keep the toasts alive
    for (Toast t : toasts)
      t.time_used = 0f;
    
    check_current_step();
  }
  
  void draw()
  {
    super.draw();
    
    if (!steps.isEmpty())
    {
      TutorialStep step = steps.get(0);
      
      if (!step.spots_to_highlight.isEmpty())
      {
        noFill();
        strokeWeight(4f);
        
        for (TutorialStep.TutorialStepHighlight th : step.spots_to_highlight)
        {
          stroke(th.border_color);
          PVector square_dim = grid.get_square_dim();
          PVector top_left = grid.absolute_pos_from_grid_pos(th.pos).sub(square_dim.copy().mult(0.5f));
          PVector highlight_dim = (th.dim.toPVec().mult(square_dim.x)).add(10f, 10f);
          rect(top_left.x - 5f, top_left.y -5f, highlight_dim.x, highlight_dim.y, 5f);
        }
      }
    }
  }
  
  void handle_message(Message message) { super.handle_message(message); }
  
  void onFocus(Message message)
  {
    super.onFocus(message);
  }
  
  void load()
  {
    deserialize(loadJSONObject(save_path));
    
    //state = GameState.PLAYLEVEL;
    start_level();
    
    previous_player_pos = player.pos; 
    
    toasts.add(new Toast(steps.get(0).description, 100));
  }
  
  void deserialize(JSONObject root)
  {
    super.deserialize(root);
    
    JSONArray jsteps = root.getJSONArray("steps");
    for (int i = 0; i < jsteps.size(); ++i)
    {
      JSONObject step = jsteps.getJSONObject(i);
      
      TutorialStep ts = new TutorialStep(step);
      
      int order = step.getInt("order",i);

      if (order == i)
        steps.add(ts);
      else
      {
        for (int ii = steps.size(); ii <= order; ++ii)
          steps.add(new TutorialStep());
        
        steps.set(order, ts);
      }
    }
  }
  
  void register_ng(NonGriddle ng) { super.register_ng(ng); increment_flag("Resource:"+ng.name); }

  void lose_level() { }
  
  void win_level()
  {
    super.win_level();
    
    flags.set("Won",1);
  }
  
  

  
  class TutorialStep
  {
    String description;
    
    String variable;
    
    ArrayList<TutorialStepHighlight> spots_to_highlight = new ArrayList<TutorialStepHighlight>();
    
    String operator; //this should be deserialized into an enum, similar to the Rule Modifiers, but legibility is far more important here than performance since it's just the tutorial.
    
    int amount;
    
    TutorialStep(String description, String variable, String operator, int amount, ArrayList<TutorialStepHighlight> spots_to_highlight) { this.description = description; this.variable = variable; this.operator = operator; this.amount = amount; this.spots_to_highlight = spots_to_highlight; }
    TutorialStep() { this("","","",0, new ArrayList<TutorialStepHighlight>()); }
    TutorialStep(String description, String expression) { this(description,expression, new ArrayList<TutorialStepHighlight>()); }
    TutorialStep(String description, String expression, ArrayList<TutorialStepHighlight> spots_to_highlight)
    {
      String[] chunks = split_respecting_quoted_whitespace(expression);
      
      if (chunks.length == 1)
      {
        this.variable = chunks[0];
        this.operator = ">";
        this.amount = 0;
      }
      else if (chunks.length == 3) 
      {
        this.variable = chunks[0];
        this.operator = chunks[1];
        this.amount = parseInt(chunks[2]);
      }
      else
        println("Error: Tutorial Step expression cannot be parsed. Value '" + expression + "' with description '" + description);
      
      this.description = description;
      this.spots_to_highlight = spots_to_highlight;
    }
    TutorialStep(JSONObject o)
    {
      this(o.getString("description",""), o.getString("expression")); 
      
      if (o.hasKey("highlight"))
      {
        Object mo = o.get("highlight");
        
        if (mo instanceof JSONArray)
        {
          JSONArray moa = (JSONArray)mo;
          
          for (int i = 0; i < moa.size(); ++i)
            spots_to_highlight.add(new TutorialStepHighlight(moa.getJSONObject(i)));
        }
        else if (mo instanceof JSONObject)
          spots_to_highlight.add(new TutorialStepHighlight((JSONObject)mo));
      }
    }
    
    class TutorialStepHighlight
    {
      IntVec pos;
      IntVec dim;
      color border_color;
      
      TutorialStepHighlight(IntVec pos, IntVec dim, color border_color)
      {
        this.pos = pos.copy();
        this.dim = dim.copy();
        this.border_color = border_color;
      }
      
      TutorialStepHighlight(JSONObject jo)
      {
        int x = 0;
        int y = 0;
        int w = 1;
        int h = 1;
        border_color = color(255,0,0,180);
        
        if (jo.hasKey("pos"))
        {
          JSONObject jjo = jo.getJSONObject("pos");
          x = jjo.getInt("x");
          y = jjo.getInt("y");
        }
        
        if (jo.hasKey("x"))
          x = jo.getInt("x");
        
        if (jo.hasKey("y"))
          y = jo.getInt("y");
        
        if (jo.hasKey("dim"))
        {
          JSONObject jjo = jo.getJSONObject("dim");
          w = jjo.getInt("w", jjo.getInt("x"));
          h = jjo.getInt("h", jjo.getInt("y"));
        }
        
        if (jo.hasKey("w"))
          w = jo.getInt("w");
        
        if (jo.hasKey("h"))
          h = jo.getInt("h");
        
        if (jo.hasKey("color") || jo.hasKey("border_color"))
        {
          int icol = unhex(jo.getString("color", jo.getString("border_color")));
          
          border_color = color(red(icol), green(icol), blue(icol), 180);
        }
        
        pos = new IntVec(x,y);
        dim = new IntVec(w,h);
      }
    }
  }
}
