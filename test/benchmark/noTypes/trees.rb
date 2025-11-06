


class State
  
  require 'set'
  include Comparable
  attr_reader :parents, :id, :children, :within, :type 


  def initialize(id, type)
    @type = type
    @id =  id
    @parents = Set.new()
    @children = Set.new()
    @within = nil
  end
  

  def addParent(parent)
    @parents.add(parent)
  end


  def addChild( child)
    @children.add(child)
  end


  def addNode( node) 
    @within = node
  end


  def hash()
    @id
  end


  def <=>(other)
    return nil unless other.is_a?(State)
    @id <=> other.id
  end


  def eql?( other)
    @id == other.id
  end
  
  def to_s()
    return "State: #{@type}, ID: #{@id}, #Parents: #{@parents.size}, #Children: #{@children.size}"
  end

  def inspect
    return "type: #{@type} id: #{@id}"
  end

end 




class MP < State
  def initialize(id)
    super(id, "MP")
  end
end

class ML < State
  def initialize(id)
    super(id, "ML")
  end
end

class MR < State
  def initialize(id)
    super(id, "MR")
  end
end

class IL < State
  def initialize(id)
    super(id, "IL")
  end
end

class IR < State
  def initialize(id)
    super(id, "IR")
  end
end

class D < State
  def initialize(id)
    super(id, "D")
  end
end

class B < State
  def initialize(id)
    super(id, "B")
  end
end

class S < State
  def initialize(id)
    super(id, "S")
  end
end

class E < State
  def initialize(id)
    super(id, "E")
  end
end

class NONE < State
  def initialize
    super(-1, "NONE")
  end
end



class StructureError < StandardError
  def initialize(message = "A structural graph error has occurred")
    super(message)
  end
end

class LexError < StandardError
  def initialize(message = "A structural graph error has occurred")
    super(message)
  end
end


class Node
  require 'set'
  include Comparable

  attr_reader :id, :type, :num_states, :states, :parents, :children

  def initialize(id, type, num_states)
    @id = id
    @type = type
    @num_states = num_states
    @states = Set.new
    @parents = Set.new
    @children = Set.new
  end

  def addState(state)
    raise StructureError, "Too Many States in Node: #{@id}, expected: #{@num_states}" if @states.size >= @num_states
    @states.add(state)
    nil
  end

  def addParent(parent)
    @parents.add(parent)
    nil
  end

  def addChild(child)
    @children.add(child)
    nil
  end

  def <=>(other)
    return nil unless other.is_a?(Node)
    @id <=> other.id
  end

  def eql?(other)
    other.is_a?(Node) && @id == other.id
  end
  alias_method :==, :eql?

  def hash
    @id.hash
  end

  def to_s
    "Node: #{@type}, ID: #{@id}, Parents: #{parents.map(&:inspect)}, Children: #{children.map(&:inspect)}, Contains: #{states.map(&:inspect)}"
  end

  def inspect
    "#{@type}(#{@id})"
  end
end



class ROOT < Node
  def initialize(id)
    super(id, "ROOT", 3)
  end
end

class MATL < Node
  def initialize(id)
    super(id, "MATL", 3)
  end
end

class MATR < Node
  def initialize(id)
    super(id, "MATR", 3)
  end
end

class BIF < Node
  def initialize(id)
    super(id, "BIF", 1)
  end
end

class BEGL < Node
  def initialize(id)
    super(id, "BEGL", 1)
  end
end

class END_NODE < Node
  def initialize(id)
    super(id, "END", 1)
  end
end

class BEGLR < Node
  def initialize(id)
    super(id, "BEGR", 2)
  end
end

class MATP < Node
  def initialize(id)
    super(id, "MATP", 6)
  end
end




def lexer(file)
  nodelist = []
  state_dict = {}

  File.open(file, "r") do |filestream|
    # skip until a line that equals "CM"
    while (line = filestream.gets)
      break if line.strip == "CM"
    end

    # read node block until a line that equals "//"
    while (line = filestream.gets)
      line = line.strip
      break if line == "//"

      tokens = line.split.reject(&:empty?)
      type = tokens[1]
      id = tokens[2].to_i

      node =
        case type
        when "ROOT"
          ROOT.new(id)
        when "MATL"
          MATL.new(id)
        when "MATR"
          MATR.new(id)
        when "BIF"
          BIF.new(id)
        when "BEGL"
          BEGL.new(id)
        when "END"
          # use EndNode (or whatever safe constant you defined for END)
          END_NODE.new(id)
        when "BEGR"
          BEGLR.new(id)
        when "MATP"
          MATP.new(id)
        else
          raise LexError, "Un-defined node type: #{type} for node: ##{id}"
        end

      nodelist << lex_node(node, state_dict, filestream)
    end

    # link nodes: states may refer to parents/children in other nodes
    nodelist.each do |node|
      node.states.each do |state|
        state.children.each do |child|
          node.addChild(child.within) unless child.within == node
        end
        state.parents.each do |parent|
          node.addParent(parent.within) unless parent.within == node
        end
      end
    end
  end

  nodelist.first
end


def lex_node(node, state_dict, filestream)
  # adding states
  node.num_states.times do
    line = filestream.gets
    tokens = line.strip.split.reject(&:empty?)
    type = tokens[0]
    id = tokens[1].to_i

    parents =
      if tokens[2].to_i != -1
        start_idx = tokens[2].to_i - tokens[3].to_i + 1
        end_idx = tokens[2].to_i
        (start_idx..end_idx).to_a
      else
        []
      end

    state =
      case type
      when "MP" then MP.new(id)
      when "ML" then ML.new(id)
      when "MR" then MR.new(id)
      when "IL" then IL.new(id)
      when "IR" then IR.new(id)
      when "D"  then D.new(id)
      when "B"  then B.new(id)
      when "S"  then S.new(id)
      when "E"  then E.new(id)
      else
        raise LexError, "Un-defined state type: #{type} for node: ##{id}"
      end

    state.addNode(node)
    state_dict[id] = state

    parents.each do |item|
      unless state_dict.key?(item)
        raise KeyError, item
      end

      state.addParent(state_dict[item])
      state_dict[item].addChild(state)
    end

    node.addState(state)
  end

  node
end


# StateTraverse: applies visitor_fn to each state in sorted order while exposing an Enumerable
class StateTraverse
  include Enumerable

  # visitor_fn: a Proc taking a state and returning some value
  # state_list: array of states (assumed comparable for sorting)
  def initialize(visitor_fn, state_list)
    @visitor_fn = visitor_fn
    @state_list = state_list.sort
  end

  # each yields the visitor result for every state in the sorted list
  def each
    return enum_for(:each) unless block_given?
    @state_list.each do |s|
      yield send(@visitor_fn, s)
    end
  end
end

# NodeTraverse: a simple breadth-first traversal that applies visitor_fn to each node
class NodeTraverse
  include Enumerable

  # visitor_fn: Proc that accepts a node and returns something (like accumulating into a structure)
  # root: the root node to start traversal from; assumed to respond to `children`
  def initialize(visitor_fn, root)
    @visitor_fn = visitor_fn
    @root = root
  end

  # each yields visitor_fn.call(n) for each visited node in BFS order
  def each
    return enum_for(:each) unless block_given?
    return if @root.nil?

    queue = [@root]
    
    until queue.empty?
      node = queue.shift
      next if node.nil?
      node.children.each do 
        |i| 
        queue << i
      end
      
      yield send(@visitor_fn, node)

    end
  end
end



