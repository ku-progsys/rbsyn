require "set"

# AI generated: decides, per spec, whether its searches need a type-inference pass.
#
# The first spec always uses inference. A later spec uses inference only if its inputs contain something no earlier
# spec had:
#   - argument types: the runtime classes of the arguments its setup passes to the method being synthesized
#     (captured by running the setup once with a stand-in method that only records them); compared per position
#   - assertion calls: the moi calls in its post-condition, as "ReceiverClass#method(argument kinds)", with the
#     receiver's runtime class taken after setup
# NilClass counts as a new type. If a profile cannot be built (e.g. setup raises), the spec uses inference.
class SpecTypeGuard # AI generated
  def initialize(ctx)
    @ctx = ctx
    @seen_args = Hash.new { |h, k| h[k] = Set.new } # position => Set of class names
    @seen_calls = Set.new
  end

  # returns [use_inference, reasons]
  def decide(index, precond, postcond)
    profile = build_profile(precond, postcond)
    if index.zero?
      record(profile) unless profile.nil?
      return [true, ["first spec"]]
    end
    return [true, ["could not profile spec inputs"]] if profile.nil?

    reasons = []
    profile[:args].each_with_index { |klass, pos|
      reasons << "new argument type #{klass} at position #{pos}" unless @seen_args[pos].include?(klass)
    }
    (profile[:calls] - @seen_calls).each { |call| reasons << "new assertion call #{call}" }
    record(profile)
    reasons.empty? ? [false, ["no new types"]] : [true, reasons]
  end

  private

  def record(profile)
    profile[:args].each_with_index { |klass, pos| @seen_args[pos] << klass }
    @seen_calls.merge(profile[:calls])
  end

  def build_profile(precond, postcond)
    klass = Class.new
    captured = nil
    guard = self # the stand-in runs with self = klass, so call back into the guard explicitly
    klass.define_singleton_method(@ctx.mth_name) { |*args| captured = args.map { |a| guard.send(:class_name, a) }; nil }
    DBUtils.reset
    @ctx.reset_func.call unless @ctx.reset_func.nil?
    klass.instance_eval(&precond)
    return nil if captured.nil?
    { args: captured, calls: assertion_calls(postcond, klass) }
  rescue StandardError, SyntaxError => e
    warn "[GD] profile failed: #{e.class}: #{e.message[0, 150]} at #{e.backtrace.first(3).join(' <- ')}" if ENV["DBG_DYN"] # INSTRUMENTATION GD (AI generated, remove)
    nil
  end

  def assertion_calls(postcond, klass)
    ast = Parser::CurrentRuby.parse(postcond.source)
    calls = Set.new
    walk(ast) { |node|
      next unless node.type == :send && @ctx.moi.include?(node.children[1])
      recv, meth, *args = node.children
      calls << "#{describe(recv, klass)}##{meth}(#{args.map { |a| describe(a, klass) }.join(', ')})"
    }
    calls
  end

  def walk(node, &blk)
    return unless node.is_a?(Parser::AST::Node)
    blk.call(node)
    node.children.each { |c| walk(c, &blk) }
  end

  def describe(node, klass)
    return "self" if node.nil?
    case node.type
    when :ivar then class_name(klass.instance_variable_get(node.children[0]))
    when :str, :dstr then "String"
    when :int then "Integer"
    when :float then "Float"
    when :sym then "Symbol"
    when :nil then "NilClass"
    when :true, :false then "%bool"
    when :lvar then "lvar:#{node.children[0]}"
    when :send then "call:#{node.children[1]}"
    else node.type.to_s
    end
  end

  def class_name(value)
    value.is_a?(Class) ? "Class:#{value.name}" : value.class.name
  end
end
