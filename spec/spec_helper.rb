begin
  require 'spec'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rspec'
  require 'spec'
end

debugger
$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift('../ruote2.0/lib')

require 'ruote-amqp'
require 'spec/ruote'
require 'fileutils'

#cmm +1
require 'ruote/engine'

# AMQP magic worked here
AMQP.settings[:vhost] = '/ruote-test'
AMQP.settings[:user]  = 'ruote'
AMQP.settings[:pass]  = 'ruote'

Spec::Runner.configure do |config|

  config.include( RuoteSpecHelpers )

  config.before(:each) do
    @tracer = Tracer.new

    ac = {}

    class << ac
      alias :old_put :[]=
      def []= (k, v)
        raise("!!!!! #{k.class}\n#{k.inspect}") \
          if k.class != String and k.class != Symbol
        old_put(k, v)
      end
    end
    #
    # useful for tracking misuses of the application context

    ac['__tracer'] = @tracer
    ac[:ruby_eval_allowed] = true
    ac[:definition_in_launchitem_allowed] = true

# cmm -1
#    @engine = OpenWFE::Engine.new( ac )
# cmm +2
      @engine = Ruote::Engine.new( ac )
      ENV['DEBUG'] = nil

    @terminated_processes = []
debugger
     @engine.get_expression_pool.add_observer(:terminate) do |c, fe, wi|
       @terminated_processes << fe.fei.wfid
       #p [ :terminated, @terminated_processes ]
     end

    if ENV['DEBUG']
      $OWFE_LOG = Logger.new( STDOUT )
      $OWFE_LOG.level = Logger::DEBUG
    end
  end

  config.after(:each) do
    @engine.stop
    AMQP.stop { EM.stop }
    sleep 0.001 while EM.reactor_running?
  end

  config.after(:all) do
    base = File.expand_path( File.dirname(__FILE__) + '/..' )
    FileUtils.rm_rf( base + '/logs' )
    FileUtils.rm_rf( base + '/work' )
  end
end


class Tracer
  def initialize
    @trace = ''
  end
  def to_s
    @trace.to_s.strip
  end
  def << s
    @trace << s
  end
  def clear
    @trace = ''
  end
  def puts s
    @trace << "#{s}\n"
  end
end
