def _join *params
  params.join ' && '
end

def template(from, to)
  # File.absolute_path __FILE__
  abs_path    = File.expand_path File.dirname __FILE__
  script_root = File.dirname abs_path
  erb         = File.read script_root + "/capistrano/templates/#{from}"
  put ERB.new(erb).result(binding), to
end

def set_default(name, *args, &block)
  set(name, *args, &block) unless exists?(name)
end