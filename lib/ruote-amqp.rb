require 'mq'

# AMQP participant and listener pair for ruote.
#
# == Documentation
#
# See #RuoteAMQP::Listener and #RuoteAMQP::Participant for detailed
# documentation on using each of them.
#
# == AMQP Notes
#
# RuoteAMQP uses durable queues and persistent messages by default, to ensure
# no messages get lost along the way and that running expressions doesn't have
# to be restarted in order for messages to be resent.
#
module RuoteAMQP

  VERSION = '2.0'

  autoload 'Participant', 'ruote-amqp/participant'
  autoload 'Listener',    'ruote-amqp/listener'

  class << self

    attr_writer :use_persistent_messages

    # Whether or not to use persistent messages (true by default)
    def use_persistent_messages?
      @use_persistent_messages ||= true
    end

    private
    @@active_threads = {}

    public
    def with_reactor(name, &blk)
      @@active_threads[name] = Thread.new do
        Thread.abort_on_exception = true
        EM.run(&blk)
      end
    end

    def stop(name = nil)
      return nil unless thread = @@active_threads[name]
      thread.kill.join
    end

    def shutdown #:nodoc:
      @@active_threads.each{ |k, t| t.kill.join }.clear
    end

end
