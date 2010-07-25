
require 'ruote-amqp'
require 'AIR/Server'

module RuoteAMQP

  #
  # = AMQP Receiver
  #
  # Used in conjunction with the RuoteAMQP::Participant, the WorkitemListener
  # subscribes to a specific direct exchange and monitors for
  # incoming workitems. It expects workitems to arrive serialized as
  # JSON.
  #
  # == Configuration
  #
  # AMQP configuration is handled by directly manipulating the values of
  # the +AMQP.settings+ hash, as provided by the AMQP gem. No
  # defaults are set by the listener. The only +option+ parsed by
  # the initializer of the workitem listener is the +queue+ key (Hash
  # expected). If no +queue+ key is set, the listener will subscribe
  # to the +ruote_workitems+ direct exchange for workitems, otherwise it will
  # subscribe to the direct exchange provided.
  #
  # == Usage
  #
  # Register the engine or storage with the listener:
  #
  #   RuoteAMQP::Receiver.new( engine_or_storage )
  #
  # The workitem listener leverages the asynchronous nature of the amqp gem,
  # so no timers are setup when initialized.
  #
  # == Options
  #
  # :queue and :launchitems
  #
  # See the RuoteAMQP::Participant docs for information on sending
  # workitems out to remote participants, and have them send replies
  # to the correct direct exchange specified in the workitem
  # attributes.
  #
  class Receiver < Ruote::Receiver

    attr_reader :queue

    # Starts a new Receiver
    #
    # Two arguments for this method.
    #
    # The first oone should be a Ruote::Engine, a Ruote::Storage or
    # a Ruote::Worker instance.
    #
    # The second one is a hash for options. There are two known options :
    #
    # :queue for setting the queue on which to listen (defaults to
    # 'ruote_workitems').
    #
    # The :launchitems option :
    #
    #   :launchitems => true
    #     # the receiver accepts workitems and launchitems
    #   :launchitems => false
    #     # the receiver only accepts workitems
    #   :launchitems => :only
    #     # the receiver only accepts launchitems
    #
    def initialize( engine_or_storage, opts = {} )

      super( engine_or_storage )
      @engine_storage = engine_or_storage
      @launchitems = opts[:launchitems]

      @queue = 'ruote_workitems'
      @queue = 'ruote_launchitems' if @launchitems == :only
      @queue = opts[:queue] if opts[:queue]

      RuoteAMQP.start!

      MQ.queue( @queue ).unsubscribe # taking over...
      sleep 0.3

      engine_proxy = AIR::Server.new(:host => AMQP.settings["host"],
                                     :user => AMQP.settings["user"],
                                     :pass => AMQP.settings["pass"],
                                     :vhost => AMQP.settings["vhost"])

      srv.register("register", method(:register_remote))
      srv.register("list", method(:list_remote))

      MQ.queue( @queue, :durable => true ).subscribe do |message|
        if AMQP.closing?
          # do nothing, we're going down
        else
          handle( message )
        end
      end
    end
    def stop
      engine_proxy.stop!
      RuoteAMQP.stop!
    end

    private

    def handle( msg )

      item = Rufus::Json.decode( msg ) rescue nil

      return unless item.is_a?(Hash)

      not_li = ! (item.has_key?('definition') or item.has_key?('register'))

      return if @launchitems == :only && not_li
      return unless @launchitems || not_li

      if not_li
        receive( item ) # workitem resumes in its process instance
      else
        launch( item ) # new process instance launch
      end
    end

    def launch( hash )
      super(hash['definition'], hash['fields'] || {}, hash['variables'] || {})
    end

    # Called by the RPC mechanism from remote systems to register a participant
    def register_remote(args, kwargs)
      return unless kwargs.has_key?('name')
      return @engine_storage.register_participant(kwargs["name"],
                                                  RuoteAMQP::Participant,
                                                  kwargs["options"])
    end

    # Called by the RPC mechanism from remote systems to get a list of participants
    def list_remote(args, kwargs)
      return @engine_storage.participant_list
    end
  end
end


