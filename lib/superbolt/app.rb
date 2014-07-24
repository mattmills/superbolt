module Superbolt
  class App
    attr_reader :config, :env, :runner_type, :error_notifier_type
    attr_accessor :logger

    def initialize(name, options={})
      @name                = name
      @env                 = options[:env] || Superbolt.env
      @logger              = options[:logger] || Logger.new($stdout)
      @config              = options[:config] || Superbolt.config
      @runner_type         = options[:runner] || config.runner || :default
      @error_notifier_type = options[:error_notifier] || Superbolt.error_notifier
    end

    def name
      env ? "#{@name}_#{env}" : @name
    end

    # just in case you have a handle to the app and want to quit it
    def quit_queue
      Queue.new("#{connection.name}.quit", connection.config)
    end

    def connection
      @connection ||= Connection::Queue.new(name, config)
    end

    delegate :close, :closing, :exclusive?, :durable?, :auto_delete?,
      :writer, :channel, :q,
        to: :connection

    def queue
      connection.q
    end

    def quit_subscriber_queue
      connection.qq
    end

    def run(&block)
      runner_class.new(queue, error_notifier, logger, block).run
      # quit_subscriber_queue.subscribe do |message|
      #    (message)
      # end
    end

    def runner_class
      runner_map[runner_type] || default_runner
    end

    def runner_map
      {
        pop:      Runner::Pop,
        ack_one:  Runner::AckOne,
        ack:      Runner::Ack,
        greedy:   Runner::Greedy,
        pg:       Runner::Pg
      }
    end

    def default_runner
      runner_map[:ack_one]
    end

    def error_notifier
      @error_notifier ||= error_notifier_class.new(logger)
    end

    def error_notifier_class
      error_notifier_map[error_notifier_type] || default_error_notifier
    end

    def error_notifier_map
      {
        airbrake: ErrorNotifier::Airbrake,
        none:     ErrorNotifier::None
      }
    end

    def default_error_notifier
      error_notifier_map[:none]
    end

    def quit(message='no message given')
      logger.info "EXITING Superbolt App listening on queue #{name}: #{message}"
      q.channel.basic_cancel q.channel.consumers.first[0]
      close
    end
  end
end
