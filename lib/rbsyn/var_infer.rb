#!/usr/bin/env ruby

# var_infer.rb — Use QDL's built-in type inference to infer the type
# of an instance/class/global variable, or the inferred method
# signatures of all methods defined in a given Ruby program.
#
# CLI Usage:
#   ruby var_infer.rb <ruby_program.rb> [variable_name] [class_name]
#
# Programmatic Usage:
#   require_relative 'var_infer'
#   VarInfer.infer_from_file('example.rb', var_name: '@contents', class_name: 'MyBox')
#   VarInfer.infer_from_file('example.rb', var_name: '@contents')
#   VarInfer.infer_from_file('example.rb', class_name: 'MyBox')
#   VarInfer.infer_from_file('sample_program.rb')

require 'set'

VAR_AST_TYPES = {
  /^@[^@]/ => [:ivar, :ivasgn],
  /^@@/    => [:cvar, :cvasgn],
  /^\$/    => [:gvar, :gvasgn],
}.freeze

module VarInfer
  module_function

  def infer_from_file(file_path, var_name: nil, class_name: nil)
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

    var_sym = var_name&.to_sym
    node_types = nil

    if var_name
      match = VAR_AST_TYPES.find { |re, _| var_name.match?(re) }
      node_types = match[1] if match
    end

    pre_class_names = ObjectSpace.each_object(Class).map(&:to_s).to_set
    require File.expand_path(file_path)
    post_class_names = ObjectSpace.each_object(Class).map(&:to_s).to_set

    # Determine target classes
    target_classes = if class_name
      [Object.const_get(class_name)]
    else
      new_names = post_class_names - pre_class_names
      classes = new_names.map { |name|
        begin; Object.const_get(name); rescue; nil; end
      }.compact.select { |cls|
        cls.instance_methods(false).any? || cls.methods(false).any?
      }
      if classes.empty?
        classes = ObjectSpace.each_object(Class).select { |cls|
          cls.instance_methods(false).any? || cls.methods(false).any?
        }
      end
      classes
    end

    file_ast = Parser::CurrentRuby.parse_file(File.expand_path(file_path))
    file_methods = extract_methods(file_ast)

    if class_name.nil?
      target_classes = target_classes.select { |cls|
        (cls.instance_methods(false) + cls.private_instance_methods(false)).any? { |m| file_methods.include?(m) }
      }
    end

    inference_label = :infer_var
    arithmetic_hole_set = Set.new

    target_classes.each do |klass|
      klass_name = klass.to_s
      next if klass_name.start_with?('#<')

      $stderr.puts "Checking #{klass_name}..."

      klass.extend QDL::Annotate

      stub_missing_methods!(klass, file_ast, file_methods)
      arithmetic_hole_set.merge(arithmetic_hole_methods(klass, file_ast, file_methods))

      if var_name
        if node_types
          # Variable inference mode
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
          # Single-method inference mode
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
        # General inference mode: tag all file-local methods
        each_method_ast(klass) do |meth, ast|
          next unless file_methods.include?(meth)
          $stderr.puts "  tagging #{klass}##{meth} for inference"
          klass.infer meth, time: inference_label
        end
      end
    end

    QDL::Heuristic.add(:arithmetic_hole) { |var|
      if var.category == :ret && arithmetic_hole_set.include?(var.meth)
        QDL::Globals.types[:integer]
      end
    }

    $stderr.puts "\nRunning inference..."
    QDL.do_infer inference_label, render_report: false

    target_classes.each do |klass|
      klass_name = klass.to_s
      next if klass_name.start_with?('#<')
      arithmetic_hole_set.each do |meth_name|
        types = QDL::Globals.info.get(klass_name, meth_name, :type)
        next unless types.is_a?(Array) && types[0]
        QDL::Typecheck.extract_meth_sol(types[0]) rescue nil
      end
    end

    build_result(target_classes, var_name, var_sym, node_types, file_methods)
  end

  # ── AST walk helpers ──────────────────────────────────────────────

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

  def arithmetic_hole_methods(klass, file_ast, file_methods)
    result = Set.new
    walk = ->(node) {
      return unless node.is_a?(AST::Node)
      if node.type == :send && %i[+ - * /].include?(node.children[1])
        recv = node.children[0]
        if recv.is_a?(AST::Node) && recv.type == :send && recv.children[0].nil?
          result << recv.children[1] unless file_methods.include?(recv.children[1])
        end
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

  # ── Result formatting ────────────────────────────────────────────

  def build_result(target_classes, var_name, var_sym, node_types, file_methods)
    result = {}
    target_classes.each do |klass|
      klass_name = klass.to_s
      next if klass_name.start_with?('#<')
      result[klass_name] = {}

      if var_name
        if node_types
          typ = QDL::Globals.info.get(klass_name, var_sym, :type)
          result[klass_name][:variables] = {}
          if typ.is_a?(QDL::Type::VarType) && typ.solution
            result[klass_name][:variables][var_name] = typ.solution.to_s
          elsif typ.is_a?(QDL::Type::VarType)
            result[klass_name][:variables][var_name] = nil
          elsif typ
            result[klass_name][:variables][var_name] = typ.to_s
          end
        else
          result[klass_name][:methods] = {}
          types = QDL::Globals.info.get(klass_name, var_sym, :type)
          if types.is_a?(Array) && types[0]
            result[klass_name][:methods][var_sym] = format_method_sol(types[0])
          end
        end
      else
        (klass.instance_methods(false) + klass.private_instance_methods(false)).uniq.each do |meth|
          next unless file_methods.include?(meth)
          types = QDL::Globals.info.get(klass_name, meth, :type)
          next unless types.is_a?(Array) && types[0]
          (result[klass_name][:methods] ||= {})[meth] = format_method_sol(types[0])
        end
      end

      result.delete(klass_name) if result[klass_name].empty?
    end
    result
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

  def usage_and_exit(msg = nil)
    warn msg if msg
    warn "Usage: #{$PROGRAM_NAME} <ruby_program.rb> [variable_name] [class_name]"
    warn "  If variable_name is given and starts with @/@@/$, it is inferred as a variable"
    warn "  If variable_name is a plain name, it is inferred as a method (hole)"
    warn "  If variable_name is omitted, all methods in the file are inferred (general mode)"
    exit 1
  end

  # ── Sketch inference ────────────────────────────────────────────

  def infer_sketch(file_path)
    result = infer_from_file(file_path, class_name: nil)
    return {} if result.empty?

    method_types = {}
    hole_types = {}

    result.each do |klass_name, types|
      next unless types[:methods]
      types[:methods].each do |meth, sig_str|
        begin
          tmeth = RDL::Globals.parser.scan_str(sig_str)
          method_types[meth] = tmeth
        rescue => e
          $stderr.puts "  [warn] could not parse signature for #{meth}: #{sig_str}"
        end
        if meth.to_s.start_with?('rbsyn_hole_')
          hole_types[meth] = method_types[meth].ret if method_types[meth]
        end
      end
    end

    { method_types: method_types, hole_types: hole_types }
  end
end

# ── CLI entry point ────────────────────────────────────────────────────

if __FILE__ == $PROGRAM_NAME
  ruby_file = ARGV[0] or VarInfer.usage_and_exit "Missing: ruby program path"
  var_name  = ARGV[1]
  class_name = ARGV[2]

  result = VarInfer.infer_from_file(ruby_file, var_name: var_name, class_name: class_name)

  $stderr.puts "\nInferred types:\n\n"

  result.each do |klass_name, types|
    if types[:variables]
      types[:variables].each do |var, typ|
        if typ
          puts "#{klass_name}#{var} :: #{typ}"
        else
          puts "#{klass_name}#{var} :: (no solution — no constraints generated)"
        end
      end
    end

    if types[:methods]
      puts "#{klass_name}:"
      types[:methods].each do |meth, sig|
        puts "  #{meth} :: #{sig}"
      end
      puts
    end
  end
end
