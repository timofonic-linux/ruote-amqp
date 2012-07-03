
require File.join(File.dirname(__FILE__), 'spec_helper')

#
# NOTE : RuoteAMQP::LaunchitemListener has been depreacted in favour of
#        RuoteAMQP::Receiver
#

describe RuoteAMQP::LaunchitemListener do

  after(:each) do
    purge_engine
  end

  it 'launches processes' do

    json = {
      'definition' => %{
        Ruote.process_definition :name => 'test' do
          sequence do
            echo '${f:foo}'
          end
        end
      },
      'fields' => { 'foo' => 'bar' }
    }.to_json

    RuoteAMQP::LaunchitemListener.new(@engine)

    AMQP.channel.queue('ruote_launchitems', :durable => true).publish(json)

    sleep 0.5

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == 'bar'
  end

  it 'discards corrupt process definitions' do

    json = {
      'definition' => %{
        I'm a broken process definition
      },
      'fields' => { 'foo' => 'bar' }
    }.to_json

    RuoteAMQP::LaunchitemListener.new(@engine, :unsubscribe => true)

    serr = String.new
    err = StringIO.new(serr, 'w+')
    $stderr = err

    AMQP.channel.queue('ruote_launchitems', :durable => true).publish(json)

    sleep 0.5

    err.close
    $stderr = STDERR

    @engine.should_not have_errors
    @engine.should_not have_remaining_expressions

    @tracer.to_s.should == ''

    serr.should match(/^===/)
  end
end

