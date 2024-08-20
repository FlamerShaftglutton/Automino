interface GameFlow
{
  void update();
  void draw();
  Message exit();
  void onFocus(Message message);
}

class NullGameFlow implements GameFlow { void update() { } void draw() { } Message exit() { return new Message(); } void onFocus(Message message) { } }

class GameFlowManager
{
  ArrayList<GameFlow> flows;
  
  GameFlowManager() { flows = new ArrayList<GameFlow>(); }
  
  void push(GameFlow flow, Message message) { flows.add(flow); flow.onFocus(message); }
  void push(GameFlow flow, String message) { flows.add(flow); flow.onFocus(new Message("", message)); }
  void push(GameFlow flow) { push(flow, ""); }
  
  GameFlow active() { if (flows.isEmpty()) { exit(); return new NullGameFlow(); } else return flows.get(flows.size() - 1); }
  
  void pop() 
  {
    GameFlow gf = flows.remove(flows.size()-1); 
    
    Message message = gf.exit();
    
    if (flows.isEmpty())
      exit();
    else
      active().onFocus(message);
  }
  
  GameFlow get(int i) { if (i >= size() || i < 0) return new NullGameFlow(); return flows.get(i); }
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
    PVector card_dim = new PVector(height / 5f, height / 4f);
    
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
      rect(pos.x - dim.x * 0.5f, pos.y - dim.y * 0.5f, dim.x, dim.y, dim.x * 0.05f);
      
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
  GameSession parent;
  
  PauseMenu(GameSession parent) 
  { 
    this.parent = parent;
    
    title = "Paused";
    return_target = "resume";
    String round_reminder = "Round " + (parent.rounds_completed + 1);
    selected_index = 1;
    
    cards = new ArrayList<CardPickMenuCard>();
    color rc = random_color();
    
    addCard("Resume",round_reminder, random_color(rc, 0.1));
    addCard("Rules",round_reminder, random_color(rc, 0.1));
    addCard("Quit",round_reminder, random_color(rc, 0.1));
    
    redistribute();
  }
  
  void update()
  {
    super.update();
    
    if (globals.keyboard.is_key_released('d') && globals.keyboard.is_coded_key_held(36))
    {
      addCard("Cheat","Give yourself 100 gold",color(#FF0000));
      redistribute();
    }
  }
  
  void handle_card_select()
  {
    switch (cards.get(selected_index).title)
    {
      case "Resume": globals.game.pop(); break;
      case "Quit": return_target = "quit"; globals.game.pop(); break;
      case "Rules":
        CardPickMenu cpm = new CardPickMenu();
        
        for (Rule r : parent.rules.rules.rules)
          cpm.addCard(r.name,r.description, r.tags.hasValue("curse") ? random_color(#babaf6, 0.03) : random_color(#f6edba, 0.03));
        
        globals.game.push(cpm, new Message("none", "Active Rules"));
        
        break;
      case "Cheat":
        Grid gg = parent.grid;
        
        for (int x = 1; x < gg.w; ++x)
        {
          Griddle griddy = gg.get(x,gg.h-1);
          
          if (griddy instanceof CountingOutputResourcePool)
          {
            CountingOutputResourcePool corp = (CountingOutputResourcePool)griddy;
            
            if (corp.ng_type.equals("Gold Ingot"))
              corp.count += 100;
          }
        }
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
    
    update_toasts();
  }
  
  void update_toasts()
  {
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
    
    draw_toasts();
  }
  
  PVector get_toast_window_pos() { return new PVector(0,0); }
  PVector get_toast_window_dim() { return new PVector(width,height); }
  
  void draw_toasts()
  {
    PVector toast_window_pos = get_toast_window_pos();
    PVector toast_window_dim = get_toast_window_dim();
    
    float toast_y = toast_window_pos.y + toast_window_dim.y;
    for (int i = 0; i < toasts.size(); ++i)
    {
      Toast t = toasts.get(i);
      
      if (t.time_used >= t.time_to_display || t.time_used < 0)
        continue;
        
      noStroke();
      fill(color(255,255,255, 255 * ((t.time_to_display - t.time_used) / t.time_to_display)));
      float text_size = (int)(toast_window_dim.x / 20f);
      textSize(text_size);
      
      StringList chunks = wrap_string(t.text_to_display, toast_window_dim.x * 0.9f);
      
      float toast_width = 0f;
      for (int ii = 0; ii < chunks.size(); ++ii)
        toast_width = max(toast_width, textWidth(chunks.get(ii)) + text_size);
      
      float toast_height = text_size * 0.5f + text_size * 1.5f * chunks.size();
      
      toast_y -= toast_height + text_size;
      
      rect(toast_window_pos.x + (toast_window_dim.x - toast_width) * 0.5f, toast_y, toast_width, toast_height, 5f);
      
      fill(color(0,0,0, 255 * ((t.time_to_display - t.time_used) / t.time_to_display)));
      textAlign(CENTER,CENTER);
      for (int ii = 0; ii < chunks.size(); ++ii)
        text(chunks.get(ii), toast_window_pos.x + toast_window_dim.x * 0.5f, toast_y + text_size + ii * text_size * 1.5f);
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
          player.spritename = globals.profiles.current().sprite;
          player.sprite = globals.sprites.get_sprite(player.spritename);
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
        if ((new RuleList(globals.profiles.current().discovered_rules)).filter_by_tag("boon").size() == 0)
        {
          GameSession newgame = new GameSession();
          newgame.save_path = dataPath(save_filename());
          newgame.create_new();
          globals.game.push(newgame);
        }
        else
        {
          NewGameFlow ngf = new NewGameFlow();
          ngf.save_path = dataPath("newgamemenu.json");
          globals.game.push(ngf);
        }
        
        break;
      case "tutorial":
        Tutorial tut = new Tutorial();
        tut.save_path = dataPath("tutorial.json");
        tut.load();
        globals.game.push(tut);
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
      case "profile":
        ProfileGameFlow pgf = new ProfileGameFlow();
        pgf.save_path = dataPath("profilemenu.json");
        globals.game.push(pgf);
        break;
    }
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

class NewGameFlow extends GridGameFlowBase
{
  MetaActionCounter selecting_mac = null;
  ArrayList<MetaActionCounter> macs = new ArrayList<MetaActionCounter>();
  boolean has_loaded = false;
  
  void update()
  {
    super.update();
    
    if (globals.keyboard.is_key_released('q')) 
      globals.game.pop();
  }
  
  void handle_message(Message message)
  {
    if (message.target.equals("choose"))
    {
      selecting_mac = (MetaActionCounter)message.sender;
      RuleList rules = new RuleList(globals.profiles.current().discovered_rules).remove_all(get_selected_rules()).filter_by_all_tags(split(message.value,';'));
      
      CardPickMenu cpm = new CardPickMenu();
    
      for (Rule r : rules.rules)
        cpm.addCard(r.name,r.description, r.tags.hasValue("curse") ? random_color(#babaf6, 0.03) : random_color(#f6edba, 0.03));
        
      cpm.addCard("None", "Remove this selection", #FF9595);
      
      globals.game.push(cpm, new Message("selectedrule", "Pick a rule"));
    }
    else if (message.target.equals("startgame"))
    {
      if (ready_to_start())
      {
        globals.game.pop();
        create_new_game();
      }
      else
        toasts.add(new Toast("Must have an equal number of curses and boons selected, with at least one recipe curse.", 3.0));
    }
  }
  
  RuleList get_selected_rules()
  {
    RuleList rules = new RuleList();
    
    for (MetaActionCounter mac : macs)
    {
      if (!mac.display_string.startsWith("Choose a "))
        rules.add(mac.display_string);
    }
    
    return rules;
  }
  
  boolean ready_to_start()
  {
    int num_curses_selected = 0;
    int num_boons_selected = 0;
    
    RuleList selected_rules = get_selected_rules();
    
    for (Rule r : selected_rules.rules)
    {
      if (r.tags.hasValue("curse"))
        ++num_curses_selected;
      else
        ++num_boons_selected;
    }
    
    return num_curses_selected == num_boons_selected && num_boons_selected > 0 && selected_rules.filter_by_tag("recipe").size() > 0;
  }
  
  void create_new_game()
  {
    GameSession newgame = new GameSession();
    newgame.save_path = dataPath(save_filename());
    newgame.rules.put(get_selected_rules());
    newgame.create_new();
    globals.game.push(newgame);
  }
  
  void load()
  {
    if (has_loaded)
      return;
    
    super.load();
    
    for (int y = 0; y < grid.h; ++y)
    {
      for (int x = 0; x < grid.w; ++x)
      {
        Griddle griddy = grid.get(x,y);
        
        if (griddy instanceof MetaActionCounter)
        {
          MetaActionCounter mac = (MetaActionCounter)griddy;
          
          if (mac.action.startsWith("choose"))
            macs.add(mac);
        }
      }
    }
    
    has_loaded = true;
  }
  
  void onFocus(Message message)
  {
    load();
    
    if (message.value.equals("None"))
      selecting_mac.display_string = selecting_mac.parameters.hasValue("curse") ? "Choose a Curse" : "Choose a Boon";
    else if (message.target.equals("selectedrule"))
      selecting_mac.display_string = message.value;
      
  }
}

class ProfileGameFlow extends GridGameFlowBase
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
      case "newprofile":
        StringList names = new StringList("Stamper","Truman","Frost","Chick","Rockhound","Sharp","Oscar","Bear","Noonan","Lennert","Andropov");
        
        for (int i = 0; i < globals.profiles.size(); ++i)
          names.removeValue(globals.profiles.get(i).name);
        
        names.shuffle();
        Profile p = globals.profiles.add();
        p.name = names.get(0);
        p.sprite = "player pink";
        p.discovered_rules = new StringList("Iron Ingots","Cobalt Ingots");
        p.highest_round = 0;
        globals.profiles.set_current(p);
        load();
        break;
      case "selectprofile":
        CardPickMenu cpm = new CardPickMenu();
        
        for (Profile profile : globals.profiles.profiles)
          cpm.addCard(profile.name, "Most rounds completed: " + profile.highest_round, random_color(color(150,150,200), 0.05), globals.sprites.get_sprite(profile.sprite));
        
        globals.game.push(cpm, new Message("selectedprofile", "Pick your profile"));
        break;
      case "changesprite":
        CardPickMenu cpm2 = new CardPickMenu();
        StringList spritenames = globals.sprites.get_sprite_names();
        StringList player_spritenames = new StringList();
        
        for (String s : spritenames)
        {
          if (s.startsWith("player"))
            player_spritenames.append(s);
        }
        
        for (String spritename : player_spritenames)
          cpm2.addCard(spritename, "", random_color(color(150,150,200), 0.05), globals.sprites.get_sprite(spritename));
        
        globals.game.push(cpm2, new Message("selectedsprite", "Pick your skin"));
        break;
      case "viewrules":
        CardPickMenu cpm3 = new CardPickMenu();
        
        for (String rulename : globals.profiles.current().discovered_rules)
        {
          Rule r = globals.ruleFactory.get_rule(rulename);
          cpm3.addCard(r.name,r.description, r.tags.hasValue("curse") ? random_color(#babaf6, 0.03) : random_color(#f6edba, 0.03));
        }
        
        globals.game.push(cpm3, new Message("none", "Active Rules"));
        break;
      case "quit":
        globals.game.pop();
        break;
    }
  }
  
  void load()
  {
    super.load();
    
    for (int y = 0; y < grid.h; ++y)
    {
      for (int x = 0; x < grid.w; ++x)
      {
        Griddle gg = grid.get(x,y);
        
        if (gg instanceof MetaActionCounter)
        {
          MetaActionCounter mac = (MetaActionCounter)gg;
          
          if (mac.display_string.equals("Current Profile"))
          {
            mac.display_string = globals.profiles.current().name;
            return;
          }
        }
      }
    }
  }
  
  void onFocus(Message message)
  {
    switch (message.target)
    {
      case "selectedprofile":
        globals.profiles.set_current(globals.profiles.get(message.value));
        break;
      case "selectedsprite":
        globals.profiles.current().sprite = message.value;
        break;
    }
    
    load();
  }
  
  Message exit()
  {
    globals.profiles.save();
    
    return new Message();
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
