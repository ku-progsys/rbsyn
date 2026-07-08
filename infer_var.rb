#!/usr/bin/env ruby

# infer_var.rb — Use QDL's built-in type inference to infer the type
# of an instance/class/global variable, or the inferred method
# signatures of all methods defined in a given Ruby program.
#
# Usage:
#   ruby infer_var.rb <ruby_program.rb> [variable_name] [class_name]
#
# Examples:
#   ruby infer_var.rb example.rb @contents MyBox
#   ruby infer_var.rb example.rb @@config App
#   ruby infer_var.rb example.rb $verbose
#   ruby infer_var.rb sample_program.rb        # (general inference mode)
#
# In variable-inference mode, the script registers the variable
# for type inference via QDL::Annotate#infer_var_type, tags all
# methods that reference the variable with QDL::Annotate#infer,
# runs QDL.do_infer, and prints the inferred type.
#
# In general-inference mode (no variable given), it tags all
# methods defined in the given file for inference and prints
# their inferred signatures.

VAR_AST_TYPES = {
  /^@[^@]/ => [:ivar, :ivasgn],
  /^@@/    => [:cvar, :cvasgn],
  /^\$/    => [:gvar, :gvasgn],
}.freeze

def usage_and_exit(msg = nil)
  warn msg if msg
  warn "Usage: #{$PROGRAM_NAME} <ruby_program.rb> [variable_name] [class_name]"
  warn "  If variable_name is given and starts with @/@@/$, it is inferred as a variable"
  warn "  If variable_name is a plain name, it is inferred as a method (hole)"
  warn "  If variable_name is omitted, all methods in the file are inferred (general mode)"
  exit 1
end

ruby_file = ARGV[0] or usage_and_exit "Missing: ruby program path"

var_name  = ARGV[1]
var_sym   = var_name&.to_sym

if var_name
  is_var = VAR_AST_TYPES.keys.any? { |re| var_name.match?(re) }
  if is_var
    node_types = VAR_AST_TYPES.find { |re, _| var_name.match?(re) }[1]
  end
end

# ── QDL setup ──────────────────────────────────────────────────────

require 'set'
require 'bundler/setup'

$LOAD_PATH.unshift File.expand_path("../rdl/lib", __dir__)

require 'qdl'
require 'types/core'

QDL.reset
QDL::Config.instance.number_mode = true
QDL::Config.instance.use_precise_string = false
QDL::Config.instance.log_levels[:inference] = :error
QDL::Config.instance.log_levels[:typecheck] = :error
QDL::Config.instance.log_levels[:heuristic] = :error

QDL.type_params :Hash,  [:k, :v], :all?
QDL.type_params :Array, [:t], :all?
QDL.readd_comp_types

# ── Load the target Ruby program ───────────────────────────────────

pre_class_names = ObjectSpace.each_object(Class).map(&:to_s).to_set

require File.expand_path(ruby_file)

post_class_names = ObjectSpace.each_object(Class).map(&:to_s).to_set

# ── AST walk helpers ───────────────────────────────────────────────

def ast_references_var?(node, var_sym, node_types)
  return false unless node.is_a?(AST::Node)
  return true if node_types.include?(node.type) && node.children[0] == var_sym
  node.children.any? { |child| ast_references_var?(child, var_sym, node_types) }
end

def ast_calls_method?(node, meth_name)
  return false unless node.is_a?(AST::Node)
  return true if node.type == :send && node.children[1] == meth_name
  node.children.any? { |child| ast_calls_method?(child, meth_name) }
end

def extract_methods(ast)
  methods = Set.new
  walk = ->(node) {
    return unless node.is_a?(AST::Node)
    methods << node.children[0] if node.type == :def
    methods << node.children[1] if node.type == :defs
    node.children.each { |c| walk.call(c) }
  }
  walk.call(ast)
  methods
end

def defs_in_file(file_path)
  extract_methods(Parser::CurrentRuby.parse_file(file_path))
end

def each_method_ast(klass)
  (klass.instance_methods(false) + klass.private_instance_methods(false)).uniq.each do |meth|
    begin
      ast = QDL::Typecheck.get_ast(klass, meth)
    rescue => e
      $stderr.puts "  [skip] #{klass}##{meth}: #{e.message}"
      next
    end
    yield meth, ast if ast
  end
end

def stub_missing_methods!(klass, file_ast, file_methods)
  hole_arities = Hash.new { |h, k| h[k] = Set.new }
  walk_arity = ->(node) {
    return unless node.is_a?(AST::Node)
    if node.type == :send && node.children[0].nil?
      meth_name = node.children[1]
      unless file_methods.include?(meth_name) ||
             klass.method_defined?(meth_name) ||
             klass.private_method_defined?(meth_name)
        hole_arities[meth_name] << node.children[2..].size
      end
    end
    node.children.each { |c| walk_arity.call(c) }
  }
  walk_arity.call(file_ast)

  hole_arities.each do |meth_name, arities|
    arity = arities.max
    if arity == 0
      klass.define_method(meth_name) { }
    else
      klass.define_method(meth_name) { |*a| }
    end
    $stderr.puts "  stubbed #{klass}##{meth_name} (arity=#{arity})"
  end

  hole_arities.keys
end

# Compute set of stubbed methods used in arithmetic context (+, -, *, /)
def arithmetic_hole_methods(klass, file_ast, file_methods)
  result = Set.new
  walk = ->(node) {
    return unless node.is_a?(AST::Node)
    if node.type == :send && %i[+ - * /].include?(node.children[1])
      # Check the receiver
      recv = node.children[0]
      if recv.is_a?(AST::Node) && recv.type == :send && recv.children[0].nil?
        result << recv.children[1] unless file_methods.include?(recv.children[1])
      end
      # Check arguments
      node.children[2..].each { |arg|
        if arg.is_a?(AST::Node) && arg.type == :send && arg.children[0].nil?
          meth_name = arg.children[1]
          result << meth_name unless file_methods.include?(meth_name)
        end
      }
    end
    node.children.each { |c| walk.call(c) }
  }
  walk.call(file_ast)
  result
end

# ── Determine target classes ───────────────────────────────────────

if ARGV[2]
  target_classes = [Object.const_get(ARGV[2])]
else
  new_names = post_class_names - pre_class_names
  target_classes = new_names.map { |name|
    begin; Object.const_get(name); rescue; nil; end
  }.compact.select { |cls|
    cls.instance_methods(false).any? || cls.methods(false).any?
  }
  target_classes = ObjectSpace.each_object(Class).select { |cls|
    cls.instance_methods(false).any? || cls.methods(false).any?
  } if target_classes.empty?
end

# ── Parse file AST and file-local methods once ────────────────────

file_ast = Parser::CurrentRuby.parse_file(File.expand_path(ruby_file))
file_methods = extract_methods(file_ast)

# Restrict to classes that define file-local methods (avoids scanning all system classes)
if ARGV[2].nil?
  target_classes = target_classes.select { |cls|
    (cls.instance_methods(false) + cls.private_instance_methods(false)).any? { |m| file_methods.include?(m) }
  }
end

# ── Tag methods for inference ─────────────────────────────────────

inference_label = :infer_var

# Pre-compute arithmetic hole methods for heuristic
$arithmetic_hole_methods = Set.new

target_classes.each do |klass|
  klass_name = klass.to_s
  next if klass_name.start_with?('#<') # skip anonymous classes

  $stderr.puts "Checking #{klass_name}..."

  klass.extend QDL::Annotate

  stub_missing_methods!(klass, file_ast, file_methods)
  $arithmetic_hole_methods.merge(arithmetic_hole_methods(klass, file_ast, file_methods))

  if var_name
    if VAR_AST_TYPES.keys.any? { |re| var_name.match?(re) }
      # ── Variable inference mode ──
      begin
        klass.infer_var_type(klass, var_sym)
      rescue RuntimeError => e
        $stderr.puts "  infer_var_type: #{e.message}"
        next
      end

      used = false

      # Tier 1: only methods defined in the given file
      each_method_ast(klass) do |meth, ast|
        next unless file_methods.include?(meth)
        if ast_references_var?(ast, var_sym, node_types)
          $stderr.puts "  tagging #{klass}##{meth}"
          klass.infer meth, time: inference_label
          used = true
        end
      end

      # Tier 2: all methods (library fallback)
      unless used
        plain = var_name.sub(/^[@$]+/, '').to_sym
        if file_methods.include?(plain)
          $stderr.puts "  (no file-local methods reference #{var_name}, but #{plain} exists as a method — try `#{plain}` instead of `#{var_name}`)"
        else
          $stderr.puts "  (no file-local methods reference #{var_name}, checking all methods)"
        end
        each_method_ast(klass) do |meth, ast|
          if ast_references_var?(ast, var_sym, node_types)
            $stderr.puts "  tagging #{klass}##{meth}"
            klass.infer meth, time: inference_label
            used = true
          end
        end
      end

      # Tier 3: tag all file-local methods as last resort
      unless used
        $stderr.puts "  (no methods reference #{var_name}, trying all file-local methods anyway)"
        each_method_ast(klass) { |meth, _| next unless file_methods.include?(meth); klass.infer meth, time: inference_label }
      end
    else
      # ── Single-method inference mode ──
      target_meth = var_sym

      used = false

      each_method_ast(klass) do |meth, ast|
        if meth == target_meth
          $stderr.puts "  tagging #{klass}##{meth} (target)"
          klass.infer meth, time: inference_label
          used = true
        elsif ast_calls_method?(ast, target_meth)
          $stderr.puts "  tagging #{klass}##{meth} (calls #{target_meth})"
          klass.infer meth, time: inference_label
          used = true
        end
      end

      unless used
        $stderr.puts "  (no methods reference #{var_name}, trying all file methods anyway)"
        each_method_ast(klass) do |meth, _|
          next unless file_methods.include?(meth)
          klass.infer meth, time: inference_label
        end
      end
    end
  else
    # ── General inference mode: tag all file-local methods ──
    each_method_ast(klass) do |meth, ast|
      next unless file_methods.include?(meth)
      $stderr.puts "  tagging #{klass}##{meth} for inference"
      klass.infer meth, time: inference_label
    end
  end
end

# Register heuristic for stubbed hole methods used in arithmetic
QDL::Heuristic.add(:arithmetic_hole) { |var|
  if var.category == :ret && $arithmetic_hole_methods.include?(var.meth)
    QDL::Globals.types[:integer]
  end
}

$stderr.puts "\nRunning inference..."
QDL.do_infer inference_label, render_report: false

# ── Post-processing: extract solutions for stubbed hole methods ────
# (they weren't in constrained_types because _infer returned early—no AST)
# We call extract_meth_sol directly instead of extract_solutions to
# avoid make_extraction_report trying to access non-existent ASTs.
target_classes.each do |klass|
  klass_name = klass.to_s
  next if klass_name.start_with?('#<')
  $arithmetic_hole_methods.each do |meth_name|
    types = QDL::Globals.info.get(klass_name, meth_name, :type)
    next unless types.is_a?(Array) && types[0]
    QDL::Typecheck.extract_meth_sol(types[0]) rescue nil
  end
end

def format_method_sol(tmeth)
  arg_strs = tmeth.args.map { |a|
    sol = a.solution rescue nil
    if sol
      sol.to_s
    elsif a.is_a?(QDL::Type::VarargType)
      "*#{format_type_sol(a.type)}"
    elsif a.is_a?(QDL::Type::OptionalType)
      "?#{format_type_sol(a.type)}"
    else
      format_type_sol(a)
    end
  }
  ret_sol = tmeth.ret.solution rescue nil
  ret_str = ret_sol ? ret_sol.to_s : format_type_sol(tmeth.ret)
  "(#{arg_strs.join(', ')}) -> #{ret_str}"
end

def format_type_sol(typ)
  if typ.is_a?(QDL::Type::VarType) && typ.solution
    typ.solution.to_s
  elsif typ.is_a?(QDL::Type::VarType)
    typ.to_s
  else
    typ.to_s
  end
end

# ── Print results ──────────────────────────────────────────────────

$stderr.puts "\nInferred types:\n\n"

if var_name
  if VAR_AST_TYPES.keys.any? { |re| var_name.match?(re) }
    target_classes.each do |klass|
      klass_name = klass.to_s
      next if klass_name.start_with?('#<')

      typ = QDL::Globals.info.get(klass_name, var_sym, :type)

      if typ.is_a?(QDL::Type::VarType) && typ.solution
        puts "#{klass_name}#{var_name} :: #{typ.solution}"
      elsif typ.is_a?(QDL::Type::VarType)
        puts "#{klass_name}#{var_name} :: (no solution — no constraints generated)"
      elsif typ
        puts "#{klass_name}#{var_name} :: #{typ}"
      else
        puts "#{klass_name}#{var_name} :: (not registered)"
      end
    end
  else
    target_meth = var_sym
    target_classes.each do |klass|
      klass_name = klass.to_s
      next if klass_name.start_with?('#<')

      types = QDL::Globals.info.get(klass_name, target_meth, :type)
      if types.is_a?(Array) && types[0]
        tmeth = types[0]
        puts "#{klass_name}##{target_meth} :: #{format_method_sol(tmeth)}"
      else
        puts "#{klass_name}##{target_meth} :: (not registered)"
      end
    end
  end
else
  target_classes.each do |klass|
    klass_name = klass.to_s
    next if klass_name.start_with?('#<')

    puts "#{klass_name}:"
    (klass.instance_methods(false) + klass.private_instance_methods(false)).uniq.each do |meth|
      next unless file_methods.include?(meth)

      types = QDL::Globals.info.get(klass_name, meth, :type)
      next unless types.is_a?(Array) && types[0]

      sol = format_method_sol(types[0])
      puts "  #{meth} :: #{sol}"
    end
    puts
  end
end
