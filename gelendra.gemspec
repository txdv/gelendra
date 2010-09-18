Gem::Specification.new do |spec|

  spec.platform = Gem::Platform::RUBY
  spec.name        = 'gelendra'
  spec.version     = '0.1'
  spec.summary     = 'GoldSrc engine map managmenet tool'
  spec.description = 'gelendra is a GoldSrc engine (Half-Life, CounterStrike, etc.) map management tool, can be used to manage amxmodx and simmilar as well'

  spec.author   = 'Andrius Bentkus'
  spec.email    = 'ToXedVirus@gmail.com'
  spec.homepage = 'http://www.github.com/txdv/ruby-gelendra/'

  spec.bindir             = 'bin/'
  spec.executables        = ['gelendra']
  spec.default_executable = 'gelendra'

  spec.files = Dir['bin/*']

  spec.has_rdoc = false
  spec.add_dependency('rubyzip', '>= 0.9.4')
end
