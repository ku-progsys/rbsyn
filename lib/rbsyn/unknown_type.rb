# lib/rdl/types/impossible_type.rb
class AnythingButType 
  attr_reader :params, :all

  def initialize(params)
    # params is an array of RDL::Type objects
    @params = params.freeze
    @all = false
    super()
  end

  def setall()
    @all = true
  end

  def ==(other)
    other.is_a?(ImpossibleType) &&
      other.params.to_set == @params.to_set
  end

  def eql?(other)
    self == other
  end

  def hash
    params.hash ^ 0XBADBAD
  end

  def to_s
    "AnythingBut<#{params.map(&:to_s).join(', ')}>"
  end


  def <=(other)
    
    if !other.is_a?(AnythingButType)
      false
    elsif @all 
      false
    else
      @params.all? {|param| other.params.any? {|oth| param <= oth}}
    end
  end

  def meet(other)
    raise ArgumentError, "other must be ImpossibleType" unless other.is_a?(self.class)

    
    if @all
      return other
    elsif other.all
      return self
    end
    candidates = []
    @params.each {|param| 
      other.params.each {|param2|
        if param <= param2
          candidates << param 
          break
        elsif param2 << param 
          candidates << param2 
          break
        else 
          next
        end
      }
    }

    return AnythingButType.new(candidates)

  end


  def join(other)
    raise ArgumentError, "other must be ImpossibleType" unless other.is_a?(self.class)

    if @all
      return self
    elsif other.all
      return other
    end

    candidates = []
    @params.each {|param| 
      other.params.each {|param2|
        if param <= param2
          candidates << param2
          break
        elsif param2 << param 
          candidates << param
          break
        else 
          next
        end
      }
    }

    return AnythingButType.new(candidates)
  end

end
