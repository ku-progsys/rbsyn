require "set"
require_relative "check_error_pass"
require_relative "check_error_pass_v2" # AI generated (2026-10-20): replacement checker, CHECKER=old uses the original
require "pry"
require "pry-byebug"
require_relative "../type_helper"
require_relative "../complex_error"

# AI generated (2026-10-20): a hash argument in a failure record where only one key is blamed: that key must be
# present with a value of `type`; any other keys, with any values, are allowed (printed as "{ key: type, ANY }").
# See InferTypes#apply_wildcards, CheckErrorPass#matches_err and CheckErrorPassV2#position_match?.
class AnyKeysHash # AI generated
  attr_reader :key, :type

  def initialize(key, type)
    @key = key
    @type = type
  end

  def ==(other)
    # type may be :ANY (wrong-key record); RDL types raise NoMethodError when compared to a symbol with ==
    other.is_a?(AnyKeysHash) && other.key == @key &&
      (other.type.equal?(@type) || (!@type.is_a?(Symbol) && !other.type.is_a?(Symbol) && other.type == @type))
  end

  def to_s
    "{ #{@key}: #{@type}, ANY }"
  end
end


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
    # @checker = CheckErrorPass.new(@type_errs, @type_successes) # AI altered (2026-10-20): replaced, see check_error_pass_v2.rb
    @checker = (ENV["CHECKER"] == "old" ? CheckErrorPass : CheckErrorPassV2).new(@type_errs, @type_successes) # AI generated
    @updated = false
    @set_exception = false
    @new_types = []
    # @new_success = false  # AI altered: name did not match attr_reader :newsuccess
    # @new_error = false    # AI altered: name did not match attr_reader :newerror
    @newsuccess = false # AI generated
    @newerror = false   # AI generated
    @counter = 0
  end

  # Information-entropy ordering of inference candidates was removed; it is available in commits up to dc740d5.

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

  def hashargtypes(hash, lnum_child)
    # AI version, skip hash arg types.  
    truefalse = RDL::Type::OptionalType.new(RDL::Type::UnionType.new(RDL::Type::SingletonType.new(false), RDL::Type::SingletonType.new(true)))
    local_hash = {}
    locals_list = (@tracelist[@counter - 1 + lnum_child] || []).dup
    hash.each do |key, val|
      x = locals_list.shift
      next if val.nil?   # exclude nil-valued keys
      if !x.nil?
        local_hash[key] = RDL::Type::OptionalType.new(x)
      elsif val.is_a?(TrueClass) || val.is_a?(FalseClass)
        local_hash[key] = truefalse
      else
        local_hash[key] = RDL::Type::OptionalType.new(RDL::Type::NominalType.new(val.class.to_s))
      end
    end
    local_hash
end

  # def hashargtypes(hash, lnum_child)
  #   #AI version
  #   truefalse = RDL::Type::OptionalType.new(RDL::Type::UnionType.new(RDL::Type::SingletonType.new(false), RDL::Type::SingletonType.new(true)))
  #   local_hash = {}
  #   locals_list = (@tracelist[@counter - 1 + lnum_child] || []).dup
  #   hash.each do |key, val|
  #     x = locals_list.shift
  #     if !x.nil?
  #       local_hash[key] = RDL::Type::OptionalType.new(x)
  #     elsif val.is_a?(TrueClass) || val.is_a?(FalseClass)
  #       local_hash[key] = truefalse
  #     else
  #       local_hash[key] = RDL::Type::OptionalType.new(RDL::Type::NominalType.new(val.class.to_s))
  #     end
  #   end
  #   local_hash
  # end

  # def hashargtypes(hash, lnum_child)
  #   truefalse = RDL::Type::OptionalType.new(RDL::Type::UnionType.new(RDL::Type::SingletonType.new(false), RDL::Type::SingletonType.new(true)))
  #   local_hash = {}
  #   locals_list = @tracelist[@counter + lnum_child]
  #   hash.each do |key, val|
      
  #     x = locals_list.shift
  #     if !x.nil?
        
  #       #BR might not want this to be an optional type 
  #       local_hash[key] = RDL::OptionalType.new(x)
  #     elsif i.is_a?(TrueClass) || i.is_a?(FalseClass) 
  #       local_hash[key] = truefalse 
  #     else 
  #       local_hash[key] = RDL::Type::OptionalType.new(RDL::Type::NominalType.new(i.class.to_s))
  #     end
  #     local_hash
  #   end
  # end

  def w_instrument(recvr, meth, *args)

    # since formal parameter may have a more generic value than the acutal argument we use argtypes to default to the more general formal param 
    argtypes = @tracelist[@counter] # so that we can elevate types when they are arguments. There is nuance to this that I am missing rn.
    __dd_declared = (argtypes || []).dup if ENV["DBG_DYN"] # INSTRUMENTATION DD (AI generated, remove): declared types before they are consumed
    @counter += 1
    truefalse = RDL::Type::UnionType.new(RDL::Type::SingletonType.new(false), RDL::Type::SingletonType.new(true))
    # trace form: {method, reciever, args, result, exception}
    recarg = argtypes.shift
    # >>> INSTRUMENTATION IM (AI generated, remove) >>>
    if ENV["DBG_DYN"] && !recarg.nil?
      __actual = recvr.is_a?(Class) ? RDL::Type::SingletonType.new(recvr) : RDL::Type::NominalType.new(recvr.class.to_s)
      unless (__actual <= recarg rescue true)
        $__im_n = ($__im_n || 0) + 1
        warn "[IM] counter=#{@counter - 1} meth=#{meth} tracelist_recv=#{recarg} actual_recv=#{__actual} args=#{args.map { |a| a.class }.inspect} tracelist=#{@tracelist.inspect[0, 200]}" if $__im_n <= 15
      end
    end
    # <<< INSTRUMENTATION IM <<<
    lnum_child = 0
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

      :args =>
        args.map {|i| x = argtypes.shift
          lnum_child += 0.1
          if !x.nil?
            x
          elsif i.is_a?(TrueClass) || i.is_a?(FalseClass) 
            truefalse 
          elsif i.is_a?(Hash)
            RDL::Type::FiniteHashType.new(hashargtypes(i, lnum_child), nil)
            # binding.pry
            # hashargtypes(i, lnum_child)< AI erase
            # RDL::Type::FiniteHashType.new(i, nil) < AI erase
          else 
            RDL::Type::NominalType.new(i.class.to_s)
          end},
      :result => nil, 
      :except => nil} # why is this nominal type this might need to change because of generics
    # >>> INSTRUMENTATION DD (AI generated, remove): log any %dyn argument type recorded for an observed call
    if ENV["DBG_DYN"] && trace[:args].is_a?(Array)
      __dd_is_dyn = lambda { |t| t.is_a?(RDL::Type::DynamicType) || (t.is_a?(RDL::Type::OptionalType) && t.type.is_a?(RDL::Type::DynamicType)) }
      if trace[:args].any? { |t| __dd_is_dyn.(t) } || __dd_is_dyn.(trace[:recvr])
        $__dd_n = ($__dd_n || 0) + 1
        warn "[DD] #{meth} recvr=#{trace[:recvr]} (actual #{recvr.class}) args=#{trace[:args].map(&:to_s).inspect} actual_arg_classes=#{args.map { |a| a.class }.inspect} declared(tracelist)=#{__dd_declared.map(&:to_s).inspect} counter=#{@counter - 1}" if $__dd_n <= 12
      end
    end
    # <<< INSTRUMENTATION DD <<<


    begin

      # if meth == :"self.exists?" || meth == :"exists?"
      #   puts "METH: #{meth}"
      #   puts "ARGS: #{args}"
      #   # binding.pry
      # end
      @raw_args = args # AI generated (2026-10-20): the actual argument values, for apply_wildcards
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
        # if e.receiver.to_s == recvr.class.to_s && e.name == meth # AI altered (2026-10-20): compared the receiver's value as text to its class name, never equal, so :ALL was never recorded
        if e.receiver.equal?(recvr) && e.name == meth # AI generated: the missing method was called on this receiver itself
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
        # if e.to_s.downcase.include?("undefined method") &&  e.receiver.to_s == recvr.class.to_s && e.name == meth # AI altered (2026-10-20): same comparison as the NoMethodError branch
        if e.to_s.downcase.include?("undefined method") && e.receiver.equal?(recvr) && e.name == meth # AI generated
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

    rescue SystemStackError => e # AI generated: record the call as an error like any other failure, then re-raise
      if !@set_exception # AI generated
        trace[:except] = e # AI generated
        update_errlist(trace) # AI generated
        @set_exception = true # AI generated
      end # AI generated
      raise e # AI generated
    end
    
    if result.is_a?(TrueClass) || result.is_a?(FalseClass) 
      trace[:result] = truefalse 
    else 
      #BR this shouldn't be to_s it gets rid of the type information esp with singleton types. Instead you should use the class itself.
      trace[:result] = RDL::Type::NominalType.new(result.class.to_s)
    end
    
    # if type_to_s(trace).to_s == "Hamster::Hash_1 :alloc => Hamster::Trie => nil => :except"
    #   binding.pry
    # end
    empty_hash_arg = trace[:args].is_a?(Array) &&
      # AI generated
      trace[:args].any? { |a| a.is_a?(RDL::Type::FiniteHashType) && a.elts.empty? }

    update_success(trace) unless empty_hash_arg
    # update_success(trace)
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

    apply_wildcards(trace) # AI generated (2026-10-20)
    consolidate_type_errors(trace)
    @type_errs

  end

  # AI generated (2026-10-20): wildcard failure records. When the error message names the class of exactly one
  # argument (its class name, or for a class value its own name; NilClass never counts), only that argument is
  # blamed and every other argument position becomes :ANY. ERR_ANY_POS=off switches this off.
  # Inside a hash argument the same is done per key: when exactly one key's value has a named class, the hash
  # becomes an AnyKeysHash (that key with its type, any other keys allowed). ERR_ANY_KEY=off switches this off
  # (key arguments can depend on state that effects change).
  # Wildcard records are marked trace[:wild] and are never merged with other records (merging keeps the narrower
  # type, which would drop the wildcard). Missing-method failures keep args = :ALL (any number of arguments).
  def apply_wildcards(trace) # AI generated
    args = @raw_args
    return unless trace[:args].is_a?(Array) && args.is_a?(Array) && args.size == trace[:args].size
    e = trace[:except]
    inner = e.is_a?(ComplexError) ? e.inner_error : e
    msg = inner.message.to_s.lines.first.to_s
    named = lambda { |v| wildcard_names(v).any? { |n| msg.match?(/\b#{Regexp.escape(n)}\b/) } }
    # AI generated (2026-10-20): type-level failure (printed "=> :type_except", swept by DeadCallPrune rule
    # PRUNE_TYPE_ERR): the error is a TypeError, or the message names the class of an argument. The receiver's class
    # does not count: lookups name it for value reasons ("Couldn't find User with id=5"). ERR_TYPE_LEVEL=off.
    if ENV["ERR_TYPE_LEVEL"] != "off" && (inner.is_a?(TypeError) || args.any? { |v| named.(v) }) # AI generated
      trace[:type_level] = true # AI generated
    end # AI generated
    blamed = args.each_index.select { |i| named.(args[i]) }
    return apply_key_nogo(trace, args, msg) if blamed.empty? # AI generated
    return unless blamed.size == 1
    i = blamed.first
    new_args = trace[:args].dup
    wild = false
    if ENV["ERR_ANY_POS"] != "off" && args.size > 1
      new_args = new_args.each_with_index.map { |t, j| j == i ? t : :ANY }
      wild = true
    end
    if ENV["ERR_ANY_KEY"] != "off" && args[i].is_a?(Hash) && new_args[i].is_a?(RDL::Type::FiniteHashType)
      keys = args[i].select { |_, v| named.(v) }.keys
      # a message naming Hash may mean the argument itself, not a value inside it: ambiguous, leave it whole
      if keys.size == 1 && !msg.match?(/\bHash\b/) && new_args[i].elts.key?(keys.first)
        new_args[i] = AnyKeysHash.new(keys.first, new_args[i].elts[keys.first])
        wild = true
      end
    end
    return unless wild
    trace[:args] = new_args
    trace[:wild] = true
  end

  # AI generated (2026-10-20): wrong-key failure. No input class is named, but the message contains, as a whole word,
  # exactly one key of a hash argument of this call (e.g. "no such column: users.email"). The key itself is the
  # no-go: recorded as AnyKeysHash(key, :ANY) (that key with any value, any other keys), other positions :ANY.
  # Not applied when that key's value is itself a hash (a nested hash produces "no such column: key.key" for a key
  # that does exist). Marked type-level: a missing column is part of the schema, which effects do not change.
  # ERR_KEY_NOGO=off switches this off.
  def apply_key_nogo(trace, args, msg) # AI generated
    return if ENV["ERR_KEY_NOGO"] == "off"
    hits = args.each_index.select { |i| args[i].is_a?(Hash) && trace[:args][i].is_a?(RDL::Type::FiniteHashType) }
      .flat_map { |i| args[i].keys.select { |k| msg.match?(/\b#{Regexp.escape(k.to_s)}\b/) }.map { |k| [i, k] } }
    return unless hits.size == 1
    i, key = hits.first
    return if args[i][key].is_a?(Hash)
    trace[:args] = trace[:args].each_with_index.map { |t, j|
      if j == i then AnyKeysHash.new(key, :ANY)
      elsif ENV["ERR_ANY_POS"] != "off" then :ANY
      else t
      end
    }
    trace[:wild] = true
    trace[:type_level] = true if ENV["ERR_TYPE_LEVEL"] != "off"
  end

  # AI generated (2026-10-20): == between an RDL type and :ANY or an AnyKeysHash raises NoMethodError in RDL, so
  # wildcard argument lists are compared position by position, by class first
  def same_wild_args?(a, b) # AI generated
    a.size == b.size && a.zip(b).all? { |x, y|
      x.equal?(y) || (x.class == y.class && !x.is_a?(Symbol) && x == y)
    }
  end

  def wildcard_names(v, depth = 0) # AI generated: class names a message can use for a value (see apply_wildcards)
    names = if v.is_a?(Hash)
      depth > 2 ? ["Hash"] : ["Hash", *v.values.flat_map { |x| wildcard_names(x, depth + 1) }]
    elsif v.is_a?(Module)
      [v.class.name, v.name.to_s, v.name.to_s.split("::").last]
    else
      [v.class.name.to_s, v.class.name.to_s.split("::").last]
    end
    names.uniq - ["NilClass", ""]

  end


  def get_reset_newtypes()
    temp = @new_types.dup
    # @new_success = false  # AI altered: reset never reached @newsuccess, so it stayed true forever
    # @new_error = false    # AI altered: reset never reached @newerror
    @newsuccess = false # AI generated
    @newerror = false   # AI generated
    @new_types = []
    temp
  end


  def update_success(trace)

    if !match_exclusion?(trace) && !(trace[:recvr].to_s == "nil")

      # ParentsHelper.addTypeManually(trace[:recvr].to_s)
      # ParentsHelper.addTypeManually(trace[:result].to_s)
      # AI altered: add class names (a %bool receiver/result was added as "true or false", which RDL.nowrap also turned
      # into an RDL key); NilClass is skipped as "nil" was before
      [trace[:recvr], trace[:result]].each { |t| registration_targets(t).each { |name, _| ParentsHelper.addTypeManually(name) unless name == "NilClass" } } # AI generated
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
        if sig[:wild] || trace[:wild] # AI generated (2026-10-20): wildcard records are kept as they are, see apply_wildcards
          return @type_errs if sig[:wild] && trace[:wild] && same_wild_args?(sig[:args], trace[:args]) # AI generated
          next # AI generated
        end # AI generated
        next if !!sig[:type_level] != !!trace[:type_level] # AI generated (2026-10-20): keep type-level records apart

        if sig[:args].size == trace[:args].size
          begin
            sigzip = sig[:args].zip(trace[:args])
          rescue Exception => e
            raise e if e.is_a?(Timeout::Error) || (defined?(Timeout::ExitException) && e.is_a?(Timeout::ExitException)) # AI generated: let timeouts through (was swallowed here)

            binding.pry
          end
          # if sigzip.all? { |old, current| current <= old || old <= current} # AI altered (2026-10-20): recorded RDL bounds
          if sigzip.all? { |old, current| TypeOperations.leq_nc(current, old) || TypeOperations.leq_nc(old, current) } # AI generated
            @newerror = true
            # if all arguments in the old observation are comprable to the current observation
            # reduce each argument to the smallest smaller arguments will be expanding the incorrectness as incorrectness travels upwards. 
            # @type_errs[meth][ind][:args] = sigzip.map {|old, current| old <= current ? old : current} # AI altered (2026-10-20)
            @type_errs[meth][ind][:args] = sigzip.map {|old, current| TypeOperations.leq_nc(old, current) ? old : current} # AI generated
            
            return @type_errs
          end
        end
      end

      @newerror = true
      @type_errs[meth].append(trace)
      return @type_errs

    rescue Exception => e
      raise e if e.is_a?(Timeout::Error) || (defined?(Timeout::ExitException) && e.is_a?(Timeout::ExitException)) # AI generated: let timeouts through (was swallowed here)
      binding.pry
      raise e
    end
  end



  def consolidate_type_successes(trace)

    if trace[:recvr].to_s == "nil"
      puts "caught nil"
      return @type_successes
    end
    # # >>> INSTRUMENTATION H (remove) >>>
    # if ENV["DBG_DYN"] && trace[:method] == :exists?
    #   (@type_successes[trace[:method]] || []).each do |sig|
    #     next unless sig[:recvr] == trace[:recvr]
    #     a, b = sig[:args].first, trace[:args].first
    #     next unless a.is_a?(RDL::Type::FiniteHashType) && b.is_a?(RDL::Type::FiniteHashType)
    #     r = begin
    #       [a <= b, b <= a]
    #     rescue Exception => e
    #       "RAISED #{e.class}: #{e.message[0, 60]}"
    #     end
    #     warn "[H] old=#{a.elts.keys} new=#{b.elts.keys} (old<=new, new<=old)=#{r.inspect}"
    #   end
    # end
    # # <<< INSTRUMENTATION H <<<
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

            # RDL::Globals.info.info[update[:recvr].to_s][meth][:type].each_with_index do |tipe, index|
            #   # now destroy any entries that are more precise than this one. 
            #   if tipe.args.zip(update[:args]).all? {|left, right| left <= right} && tipe.ret <= update[:result] 
            #     # any that is more specific we can destroy
            #     RDL::Globals.info.info[update[:recvr].to_s][meth][:type].pop(index)
            #     RDL::Globals.info.info[update[:recvr].to_s][meth][:effect].pop(index)
            #   end  
            # end
            
            # info = RDL::Globals.info.info[update[:recvr].to_s][meth]  # AI altered: class receivers live under the "[s]" key
            # info = RDL::Globals.info.info[rdl_info_key(update[:recvr])][meth] # AI generated
            # #AI version something about 
            # doomed = []
            # info[:type].each_with_index do |tipe, index|
            #   if tipe.args.zip(update[:args]).all? { |left, right| left <= right } && tipe.ret <= update[:result]
            #     doomed << index
            #   end
            # end
            # doomed.reverse_each do |index|
            #   info[:type].delete_at(index)
            #   info[:effect].delete_at(index)
            # end
            # AI altered: same clean-up, done for each class the signature is filed under (see registration_targets)
            registration_targets(update[:recvr]).each do |name, class_recv| # AI generated
              info = (RDL::Globals.info.info[class_recv ? RDL::Util.add_singleton_marker(name) : name] || {})[meth] # AI generated
              next if info.nil? # AI generated
              doomed = [] # AI generated
              info[:type].each_with_index do |tipe, index| # AI generated
                if tipe.args.zip(update[:args]).all? { |left, right| left <= right } && tipe.ret <= update[:result] # AI generated
                  doomed << index # AI generated
                end # AI generated
              end # AI generated
              doomed.reverse_each do |index| # AI generated
                info[:type].delete_at(index) # AI generated
                info[:effect].delete_at(index) # AI generated
              end # AI generated
              TypeOperations.bump_methods_gen unless doomed.empty? # AI generated (2026-10-19): edited in place, drop methods_of cache
            end # AI generated

            # build the new, more general type into RDL
            # RDL.type update[:recvr].to_s, meth, "(#{update[:args].map(&:to_s).join(', ')}) -> #{update[:result].to_s}"  # AI altered: registered class methods as instance methods
            # RDL.type update[:recvr].to_s, rdl_meth_name(update[:recvr], meth), "(#{update[:args].map(&:to_s).join(', ')}) -> #{update[:result].to_s}"  # AI altered: did not carry the declared read/write effects over
            # carried = carried_effects(update[:recvr], meth) # AI generated
            # RDL.type update[:recvr].to_s, rdl_meth_name(update[:recvr], meth), "(#{update[:args].map(&:to_s).join(', ')}) -> #{update[:result].to_s}", read: carried[:read], write: carried[:write] # AI generated
            # AI altered: filed under update[:recvr].to_s, which for a %bool receiver is "true or false" (not a class); see register_learned
            register_learned(update, meth) # AI generated
            return @type_successes
          end
        end
      end

      # we have not found any type that is a comprable version of this one, we can add it in as is
      @type_successes[meth].append(trace)
      update = @type_successes[meth][-1]
      @newsuccess = true
      @new_types << update
      # RDL.type update[:recvr].to_s, meth, "(#{update[:args].map(&:to_s).join(', ')}) -> #{update[:result].to_s}"  # AI altered: registered class methods as instance methods
      # RDL.type update[:recvr].to_s, rdl_meth_name(update[:recvr], meth), "(#{update[:args].map(&:to_s).join(', ')}) -> #{update[:result].to_s}"  # AI altered: did not carry the declared read/write effects over
      # carried = carried_effects(update[:recvr], meth) # AI generated
      # RDL.type update[:recvr].to_s, rdl_meth_name(update[:recvr], meth), "(#{update[:args].map(&:to_s).join(', ')}) -> #{update[:result].to_s}", read: carried[:read], write: carried[:write] # AI generated
      # AI altered: filed under update[:recvr].to_s, which for a %bool receiver is "true or false" (not a class); see register_learned
      register_learned(update, meth) # AI generated
      return @type_successes

    rescue Exception => e
      raise e if e.is_a?(Timeout::Error) || (defined?(Timeout::ExitException) && e.is_a?(Timeout::ExitException)) # AI generated: let timeouts through (was swallowed here)
      binding.pry
      raise e
    end
  end


  # AI generated: a receiver that is a class (SingletonType of a Class) means the observed
  # call was a class method, so it must be registered as "self.meth" / looked up under "[s]Klass".
  def class_receiver?(recvr) # AI generated
    recvr.is_a?(RDL::Type::SingletonType) && recvr.val.is_a?(Class)
  end

  def rdl_meth_name(recvr, meth) # AI generated
    class_receiver?(recvr) ? "self.#{meth}" : meth
  end

  def rdl_info_key(recvr) # AI generated
    class_receiver?(recvr) ? RDL::Util.add_singleton_marker(recvr.to_s) : recvr.to_s
  end

  # AI generated: where a learned signature is filed. RDL files methods under classes, so a union receiver (e.g. %bool,
  # i.e. true or false) is filed under each member's class, value singletons under their class (true -> TrueClass),
  # generic/hash types under their base class, and %dyn receivers not at all. Returns [[class name, class receiver?]].
  # Works with names, not types: RDL turns NominalType.new(TrueClass) into the singleton type `true` ("true").
  def registration_targets(recvr) # AI generated
    case recvr
    when RDL::Type::UnionType then recvr.types.flat_map { |t| registration_targets(t) }.uniq
    when RDL::Type::OptionalType then registration_targets(recvr.type)
    when RDL::Type::SingletonType
      recvr.val.is_a?(Class) ? [[recvr.val.name, true]] : [[recvr.val.class.name, false]]
    when RDL::Type::NominalType then [[recvr.name.to_s, false]]
    when RDL::Type::GenericType then registration_targets(recvr.base)
    when RDL::Type::FiniteHashType then [["Hash", false]]
    when RDL::Type::DynamicType then []
    else [[recvr.to_s, false]]
    end
  end

  # AI generated: carried_effects for one registration target (class name), with 'self' replaced by that class
  def carried_effects_for(name, class_recv, meth) # AI generated
    placeholder = class_recv ? RDL::Util.add_singleton_marker("DynamicType") : "DynamicType"
    key = class_recv ? RDL::Util.add_singleton_marker(name) : name
    declared = (RDL::Globals.info.info[placeholder] || {})[meth.to_sym] || {}
    existing = (RDL::Globals.info.info[key] || {})[meth.to_sym] || {}
    substitute = lambda { |effs| (effs || []).map { |e| e == 'self' ? name : e.sub(/\Aself\./, "#{name}.") } }
    { read: substitute.(declared[:read]) - (existing[:read] || []), write: substitute.(declared[:write]) - (existing[:write] || []) }
  end

  # AI generated: file one learned signature under each registration target
  def register_learned(update, meth) # AI generated
    sig = "(#{update[:args].map(&:to_s).join(', ')}) -> #{update[:result].to_s}"
    registration_targets(update[:recvr]).each { |name, class_recv|
      carried = carried_effects_for(name, class_recv, meth)
      RDL.type name, (class_recv ? "self.#{meth}" : meth), sig, read: carried[:read], write: carried[:write]
    }
  end

  # AI generated: the read/write effects declared for a moi method on the %dyn placeholder
  # (DynamicType, or [s]DynamicType for class methods) that the concrete class does not have yet.
  # Carried onto the learned signature when it is registered, so the effect system still sees them.
  def carried_effects(recvr, meth) # AI generated
    placeholder = class_receiver?(recvr) ? RDL::Util.add_singleton_marker("DynamicType") : "DynamicType"
    declared = (RDL::Globals.info.info[placeholder] || {})[meth.to_sym] || {}
    existing = (RDL::Globals.info.info[rdl_info_key(recvr)] || {})[meth.to_sym] || {}
    # {
    #   read: (declared[:read] || []) - (existing[:read] || []),
    #   write: (declared[:write] || []) - (existing[:write] || [])
    # }
    # AI altered: the declared effects say 'self'; on a learned signature the receiver's class is known, so 'self' is
    # replaced with it ('self' -> 'DiasporaUser', 'self.x' -> 'DiasporaUser.x'). Left as 'self', ProgWrapper#
    # methods_with_write_effect only substitutes it for the class being searched, and effect_leq raised
    # "cannot have self during leq of effects" when a second model was involved.
    owner = recvr.to_s # AI generated: class name for both NominalType and SingletonType(class) receivers
    substitute = lambda { |effs| (effs || []).map { |e| e == 'self' ? owner : e.sub(/\Aself\./, "#{owner}.") } } # AI generated
    { # AI generated
      read: substitute.(declared[:read]) - (existing[:read] || []), # AI generated
      write: substitute.(declared[:write]) - (existing[:write] || []) # AI generated
    } # AI generated
  end

  def check_errors(ast)
    @checker.update_reset(@type_errs, @type_successes) # resetting the checker
    @checker.process(ast) # the # of errors 
    # binding.pry if x.is_a?(RDL::Type::DynamicType)
    # @checker.update_reset(@type_errs, @type_successes) # resetting the checker
    # x = @checker.process(ast) # the # of errors 
    [@checker.errors, @checker.dynamic_components]  

  end

  def expanded_type_to_s(tipe)
    str = ""
    case tipe
      
    when RDL::Type::OptionalType
      str += "OPT: "
      str += expanded_type_to_s(tipe.type)
    when RDL::Type::SingletonType
      str += "SINGLETON:"
      str += expanded_type_to_s(tipe.nominal)
      str += ", VAL: "
      str += tipe.val.to_s
    when :ANY # AI generated (2026-10-20): wildcard argument position, see apply_wildcards
      str += "ANY" # AI generated
    when AnyKeysHash # AI generated
      str += "FHASH: Elements: #{tipe.key}=>#{expanded_type_to_s(tipe.type)} + ANY" # AI generated
    when RDL::Type::FiniteHashType
      str += "FHASH: "
      str += "Elements: "
      tipe.elts.each {|k, t| str += k.to_s; str += "=>"; str += expanded_type_to_s(t); str == "\n" }
    when RDL::Type::NominalType
      str += "NOMINAL: "
      str += tipe.to_s
    when RDL::Type::GenericType
      str += "GENERIC: "
      str += "BASE: "
      str += expanded_type_to_s(tipe.base)
      tipe.params.each {|i| str += expanded_type_to_s(i)}
    

    else
      #TODO FURTHER EXPAND UPON THESE TYPES, ELSE YOU WILL RUN INTO MORE PROBLEMS WHERE THE TO_STRING FUNCTION HAS COLLISIONS
      str += "OTHER: "
      str += tipe.to_s
    end
    str
  end

  def type_to_s(type)

    # binding.pry
    
    t = expanded_type_to_s(type[:recvr])
    
    if !type[:method].nil?
      t = "#{t} :#{type[:method]}"
    end 
    
    if type[:args] == :ALL
      t = "#{t} => #{type[:args].to_s}"
    
    else 
      type[:args].each {|i|
      t = "#{t} => #{expanded_type_to_s(i)}"
      }
    end

    if !type[:result].nil?
      t = "#{t} => #{expanded_type_to_s(type[:result])}"
    end


    if !type[:except].nil?
      # t = " #{t} => :except" # AI altered (2026-10-20): type-level failures print as :type_except
      t = " #{t} => #{type[:type_level] ? ':type_except' : ':except'}" # AI generated
    end

    t
  end

end