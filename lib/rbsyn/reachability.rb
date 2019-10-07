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
    raise RuntimeError, "expect path to be an array" unless path.is_a? Array
    raise RuntimeError, "last element in a path must always be a type" unless path.last.is_a? RDL::Type::Type
    @path = path
    @tenv = tenv
  end

  def last
    @path.last
  end
end

class Reachability
  def initialize(initial_tenv)
    @initial_tenv = initial_tenv
  end

  def paths_to_type(target, depth)
    curr_depth = 0
    types = types_from_tenv(@initial_tenv)
    queue = types.map { |t| CallChain.new([t], types) }

    until curr_depth == depth do
      new_queue = []
      queue.each { |path|
        trecv = path.last
        mthds = methods_of(trecv)
        mthds.each { |mthd, info|
          tmeth = info[:type]
          targs = compute_targs(trecv, tmeth)
          next unless constructable? targs, path.tenv
          tout = compute_tout(trecv, tmeth, targs)
          # convert :self types to actual object
          tout = trecv if tout.is_a?(RDL::Type::VarType) && tout.name == :self
          new_tenv = make_new_tenv(tout, path.tenv)
          new_queue << CallChain.new(path.path + [mthd, tout], new_tenv)
        }
      }
      queue = new_queue
      curr_depth += 1
    end
    chains_with_type(queue, target)
  end

  private
  def chains_with_type(chains, type)
    chains.filter { |chain|
      type <= chain.last
    }
  end

  def make_new_tenv(tout, tenv)
    new_tenv = tenv.clone
    new_tenv.add(tout)
  end

  def constructable?(targs, tenv)
    targs.all? { |targ|
      case targ
      when RDL::Type::FiniteHashType
        targ.elts.values.any? { |v| constructable? [v], tenv }
      when RDL::Type::OptionalType
        constructable? [targ.type], tenv
      when RDL::Type::NominalType
        tenv.any? { |t| t <= targ }
      when RDL::Type::SingletonType
        if targ.val.is_a? Symbol
          true
        else
          raise RuntimeError, "unhandled type #{targ.inspect}"
        end
      else
        raise RuntimeError, "unhandled type #{targ.inspect}"
      end
    }
  end

  def compute_targs(trec, tmeth)
    # TODO: we use only the first definition, ignoring overloaded method definitions
    type = tmeth[0]
    targs = type.args
    targs.map { |targ|
      case targ
      when RDL::Type::ComputedType
        bind = Class.new.class_eval { binding }
        bind.local_variable_set(:trec, trec)
        targ.compute(bind)
      else
        raise RuntimeError, "unhandled type #{targ}"
      end
    }
  end

  def compute_tout(trec, tmeth, targs)
    # TODO: we use only the first definition, ignoring overloaded method definitions
    type = tmeth[0]
    tret = type.ret
    case tret
    when RDL::Type::ComputedType
      bind = Class.new.class_eval { binding }
      bind.local_variable_set(:trec, trec)
      bind.local_variable_set(:targs, targs)
      tret.compute(bind)
    else
      tret
    end
  end

  def parents_of(trecv)
    case trecv
    when RDL::Type::SingletonType
      cls = trecv.val
      if cls.is_a? Class
        cls.ancestors.map { |klass| RDL::Util.add_singleton_marker(klass.to_s) }
      else
        raise RuntimeError, "expected only true/false" unless (cls == true || cls == false)
        cls.class.ancestors.map { |klass| klass.to_s }
      end
    when RDL::Type::PreciseStringType
      String.ancestors.map { |klass| klass.to_s }
    when RDL::Type::UnionType
      trecv.types.map { |type| parents_of type }.flatten
    when RDL::Type::GenericType
      parents_of trecv.base
    when RDL::Type::NominalType
      RDL::Util.to_class(trecv.name).ancestors.map { |klass| klass.to_s }
    else
      raise RuntimeError, "unhandled type #{trecv.inspect}"
    end
  end

  def methods_of(trecv)
    Hash[*parents_of(trecv).map { |klass|
        RDL::Globals.info.info[klass]
      }.reject(&:nil?).collect { |h| h.to_a }.flatten]
  end

  def types_from_tenv(tenv)
    s = Set.new
    tenv.bindings.each { |b|
      s.add(tenv[b].type)
    }
    return s
  end
end
