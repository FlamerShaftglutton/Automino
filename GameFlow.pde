interface GameFlow
{
  void update();
  void draw();
  void save();
  void load();
  String exit();
  void onFocus(String message);
}

class GameFlowManager
{
  ArrayList<GameFlow> flows;
  
  GameFlowManager() { flows = new ArrayList<GameFlow>(); }
  
  void push(GameFlow flow, String message) { flows.add(flow); flow.onFocus(message); }
  void push(GameFlow flow) { push(flow, ""); }
  
  GameFlow active() { return flows.get(flows.size() - 1); }
  
  void pop() 
  {
    GameFlow gf = flows.remove(flows.size()-1); 
    
    String message = gf.exit();
    
    if (flows.isEmpty())
      exit();
    else
      active().onFocus(message);
  }
}

class GridGameFlowBase implements GameFlow
{
  Grid grid;
  String save_path;
  Player player;
  
  ArrayList<NonGriddle> nongriddles = new ArrayList<NonGriddle>();
  ArrayList<NonGriddle> nongriddles_to_delete = new ArrayList<NonGriddle>();
  
  void update()
  {
    player.update();
    grid.update(this);
    
    for (NonGriddle dng : nongriddles_to_delete)
      nongriddles.remove(dng);
  
    nongriddles_to_delete.clear();
    
    for (Message m = globals.messages.consume_message(); m != null; m = globals.messages.consume_message())
    {
      //println("Message '" + m.target + "' = '" + m.value + "', caller: " + (m.sender == null ? "null" : "not null"));
      handle_message(m);
    }
  }
  
  void draw()
  {
    grid.draw();
    player.draw();
    
    for (NonGriddle ng : nongriddles)
      ng.draw();
  }
  
  void handle_message(Message message) { }
  
  String exit()
  {
    return "";
  }
  
  void onFocus(String message)
  {
    
  }
  
  void save()
  {
    saveJSONObject(serialize(), save_path);
  }
  
  void load()
  {
    deserialize(loadJSONObject(save_path));
  }
  
  JSONObject serialize()
  {
    JSONObject root = new JSONObject();
    
    PlayerGriddle griddy = new PlayerGriddle(this);
    griddy.spritename = player.spritename;
    IntVec pgp = grid.grid_pos_from_absolute_pos(player.pos);
    grid.set(pgp.x, pgp.y, griddy);
    
    grid.apply_alterations();
    
    root.setJSONObject("grid", grid.serialize());
    
    return root;
  }
  
  void deserialize(JSONObject root)
  {    
    Grid gg = new Grid(new PVector(20,20), new PVector(width - 40, height - 40), this);
    
    gg.deserialize(root.getJSONObject("grid"), this);
    
    grid = gg;
    
    player = null;
    for (int x = 0; x < gg.w && player == null; ++x)
    {
      for (int y = 0; y < gg.h && player == null; ++y)
      {
        Griddle gr = gg.get(x,y);
        
        if (gr instanceof PlayerGriddle)
        {
          player = new Player(this);
          player.spritename = gr.spritename;
          player.sprite = gr.sprite;
          player.pos = gg.absolute_pos_from_grid_pos(new IntVec(x,y));
          player.dim = gg.get_square_dim();
          
          grid.set(x,y,new EmptyGriddle(this));
        }
      }
    }
    
    grid.apply_alterations();
  }
  
  NonGriddle create_and_register_ng(String name)
  {
    NonGriddle retval = globals.ngFactory.create_ng(name);
    
    register_ng(retval);
    
    return retval;
  }
  
  void register_ng(NonGriddle ng) { nongriddles.add(ng); }
  
  void destroy_ng(NonGriddle ng)
  {
    nongriddles_to_delete.add(ng);
  }
}

class UpgradeMenuGameFlow extends GridGameFlowBase
{
  StringList options = new StringList();
  String outgoing_message = "cancel";
  
  void handle_message(Message message)
  {
    if (message.target.equals("select"))
      outgoing_message = message.value;
    
    if (message.target.equals("select") || message.target.equals("cancel"))
      globals.game.pop();
  }
  
  String exit() { return outgoing_message; }
  
  void load()
  {
    int w,h;
    
    if (options.size() == 0)
      w = h = 5;
    else
    {
      w = (options.size() + 1) * 2 + 1;
      h = 5;
    }
    
    grid = new Grid(new PVector(100,100), new PVector(width - 200, height - 200), w, h, this);
    
    int x = 1;
    for (int i = 0; i < options.size(); ++i, x+= 2)
    {
      String option = options.get(i);
      
      MetaActionCounter mac = new MetaActionCounter(this);
      mac.traversable = false;
      mac.display_string = option;
      mac.action = "select";
      mac.parameters.append(option);
      mac.spritename = globals.gFactory.get_spritename(option);
      mac.sprite = globals.sprites.get_sprite(mac.spritename);
      
      grid.set(x, 2, mac);
    }
    
    MetaActionCounter cmac = new MetaActionCounter(this);
    cmac.traversable = false;
    cmac.template = "Cancel";
    cmac.action = "cancel";
    cmac.spritename = "null";
    cmac.sprite = globals.sprites.get_sprite("null");
    
    grid.set(x, 2, cmac);
    
    player = new Player(this);
    player.spritename = globals.gFactory.get_spritename("Player");
    player.sprite = globals.sprites.get_sprite(player.spritename);
    player.rot = HALF_PI;
    player.pos = grid.absolute_pos_from_grid_pos(new IntVec(1 + w / 2, 4));
    player.dim = grid.get_square_dim();
    
    grid.apply_alterations();
  }
}

class MainMenuGameFlow extends GridGameFlowBase
{
  void update()
  {
    super.update();
    
    if (globals.keyReleased && key == 'q') 
      globals.game.pop();
  }
  
  void handle_message(Message message)
  {
    switch (message.target)
    {
      case "newgame":
        GameSession newgame = new GameSession();
        newgame.save_path = dataPath(save_filename());
        newgame.create_new();
        globals.game.push(newgame);
        break;
      case "load":
        GameSession loadgame = new GameSession();
        loadgame.save_path = message.value;
        loadgame.load();
        globals.game.push(loadgame);
        break;
      case "debug":
        GridGameFlowBase debuggame = new GridGameFlowBase();
        debuggame.save_path = dataPath("debug.json");
        debuggame.load();
        globals.game.push(debuggame);
        break;
      case "save":
        println("Saving... psych! I ain't doing nothing'.");
        break;
    }
  }
  
  String save_filename()
  {
    String retval = "save_";
    
    retval += right("0000" + year(),4);
    retval += right("00" + month(),2);
    retval += right("00" + day(),2);
    retval += right("00" + hour(),2);
    retval += right("00" + minute(),2);
    retval += right("00" + second(),2);
    
    retval += ".json";
    
    return retval;
  }
  
  void load()
  {
    super.load();
    
    File dir = new File(dataPath(""));
    
    File[] files = dir.listFiles();
    
    int used = 0;
    for (int i = 0; i < files.length && used < grid.h; ++i)
    {
      File f = files[i];
      
      if (f.isDirectory() || !f.getName().startsWith("save") || !f.getName().endsWith("json"))
        continue;
      
      MetaActionCounter mac = (MetaActionCounter)globals.gFactory.create_griddle("MetaActionCounter", this);
      mac.display_string = "Load " + f.getName();
      mac.action = "load";
      mac.parameters.append(f.getAbsolutePath());

      grid.set(grid.w - 1, used, mac);
      
      ++used;
    }
    
    if (used >= grid.h)
    {
      for (int y = 0; y < grid.h; ++y)
      {
        for (int x = 0; x < grid.w - 1; ++x)
        {
          Griddle griddy = grid.get(x,y);
          
          if (griddy instanceof MetaActionCounter && ((MetaActionCounter)griddy).action.equals("newgame"))
            grid.set(x,y, new EmptyGriddle(this));
        }
      }
    }
  }
  
  void onFocus(String message)
  {
    load();
  }
}

class MessageScreenGameFlow implements GameFlow
{
  String message = "";
  
  void update() { if (globals.keyReleased && key == 'y') globals.game.pop(); }
  void draw()
  {
    fill(color(255,255,255,100));
    stroke(color(0,0,0,100));
    
    rect(width * 0.2, height * 0.2, width * 0.6, height * 0.6, 10f);

    fill(0);
    
    textSize((int)height / 8);
    textAlign(CENTER,CENTER);
    text(message, width * 0.5f, height * 0.4f);
    
    textSize((int)height / 32);
    text("Press Y to continue", width * 0.5f, height * 0.6f);
  }
  void save() { }
  void load() { }
  String exit() { return message; }
  void onFocus(String message) { this.message = message; }
}
