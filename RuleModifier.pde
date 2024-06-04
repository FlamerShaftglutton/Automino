
class Modifier
{
  String field;
  ModifierOperation op;
  float  float_value;
  int    int_value;
  String string_value;
  
  Modifier(String field, ModifierOperation op, String value) { this.field = field; this.op = op; float_value = parse_float(value, 0f); int_value = (int)float_value; string_value = value; }
  Modifier() { this("", ModifierOperation.NONE, ""); }
  Modifier(String to_parse)
  {
    this();
    String[] chunks = to_parse.split(" ");
    
    if (chunks.length >= 4 && (chunks[2].toLowerCase().equals("to") || chunks[2].toLowerCase().equals("from")))
    {
      switch (chunks[0].toLowerCase())
      {
        case "add": case "sum": case "+": op = ModifierOperation.ADD; break;
        case "subtract":  case "sub": case "-": op = ModifierOperation.SUBTRACT; break;
        case "set": op = ModifierOperation.SET; break;
        case "multiply": case "mult": case "*": op = ModifierOperation.MULTIPLY; break;
        case "divide": case "div": case "/": op = ModifierOperation.DIVIDE; break;
        default: op = ModifierOperation.NONE; println("Unknown rule modifier operator '" + chunks[0] + "'."); break;
      }
      
      string_value = chunks[1];
      float_value = parse_float(chunks[1],0f);
      int_value = (int)float_value;
      
      field = chunks[3];
    }
  }
  
  float get_float(float current_value)
  {
    switch (op)
    {
      case ADD:      return current_value + float_value;
      case SUBTRACT: return current_value - float_value;
      case SET:      return                 float_value;
      case MULTIPLY: return current_value * float_value;
      case DIVIDE:   return current_value / float_value;
      default:       return current_value;
    }
  }
  
  int get_int(int current_value)
  {
    switch (op)
    {
      case ADD:      return current_value + int_value;
      case SUBTRACT: return current_value - int_value;
      case SET:      return                 int_value;
      case MULTIPLY: return current_value * int_value;
      case DIVIDE:   return current_value / int_value;
      default:       return current_value;
    }
  }
  
  String get_string(String current_value)
  {
    if (current_value.length() == 0 || op == ModifierOperation.SET)
      return string_value;
    
    if (string_value.length() == 0)
      return current_value;
    
    return current_value + ", " + string_value;
  }
  
  float  get_float()  { return float_value;  }
  int    get_int()    { return int_value;    }
  String get_string() { return string_value; }
}

class Rule
{
  String name;
  String description;
  
  RuleType type;
  StringList dependencies;
  StringList tags;
  ArrayList<Modifier> mods;
  
  Rule(String name, String description, RuleType type, StringList dependencies, StringList tags)
  {
    this.description = description; 
    this.name = name; 
    this.type = type; 
    this.dependencies = new StringList(dependencies);
    this.tags = new StringList(tags);
    mods = new ArrayList<Modifier>();
  }

  Rule() { this("", "", RuleType.CURSE, new StringList(), new StringList()); }
  
  boolean is_locked(StringList rulenames) { for (String dep : dependencies) { if (!rulenames.hasValue(dep)) return true; } return false; }
}


//maintains a list of rules. Also has a separate mapping of all the rules' modifiers keyed by field they modify.
class RuleManager
{
  ArrayList<Rule> rules = new ArrayList<Rule>();
  HashMap<String, ArrayList<Modifier>> mods = new HashMap<String, ArrayList<Modifier>>();
  
  void put(Rule r)
  {
    rules.add(r);
    
    for (Modifier m : r.mods)
    {
      if (!mods.containsKey(m.field))
        mods.put(m.field, new ArrayList<Modifier>());
      
      mods.get(m.field).add(m);
    }
  }
  
  float get_float(String field, float current_value)
  {
    float retval = current_value;
    
    ArrayList<Modifier> ms = mods.get(field);
    
    if (ms != null)
    {
      for (int i = 0; i < ms.size(); ++i)
        retval = ms.get(i).get_float(retval);
    }
    
    return retval;
  }
  
  int get_int(String field, int current_value)
  {
    int retval = current_value;
    
    ArrayList<Modifier> ms = mods.get(field);
    
    if (ms != null)
    {
      for (int i = 0; i < ms.size(); ++i)
        retval = ms.get(i).get_int(retval);
    }
    
    return retval;
  }
  
  StringList get_strings(String field)
  {
    StringList retval = new StringList();
    
    ArrayList<Modifier> ms = mods.get(field);
    
    if (ms != null)
    {
      for (int i = 0; i < ms.size(); ++i)
        retval.append(ms.get(i).get_string());
    }
    
    return retval;
  }
  
  float  get_float (String field) { return get_float (field,0f); }
  int    get_int   (String field) { return get_int   (field,0 ); }
  String get_string(String field) { return get_strings(field).join(", "); }
  
  StringList get_rule_names() { StringList retval = new StringList(); for (int i = 0; i < rules.size(); ++i) retval.append(rules.get(i).name); return retval; }
  ArrayList<Rule> get_rules() { return new ArrayList<Rule>(rules); }
  
  StringList get_available_curses()
  {
    StringList existing_rules = get_rule_names();
    
    StringList retval = globals.rules.get_all_curse_names();
    
    for (String er : existing_rules)
      retval.removeValue(er);
    
    StringList to_remove = new StringList();
    
    for (String rulename : retval)
    {
      if (globals.rules.get_curse(rulename).is_locked(existing_rules))
        to_remove.append(rulename);
    }
    
    for (String tr : to_remove)
    {
      retval.removeValue(tr);
    }
    
    return retval;
  }
  
  StringList get_available_boons()
  {
    StringList existing_rules = get_rule_names();
    
    StringList retval = globals.rules.get_all_boon_names();
    
    for (String er : existing_rules)
      retval.removeValue(er);
    
    StringList to_remove = new StringList();
    
    for (String rulename : retval)
    {
      if (globals.rules.get_boon(rulename).is_locked(existing_rules))
        to_remove.append(rulename);
    }
    
    for (String tr : to_remove)
    {
      retval.removeValue(tr);
    }
    
    return retval;
  }
}

class RuleFactory
{
  HashMap<String, Rule> curses = new HashMap<String, Rule>();
  HashMap<String, Rule> boons = new HashMap<String, Rule>();
  
  void load(String filepath)
  {
    //TODO: this
  }
  
  Rule get_curse(String name) { return curses.get(name); }
  Rule get_boon(String name)  { return  boons.get(name); }
  
  StringList get_all_curse_names() { return new StringList(curses.keySet()); }
  StringList get_all_boon_names()  { return new StringList( boons.keySet()); }
}


enum ModifierOperation
{
  ADD,
  SUBTRACT,
  SET,
  MULTIPLY,
  DIVIDE,
  NONE
}

enum RuleType
{
  CURSE,
  BOON
}
