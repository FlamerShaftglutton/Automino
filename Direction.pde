
enum Direction
{
  NORTH,
  EAST,
  SOUTH,
  WEST,
  NONE
}

String print_direction(Direction d)
{
  String retval = "";
  
  switch (d)
  {
    case NORTH: retval = "NORTH"; break;
    case EAST:  retval = "EAST" ; break;
    case SOUTH: retval = "SOUTH"; break;
    case WEST:  retval = "WEST" ; break;
    case NONE:  retval = "NONE" ; break;
  }
  
  return retval;
}

IntVec offset_from_direction(Direction d)
{
  IntVec retval = new IntVec(0,0);
  
  switch (d)
  {
    case NORTH: retval.y = -1; break;
    case EAST:  retval.x =  1; break;
    case SOUTH: retval.y =  1; break;
    case WEST:  retval.x = -1; break;
    case NONE: break;
  }
  
  return retval;
}

float rotation_from_direction(Direction d)
{
  float rot = 0f;
  
  switch (d)
  {
    case NORTH: rot = HALF_PI; break;
    case EAST:  rot = 0f; break;
    case SOUTH: rot = PI + HALF_PI; break;
    case WEST:  rot = PI; break;
    case NONE:  rot = PI * 0.25f; break; //this should look awful
  }
  
  return rot;
}

Direction direction_from_quarter_turns(int quarter_turns)
{
  switch (quarter_turns % 4)
  {
    case 0:   return Direction.EAST;
    case 1:   return Direction.NORTH;
    case 2:   return Direction.WEST;
    case 3:   return Direction.SOUTH;
    default : return Direction.NONE;
  }
}

int quarter_turns_from_direction(Direction d)
{
  switch (d)
  {
    case NORTH: return 1;
    case EAST:  return 0;
    case SOUTH: return 3;
    case WEST:  return 2;
    default:    return 0;
  }
}

Direction parseDirection(String dir)
{
    switch (dir)
  {
    case "NORTH": return Direction.NORTH;
    case "EAST":  return Direction.EAST;
    case "SOUTH": return Direction.SOUTH;
    case "WEST":  return Direction.WEST;
    default: return Direction.NONE;
  }
}

IntVec offset_from_quarter_turns(int quarter_turns)
{
  quarter_turns &= 3;
  IntVec retval = new IntVec(0,0);
  
  switch (quarter_turns)
  {
    case 1: retval.y = -1; break;
    case 0:  retval.x =  1; break;
    case 3: retval.y =  1; break;
    case 2:  retval.x = -1; break;
  }
  
  return retval;
}
