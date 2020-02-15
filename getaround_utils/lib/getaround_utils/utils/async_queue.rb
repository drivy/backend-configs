module GetaroundUtils; end
module GetaroundUtils::Utils; end

class GetaroundUtils::Utils::AsyncQueue
  include GetaroundUtils::Mixins::Loggable

  MAX_QUEUE_SIZE = 1000
  BUFFER_SIZE = 50

  def initialize
    @queue = []
    @mutex = Mutex.new
    @closed = false
    @worker = Thread.new(&method(:thread_run))
    at_exit { terminate }
  end

  def perform
    raise NotImplementedError
  end

  def push(payload)
    @mutex.synchronize do
      if @queue.size >= MAX_QUEUE_SIZE
        loggable_log(:error, 'queue overflow')
      else
        @queue.push(payload)
      end
    end
  end

  def thread_run
    loop do
      buffer = @mutex.synchronize { @queue.shift(BUFFER_SIZE) }
      loggable_log(:debug, 'thread_run', buffer_size: buffer.size)
      return if @closed && buffer.empty?

      perform(buffer) unless buffer.empty?
      sleep(1) unless @mutex.synchronize { @queue.any? }
    rescue StandardError => e
      loggable_log(:error, e.message, class: e.class.to_s, backtrace: e.backtrace)
    end
  end

  def terminate
    @mutex.synchronize { @closed = true }
    @worker&.join
  end
end
