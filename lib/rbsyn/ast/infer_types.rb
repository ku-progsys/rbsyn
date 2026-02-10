require "set"
require_relative "check_error_pass"
require "pry"
require "pry-byebug"
require_relative "../type_helper"
require_relative "../complex_error"


class InferTypes

  attr_reader :type_errs, :type_successes, :moi, :new_types, :newerror, :newsuccess, :exclude

  def initialize(moi, exclude)
    @moi = moi
    @exclude = exclude
    @type_errs = {}
    @type_successes = {}
    moi.each do |i|
      @type_errs[i] = []
      @type_successes[i] = []
    end
    @typestack = []
    @tracelist = {}
    @checker = CheckErrorPass.new(@type_errs, @type_successes)
    @updated = false
    @set_exception = false
    @new_types = []
    @new_success = false
    @new_error = false
    @counter = 0
  end

  def compare_hashes(left, right)

    return left.reject { |k, _| [:except].include?(k) } == right.reject { |k, _| [:except].include?(k) }

  end

  def reset_instrumentation(tracelist)
    @updated = false
    @typestack = []
    @set_exception = false
    @new_types = []
    @counter = 0
    @tracelist = tracelist
  end

  def w_instrument(recvr, meth, *args)

    argtypes = @tracelist[@counter] # so that we can elevate types when they are arguments. There is nuance to this that I am missing rn. 
    @counter += 1
    truefalse = RDL::Type::UnionType.new(RDL::Type::SingletonType.new(false), RDL::Type::SingletonType.new(true))
    # trace form: {method, reciever, args, result, exception}
    recarg = argtypes.shift
    trace = {
      :method => meth,
      :recvr => 
        if !recarg.nil?
          recarg
        elsif recvr.is_a?(TrueClass) || recvr.is_a?(FalseClass)
          truefalse
        else
          RDL::Type::NominalType.new(recvr.class.to_s)
        end,
      :args => args.map {|i| x = argtypes.shift
                          if !x.nil?
                            x
                          elsif i.is_a?(TrueClass) || i.is_a?(FalseClass) 
                            truefalse 
                          else 
                            RDL::Type::NominalType.new(i.class.to_s) 
                          end},
      :result => nil, 
      :except => nil} # why is this nominal type this might need to change because of generics 


    begin
      # if type_to_s(trace).to_s.include?("Hamster::Hash_1 :default")
      #   binding.pry
      # end
      result = recvr.send(meth, *args)

      result.inspect # this forces an inspection on an object 
      # for some reason with hamster lazy list take and drop the error isn't caught without it. 
      # this might ruin lazyness for now I don't have an alternative route. 
            
    rescue TypeError => e
      if !@set_exception 
        trace[:except] = e
        update_errlist(trace)
        @set_exception = true
      end
      raise e

    rescue NoMethodError => e 
      
      # don't even bother using this program because it DEFINITELY has a type error, not just a potential error. 
      if !@set_exception 
        trace[:except] = e
        if e.receiver.to_s == recvr.class.to_s && e.name == meth
          # ensure that error arose from outer class, not inner call. 
          trace[:args] = :ALL
        else

          e = ComplexError.new(e, outer_receiver: recvr.class, outer_method: meth)
          trace[:except] = e
        end
        update_errlist(trace)
        @set_exception = true
      end
      raise e

    rescue NameError => e 
      if !@set_exception 
        trace[:except] = e
        if e.to_s.downcase.include?("undefined method") &&  e.receiver.to_s == recvr.class.to_s && e.name == meth
          trace[:args] = :ALL
        else
          e = ComplexError.new(e, outer_receiver: recvr.class, outer_method: meth)
          trace[:except] = e
        end
        update_errlist(trace)
        @set_exception = true
      end
      raise e

    rescue ArgumentError => e 
       if !@set_exception  
        trace[:except] = e
        update_errlist(trace)
        @set_exception = true
      end
      raise e

    rescue StandardError => e
      if !@set_exception 
        trace[:except] = e
        update_errlist(trace)
        @set_exception = true
      end
      raise e
    end
    
    if result.is_a?(TrueClass) || result.is_a?(FalseClass) 
      trace[:result] = truefalse 
    else 
      trace[:result] = RDL::Type::NominalType.new(result.class.to_s)
    end
    
    # if type_to_s(trace).to_s == "Hamster::Hash_1 :alloc => Hamster::Trie => nil => :except"
    #   binding.pry
    # end
    update_success(trace)
    result

  end

  def match_exclusion?(trace)

    #check if we need to exclude any known types from the search
    if @exclude[trace[:recvr].to_s.to_sym].nil?
      @exclude[:"%any"].include?(trace[:method].to_s.to_sym)
    else
      @exclude[trace[:recvr].to_s.to_sym].include?(:"%all") || @exclude[trace[:recvr].to_s.to_sym].include?(trace[:method].to_s.to_sym)
    end
  end


  def update_errlist(trace)
    
    consolidate_type_errors(trace)
    @type_errs

  end


  def get_reset_newtypes()
    temp = @new_types.dup
    @new_success = false
    @new_error = false
    @new_types = []
    temp
  end


  def update_success(trace)

    if !match_exclusion?(trace)

      ParentsHelper.addTypeManually(trace[:recvr].to_s)
      ParentsHelper.addTypeManually(trace[:result].to_s)
      consolidate_type_successes(trace)

    end

    @type_successes

  end

    def consolidate_type_errors(trace)

    meth = trace[:method]
    begin
      
      @type_errs[meth].each_with_index do |sig, ind|
        if sig[:recvr] != trace[:recvr]
          next
        end
        if trace[:except].is_a?(NoMethodError) || trace[:except].is_a?(NameError)
          #if we've already seen this error we don't need to update anything, method missing is method missing. 
          #we know we've seen it because it will be the only one with this reciever for this method
          return @type_errs
        end
        
        if sig[:args].size == trace[:args].size
          begin
            sigzip = sig[:args].zip(trace[:args])
          rescue Exception => e

            binding.pry
          end
          if sigzip.all? { |old, current| current <= old || old <= current}
            @newerror = true
            # if all arguments in the old observation are comprable to the current observation
            # reduce each argument to the smallest smaller arguments will be expanding the incorrectness as incorrectness travels upwards. 
            @type_errs[meth][ind][:args] = sigzip.map {|old, current| old <= current ? old : current}
            
            return @type_errs
          end
        end
      end

      @newerror = true
      @type_errs[meth].append(trace)
      return @type_errs

    rescue Exception => e
      binding.pry
      raise e
    end
  end



  def consolidate_type_successes(trace)

    meth = trace[:method]
    begin

      @type_successes[meth].each_with_index do |sig, ind|
        if sig[:recvr] != trace[:recvr]
          next
        end 
        # puts "here"
        # puts sig

        if sig[:args].size == trace[:args].size && ( sig[:result] <= trace[:result] || trace[:result] <= sig[:result] )
          temp = sig
          # if args are correct size and returns are comprable
          sigzip = sig[:args].zip(trace[:args])
          if !(sigzip.any? {|old, current| old != current})
            return @type_successes
          end

          if !(sigzip.any? {|old, current| !(old <= current) && !(current <= old)}) # if all of the arguments are comparable

            # we can consider the previous observation to be a call to an instance of this function 
            # or a more specific instance of this function (perhaps we should not fold in, but RUBY only allows one function of the same arity per reciever" 
            @type_successes[meth][ind][:args] = sigzip.map {|old, current| current <= old ? old : current}
            @type_successes[meth][ind][:result] = sig[:result] <= trace[:result] ? trace[:result] : sig[:result]
            # preserve the most generic version of the type
            update = @type_successes[meth][ind]

            @newsuccess = true
            @new_types << update

            RDL::Globals.info.info[update[:recvr].to_s][meth][:type].each_with_index do |tipe, index|
              # now destroy any entries that are more precise than this one. 
              if tipe.args.zip(update[:args]).all? {|left, right| left <= right} && tipe.ret <= update[:result] 
                # any that is more specific we can destroy
                RDL::Globals.info.info[update[:recvr].to_s][meth][:type].pop(index)
                RDL::Globals.info.info[update[:recvr].to_s][meth][:effect].pop(index)
              end  
            end

            # build the new, more general type into RDL
            RDL.type update[:recvr].to_s, meth, "(#{update[:args].map(&:to_s).join(', ')}) -> #{update[:result].to_s}"
            return @type_successes
          end
        end
      end

      # we have not found any type that is a comprable version of this one, we can add it in as is
      @type_successes[meth].append(trace)
      update = @type_successes[meth][-1]
      @newsuccess = true
      @new_types << update
      RDL.type update[:recvr].to_s, meth, "(#{update[:args].map(&:to_s).join(', ')}) -> #{update[:result].to_s}"
      return @type_successes

    rescue Exception => e
      binding.pry
      raise e
    end
  end


  def check_errors(ast)
    @checker.update_reset(@type_errs, @type_successes) # resetting the checker
    @checker.process(ast) # the # of errors 
    # binding.pry if x.is_a?(RDL::Type::DynamicType)
    # @checker.update_reset(@type_errs, @type_successes) # resetting the checker
    # x = @checker.process(ast) # the # of errors 
    [@checker.errors, @checker.dynamic_components]  

  end


  def type_to_s(type)
  
    t = type[:recvr].to_s 
    
    if !type[:method].nil?
      t = "#{t} :#{type[:method]}"
    end 
    
    if type[:args] == :ALL
      t = "#{t} => #{type[:args].to_s}"
    
    else 
      type[:args].each {|i|
      t = "#{t} => #{i.to_s}"
      }
    end

    if !type[:result].nil?
      t = "#{t} => #{type[:result].to_s}"
    end


    if !type[:except].nil?
      t = " #{t} => :except"
    end

    t
  end

end