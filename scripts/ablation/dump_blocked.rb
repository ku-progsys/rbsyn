# AI generated (2026-10-20): loaded with RUBYOPT=-r. At the benchmark's ParentsHelper.subtract, keeps every signature
# the benchmark had before its %dyn window (ParentsHelper.blocked) and the window's own DynamicType declarations; at
# SynthesizerProxy#initialize (the define) writes them to ABLATE_DUMP (JSON) together with the define's function type
# and components, then exits. Used once per benchmark to build the ablation pool.
# Per blocked method: "rets" (classes in its return types), "hash_vals" (classes of finite-hash values in them),
# "computed_rets" (code of ``…`` return types, not evaluated), "computed" (any of its types contains ``…``).
# Per blocked class: "ancestors" (class keys of its ancestors, "[s]X" for class-method keys); "ancestors_all" has the
# same for every class named in the start set, the dump keys and the return types.
require "json"

$__abl_dump = nil

# classes a type reaches: acc[:classes], finite-hash value classes acc[:hash_vals], unevaluated acc[:computed]
def __abl_walk(t, acc)
  case t
  when RDL::Type::NominalType then acc[:classes] << t.name.to_s
  when RDL::Type::GenericType then __abl_walk(t.base, acc); t.params.each { |p| __abl_walk(p, acc) }
  when RDL::Type::UnionType, RDL::Type::IntersectionType then t.types.each { |x| __abl_walk(x, acc) }
  when RDL::Type::FiniteHashType
    acc[:classes] << "Hash"
    sub = { classes: [], hash_vals: [], computed: [] }
    t.elts.values.each { |v| __abl_walk(v, sub) }
    acc[:hash_vals].concat(sub[:classes] + sub[:hash_vals]); acc[:computed].concat(sub[:computed])
  when RDL::Type::TupleType then acc[:classes] << "Array"; t.params.each { |p| __abl_walk(p, acc) }
  when RDL::Type::SingletonType then acc[:classes] << (t.val.is_a?(Module) ? "[s]#{t.val}" : t.val.class.name)
  when RDL::Type::ComputedType then acc[:computed] << t.code.to_s
  when RDL::Type::OptionalType, RDL::Type::VarargType, RDL::Type::AnnotatedArgType, RDL::Type::NonNullType then __abl_walk(t.type, acc)
  end
  acc
end

def __abl_classes_of(types)
  acc = { classes: [], hash_vals: [], computed: [] }
  types.each { |t| __abl_walk(t, acc) }
  acc.transform_values(&:uniq)
end

def __abl_ancestors(key)
  if key.start_with?("[s]")
    c = Object.const_get(key[3..]) rescue nil
    return [] unless c.is_a?(Module)
    c.ancestors.map { |a| "[s]#{a}" } + Class.ancestors.map(&:to_s)
  else
    c = Object.const_get(key) rescue nil
    c.is_a?(Module) ? c.ancestors.map(&:to_s) - [key] : []
  end
end

TracePoint.new(:end) { |tp|
  case tp.self.name
  when "ParentsHelper"
    next if tp.self.singleton_class.ancestors.any? { |m| m.name == "AblateDump" }
    mod = Module.new {
      def subtract(*a)
        r = super
        blocked = blocked().map { |klass, meths|
          [klass, { "ancestors" => __abl_ancestors(klass), "methods" => meths.map { |meth, kinds|
            types = Array(kinds[:type])
            rc = __abl_classes_of(types.map { |t| t.respond_to?(:ret) ? t.ret : t })
            [meth.to_s, {
              "types" => types.map(&:to_s),
              "args" => types.map { |t| t.respond_to?(:args) ? t.args.map { |x| x.class.name.split("::").last } : [] },
              "read" => kinds[:read], "write" => kinds[:write],
              "rets" => rc[:classes], "hash_vals" => rc[:hash_vals], "computed_rets" => rc[:computed],
              "computed" => types.any? { |t| t.to_s.include?("``") },
            }]
          }.to_h }]
        }.to_h
        window = %w[DynamicType [s]DynamicType].flat_map { |key| (RDL::Globals.info.info[key] || {}).map { |m, k| [(key.start_with?("[s]") ? "self." : "") + m.to_s, { "types" => Array(k[:type]).map(&:to_s), "read" => k[:read], "write" => k[:write] }] } }.to_h
        $__abl_dump = { "blocked" => blocked, "window" => window }
        r
      end
    }
    Object.const_set(:AblateDump, mod)
    tp.self.singleton_class.prepend(mod)
  when "SynthesizerProxy"
    next if tp.self.ancestors.any? { |m| m.name == "AblateDumpProxy" }
    mod = Module.new {
      def initialize(mth_name, type, components, *rest)
        ft = RDL::Globals.parser.scan_str(type)
        fc = __abl_classes_of(ft.args + [ft.ret])
        comps = components.map(&:to_s)
        d = ($__abl_dump || { "blocked" => {}, "window" => {} }).merge(
          "functype" => type, "components" => comps,
          "start" => (fc[:classes] + fc[:hash_vals] + comps.flat_map { |c| [c, "[s]#{c}"] }).uniq,
          "start_hash_vals" => fc[:hash_vals], "start_computed" => fc[:computed], "subtract_seen" => !$__abl_dump.nil?)
        # ancestors of every class the pool step can reach (singletons of models are not dump keys themselves)
        names = d["start"] + d["blocked"].flat_map { |k, info| [k] + info["methods"].values.flat_map { |v| v["rets"] + v["hash_vals"] } }
        names = (names + names.reject { |n| n.start_with?("[s]") }.map { |n| "[s]#{n}" }).uniq
        d["ancestors_all"] = names.map { |n| [n, __abl_ancestors(n)] }.to_h
        File.write(ENV["ABLATE_DUMP"], JSON.pretty_generate(d))
        $stderr.puts "[ABLATE_DUMP] wrote #{ENV['ABLATE_DUMP']}"
        exit!(0)
      end
    }
    Object.const_set(:AblateDumpProxy, mod)
    tp.self.prepend(mod)
  end
}.enable
