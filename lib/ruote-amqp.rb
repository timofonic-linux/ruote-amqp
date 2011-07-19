
require 'amqp'

require 'ruote-amqp/version'


#
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

  autoload 'ParticipantProxy',   'ruote-amqp/participant'

  autoload 'Receiver',           'ruote-amqp/receiver'
  autoload 'WorkitemListener',   'ruote-amqp/workitem_listener'
  autoload 'LaunchitemListener', 'ruote-amqp/launchitem_listener'

  def self.use_persistent_messages?
    false
  end
end

