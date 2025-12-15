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
    elsif type.is_a?(RDL::Type::SingletonType)
      val = type.val
      return val.singleton_methods.include?(mthd)
    elsif type.is_a?(RDL::Type::UnionType)
      type.types.any? {|t| RDLRespondTo(t, mthd)}
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
          
          tmeths = info[:type]
          is_moi = @moi.include?(mthd)
          targs_1 = compute_targs(trecv, tmeths,is_moi)
          
          tout = []
          # if (tmeths.size > 1) && is_moi
          #   binding.pry
          # end
          targs_1.zip(tmeths[0 .. targs_1.size]).each do |targs, tmeth|
            next if targs.any? { |t| t.is_a? RDL::Type::BotType }

            begin
              x = compute_tout(trecv, [tmeth], targs)
              tout << x unless tout.include?(x)
            rescue NoMethodError => e
              binding.pry
              puts "NO METHOD ERROR IN #{mthd}"
              next
            end
          end
          next if tout == []
          # convert :self types to actual object
          # if mthd.to_s == "make_splitter" or mthd.to_s == "<<"
          #   binding.pry
          # end
          tout.each do |t|
            t = trecv if t.is_a?(RDL::Type::VarType) && t.name == :self
            new_tenv = make_new_tenv(t, path.tenv)
            new_queue << CallChain.new(path.path + [mthd, t], new_tenv)
          end
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
