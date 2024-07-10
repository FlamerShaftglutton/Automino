interface GameFlow
{
  void update();
  void draw();
  void save();
  void load();
  Message exit();
  void onFocus(Message message);
}

class GameFlowManager
{
  ArrayList<GameFlow> flows;
  
  GameFlowManager() { flows = new ArrayList<GameFlow>(); }
  
  void push(GameFlow flow, Message message) { flows.add(flow); flow.onFocus(message); }
  void push(GameFlow flow, String message) { flows.add(flow); flow.onFocus(new Message("", message)); }
  void push(GameFlow flow) { push(flow, ""); }
  
  GameFlow active() { if (flows.isEmpty()) exit(); return flows.get(flows.size() - 1); }
  
  void pop() 
  {
    GameFlow gf = flows.remove(flows.size()-1); 
    
    Message message = gf.exit();
    
    if (flows.isEmpty())
      exit();
    else
      active().onFocus(message);
  }
  
  GameFlow get(int i) { if (i >= size() || i < 0) return null; return flows.get(i); }
  int size() { return flows.size(); }
}

class CardPickMenu implements GameFlow
{
  ArrayList<CardPickMenuCard> cards = new ArrayList<CardPickMenuCard>();
  color background_color = color(200);
  String title = "";
  int selected_index = 0;
  String return_target;
  
  void addCard(CardPickMenuCard card) { cards.add(card); }
  void addCard(String title, String description, String return_value, color bg, color text_color, PShape sprite) { addCard(new CardPickMenuCard(title, description, return_value, bg, text_color,sprite)); }
  void addCard(String title, String description, String return_value, color bg, color text_color) { addCard(new CardPickMenuCard(title, description, return_value, bg, text_color)); }
  void addCard(String title, String description, color bg, PShape sprite) { addCard(new CardPickMenuCard(title, description, title, bg, color(0,0,0,255),sprite)); }
  void addCard(String title, String description, color bg) { addCard(new CardPickMenuCard(title, description, title, bg, color(0,0,0,255))); }
  void addCard(String title, String description, String return_value, PShape sprite) { addCard(title, description, return_value, random_color(), color(0,0,0,255),sprite); }  
  void addCard(String title, String description, String return_value) { addCard(title, description, return_value, random_color(), color(0,0,0,255)); }
  void addCard(String title, String description, PShape sprite) { addCard(title, description, title,sprite); }
  void addCard(String title, String description) { addCard(title, description, title); }
  void addCard(String title, PShape sprite) { addCard(title, "",sprite); }
  void addCard(String title) { addCard(title, ""); }
  void addCards(StringList titles) { for (String s : titles) addCard(s); }
  
  void handle_card_select() { globals.game.pop(); }
  
  void update()
  {
    if (globals.keyboard.is_key_released('y') || globals.keyboard.is_key_released('x'))
      handle_card_select();
    else if (globals.keyboard.is_key_released('q'))
      globals.game.pop();
    else if (globals.keyboard.is_coded_key_pressed(LEFT) && selected_index > 0)
    {
      --selected_index;
      redistribute();
    }
    else if (globals.keyboard.is_coded_key_pressed(RIGHT) && selected_index < cards.size() - 1)
    {
      ++selected_index;
      redistribute();
    }
  }
  
  void redistribute()
  {
    PVector card_dim = new PVector(width / 6f, height / 4f);
    
    for (CardPickMenuCard c : cards)
      c.dim = card_dim.copy();
    
    //center and expand the selected card
    CardPickMenuCard selected_card = cards.get(selected_index);
    selected_card.dim = card_dim.copy().mult(1.5f);
    selected_card.pos = new PVector(width / 2f, height / 2f);
    
    //now do the left side
    PVector lpos = new PVector(card_dim.x, height /2f);
    PVector rpos = selected_card.pos.copy().sub(selected_card.dim.x,0f);
    if (selected_index == 1)
      cards.get(0).pos = PVector.lerp(lpos, rpos, 0.5f);
    else for (int x = 0; x < selected_index; ++x)
      cards.get(x).pos = PVector.lerp(lpos, rpos, x / float(selected_index-1));
    
    //finally do the right side
    lpos = selected_card.pos.copy().add(selected_card.dim.x, 0f);
    rpos = new PVector(width - card_dim.x, height / 2f);
    
    if (selected_index == cards.size() - 2)
      cards.get(cards.size() - 1).pos = PVector.lerp(lpos, rpos, 0.5f);
    else for (int x = selected_index + 1; x < cards.size(); ++x)
      cards.get(x).pos = PVector.lerp(lpos, rpos, (x - selected_index - 1) / float(cards.size() - selected_index - 2));
  }
  
  void draw()
  {
    background(background_color);
    
    if (title.length() > 0)
    {
      fill(0);
      textSize(72);
      textAlign(CENTER,CENTER);
      text(title, width * 0.5f, height * 0.2f);
    }
    
    for (int x = 0; x < selected_index; ++x)
      cards.get(x).draw();
      
    for (int x = cards.size() - 1; x > selected_index; --x)
      cards.get(x).draw();
      
    CardPickMenuCard selected_card = cards.get(selected_index);
    selected_card.draw();
    
    if (selected_card.description.length() > 0)
    {
      fill(0);
      int text_size = 24;
      textSize(text_size);
      textAlign(CENTER,CENTER);
      StringList chunks = wrap_string(selected_card.description, width * 0.8f);
      
      for (int i = 0; i < chunks.size(); ++i)
        text(chunks.get(i), width * 0.5f, height * 0.8f + text_size * i * 1.1f);
    }
  }
  
  void save() { }
  void load() { redistribute(); }
  Message exit() { return new Message(return_target, cards.get(selected_index).return_value); }
  void onFocus(Message message) { redistribute(); if (title == null || title.length() == 0) title = message.value; if (return_target == null || return_target.length() == 0) return_target = message.target; if (return_target.length() == 0) return_target = "select"; }

  class CardPickMenuCard
  {
    String title;
    String description;
    String return_value;
    color bg;
    color text_color;
    PVector pos;
    PVector dim;
    PShape sprite;
    
    CardPickMenuCard(String title, String description, String return_value, color bg, color text_color, PShape sprite)
    {
      this.title = title;
      this.description = description;
      this.return_value = return_value;
      this.bg = bg;
      this.text_color = text_color;
      this.sprite = sprite;
      
      pos = new PVector(0,0);
      dim = new PVector(100,100);
    }
    
    CardPickMenuCard(String title, String description, String return_value, color bg, color text_color) { this(title,description,return_value,bg,text_color,null); }
    
    void draw()
    {
      fill(bg);
      strokeWeight(3f);
      stroke(255);
      rect(pos.x - dim.x * 0.5f, pos.y - dim.y * 0.5f, dim.x, dim.y);
      
      float text_y_pos = pos.y;
      
      if (sprite != null)
      {
        text_y_pos -= dim.y * 0.4f;
        
        shape(sprite, pos.x - dim.x * 0.4f, pos.y - dim.y * 0.3f, dim.x * 0.8f, dim.x * 0.8f);
      }
      
      textSize(text_size_to_fit(title, dim.x * 0.9f));
      textAlign(CENTER,CENTER);
      fill(text_color);
      text(title, pos.x, text_y_pos);
    }
  }
}

class PauseMenu extends CardPickMenu
{
  void load()
  {
    title = "Paused";
    return_target = "resume";
    selected_index = 1;
    
    cards = new ArrayList<CardPickMenuCard>();
    color rc = random_color();
    
    addCard("Resume","", random_color(rc, 0.1));
    addCard("Rules","", random_color(rc, 0.1));
    addCard("Quit","", random_color(rc, 0.1));
    
    super.load();
  }
  
  void onFocus(Message message) { load(); } 
  
  void handle_card_select()
  {
    switch (cards.get(selected_index).title)
    {
      case "Resume": globals.game.pop(); break;
      case "Quit": return_target = "quit"; globals.game.pop(); break;
      case "Rules":
        //get the rule list by crawling up the game stack until we find the GameSession. Not very elegant, but it's probably better than passing the list around.
        RuleList rules = null;
        
        for (int i = globals.game.size() - 2; i >= 0; --i)
        {
          GameFlow gf = globals.game.get(i);
          
          if (gf instanceof GameSession)
          {
            rules = ((GameSession)gf).rules.get_rules();
            break;
          }
        }
        
        if (rules == null)
        {
          println("Something's messed up with the Rules button in the pause menu.");
          return;
        }
        
        CardPickMenu cpm = new CardPickMenu();
        
        for (Rule r : rules.rules)
          cpm.addCard(r.name,r.description, r.type == RuleType.CURSE ? random_color(#babaf6, 0.03) : random_color(#f6edba, 0.03));
        
        globals.game.push(cpm, new Message("none", "Active Rules"));
        
      break;
    }
  }
}

class GridGameFlowBase implements GameFlow
{
  Grid grid;// = new Grid(new PVector(20f,20f), new PVector(width * 0.75f, height - 40f), this);
  String save_path;
  Player player;
  
  ArrayList<NonGriddle> nongriddles = new ArrayList<NonGriddle>();
  ArrayList<NonGriddle> nongriddles_to_delete = new ArrayList<NonGriddle>();
  
  ArrayList<Toast> toasts = new ArrayList<Toast>();
  
  void update()
  {
    player.update();
    grid.update(this);
    
    for (NonGriddle dng : nongriddles_to_delete)
      nongriddles.remove(dng);
  
    nongriddles_to_delete.clear();
    
    for (Message m = globals.messages.consume_message(); m != null; m = globals.messages.consume_message())
    {
      ////DEBUG
      //println("Message '" + m.target + "' = '" + m.value + "', caller: " + (m.sender == null ? "null" : "not null"));
      
      handle_message(m);
    }
    
    for (int i = 0; i < toasts.size(); ++i)
    {
      Toast t = toasts.get(i);
      
      t.time_used += 0.01f;
      
      if (t.time_used >= t.time_to_display)
      {
        toasts.remove(i);
        --i;
      }
    }
  }
  
  void draw()
  {
    grid.draw();
    player.draw();
    
    for (NonGriddle ng : nongriddles)
      ng.draw();
      
    for (int i = 0; i < toasts.size(); ++i)
    {
      Toast t = toasts.get(i);
      
      textSize(14);
      fill(color(0,0,0, 255 * ((t.time_to_display - t.time_used) / t.time_to_display)));
      textAlign(CENTER,CENTER);
      text(t.text_to_display, width * 0.8f, height - 16f * (i + 1));
    }
  }
  
  void handle_message(Message message) { }
  
  Message exit()
  {
    return new Message();
  }
  
  void onFocus(Message message)
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
    Grid gg = new Grid(new PVector(20,20), new PVector(width - 40f, height - 40), this);
    
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
    
    retval.dim = grid.get_square_dim().mult(0.4f);
    
    register_ng(retval);
    
    return retval;
  }
  
  void register_ng(NonGriddle ng) { nongriddles.add(ng); }
  
  void destroy_ng(NonGriddle ng)
  {
    nongriddles_to_delete.add(ng);
  }
}

class MainMenuGameFlow extends GridGameFlowBase
{
  void update()
  {
    super.update();
    
    if (globals.keyboard.is_key_released('q')) 
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
  
  void onFocus(Message message)
  {
    load();
  }
}

class MessageScreenGameFlow implements GameFlow
{
  Message received;
  
  void update() { if (globals.keyboard.is_key_released('y')) globals.game.pop(); }
  void draw()
  {
    fill(color(255,255,255,100));
    stroke(color(0,0,0,100));
    
    rect(width * 0.2, height * 0.2, width * 0.6, height * 0.6, 10f);

    fill(0);
    
    textSize((int)height / 8);
    textAlign(CENTER,CENTER);
    text(received.value, width * 0.5f, height * 0.4f);
    
    textSize((int)height / 32);
    text("Press Y to continue", width * 0.5f, height * 0.6f);
  }
  void save() { }
  void load() { }
  Message exit() { return received; }
  void onFocus(Message message) { this.received = message; }
}

class Toast
{
  String text_to_display;
  float time_to_display;
  float time_used;
  
  Toast(String text_to_display, float time_to_display) { this.text_to_display = text_to_display; this.time_to_display = time_to_display; }
  Toast() { this("", 0f); }
}
