module GetaroundUtils; end
module GetaroundUtils::Utils; end

class GetaroundUtils::Utils::AsyncQueue
  class << self
    include GetaroundUtils::Mixins::Loggable

    MAX_QUEUE_SIZE = 100
    MUTEX = Mutex.new

    def perform
      raise NotImplementedError
    end

    def perform_async(*args)
      start_once!

      if @queue.size > MAX_QUEUE_SIZE
        loggable('warn', 'Queue is overflowing')
        return
      end

      @queue.push(args)
    end

    def start_once!
      MUTEX.synchronize do
        return unless @parent.nil?

        @parent = Process.pid
        @queue = Queue.new

        @worker = Thread.new do
          while args = @queue.pop
            begin
              perform(*args)
            rescue ClosedQueueError
              nil
            rescue StandardError => e
              loggable('error', e.message, class: e.class.to_s, backtrace: e.backtrace)
            end
          end
        end

        at_exit { terminate }
      end
    end

    def terminate
      @queue&.close
      @worker&.join
    end

    def reset
      terminate
      @parent = nil
    end
  end
end
