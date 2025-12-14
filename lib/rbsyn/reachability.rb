=begin
path = (type -> method -> type -> ..., tenv)
queue = initial_set of path
while depth < max_depth {
  type = consume item from queue
  find all possible methods in the type
  compute targs of the methods
  check if the targs can be constructed from the tenv
  if yes {
    compute tout for that method
    push the path to the queue
  }
}
take paths in the queue that end with the type that we need
=end

class CallChain
  attr_reader :path, :tenv

  def initialize(path, tenv)
    raise RbSynError, "expect path to be an array" unless path.is_a? Array
    raise RbSynError, "last element in a path must always be a type" unless path.last.is_a? RDL::Type::Type
    @path = path
    @tenv = tenv
  end

  def last
    @path.last
  end

  def to_s
    @path.join(' -> ')
  end
end

class Reachability
  include TypeOperations

  def initialize(initial_tenv, moi)
    @initial_tenv = initial_tenv
    @moi = moi
  end

  def RDLRespondTo(type, mthd)

    if type.is_a?(RDL::Type::NominalType)
      klass = type.klass
      return klass.instance_methods.include?(mthd) || klass.singleton_methods.include?(mthd)
    elsif type.is_a?(RDL::Type::UnionType)
      # BR cant remember the structure right now, I will figure out shortly. 
      binding.pry
    elsif type.is_a?(RDL::Type::DynamicType)
      true
    else
     false
    end
  end

  def paths_to_type(target, depth, variance=COVARIANT)

    
    #puts target.to_s
    curr_depth = 0
    types = types_from_tenv(@initial_tenv)
    queue = types.map { |t| CallChain.new([t], types) }
  
    until curr_depth == depth do

      new_queue = []
      queue.each { |path|
        trecv = path.last
        mthds = methods_of(trecv)
        mthds.delete(:__getobj__)
        #BR added in a respond_to here so that we can avoid methods that don't actually respond. 
        #mthds = mthds.filter {|i, _| RDLRespondTo(trecv, i)} # a bit hackey though 
        mthds.each { |mthd, info|
          if @moi.include?(mthd) && !RDLRespondTo(trecv, mthd)
            next
          end
          
          tmeth = info[:type] 
          targs = compute_targs(trecv, tmeth, @moi)

          next if targs.any? { |t| t.is_a? RDL::Type::BotType }
          begin
            tout = compute_tout(trecv, tmeth, targs)
          rescue NoMethodError => e
            puts "NO METHOD ERROR IN #{mthd}"

            next
          end
          # convert :self types to actual object
          # if mthd.to_s == "make_splitter" or mthd.to_s == "<<"
          #   binding.pry
          # end
          tout = trecv if tout.is_a?(RDL::Type::VarType) && tout.name == :self
          new_tenv = make_new_tenv(tout, path.tenv)
          new_queue << CallChain.new(path.path + [mthd, tout], new_tenv)
        }
        
      }
      queue = new_queue
      curr_depth += 1
    end
    chains_with_type(queue, target, variance)
  end

  private
  def chains_with_type(chains, type, variance)
    chains.filter { |chain|
      case variance
      when COVARIANT

        type <= chain.last
      when CONTRAVARIANT

        if chain.last.is_a? RDL::Type::UnionType
          chain.last.types.any? { |t| t <= type }
        else
          chain.last <= type
        end
      else
        raise RbSynError, "unexpected variance"
      end
    }
  end

  def make_new_tenv(tout, tenv)
    new_tenv = tenv.clone
    new_tenv.add(tout)
  end
end
