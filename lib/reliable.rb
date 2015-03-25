module Reliable
  def retries(method, up_to:, on:, delay: Tryer.delay, before_retry: Tryer.before_retry, after_call: Tryer.after_call)
    original_method = :"#{method}_without_reliable"
    alias_method original_method, method

    tryer = Tryer.new(up_to: up_to, on: on, delay: delay, before_retry: before_retry, after_call: after_call)
    define_method method do |*args|
      tryer.reliably do
        __send__ original_method, *args
      end
    end
  end

  class Tryer
    class << self
      def delay=(delay)
        @delay = delay
      end

      def delay
        @delay ||= -> x { x ** 2 }
      end

      def before_retry=(before_retry)
        @before_retry = before_retry
      end

      def before_retry
        @before_retry ||= -> e:, tries: {
          warn "Retrying on error: #{e.class.name}: #{e}"
        }
      end

      def after_call=(after_call)
        @after_call = after_call
      end

      def after_call
        @after_call ||= -> value:, error:, tries: {}
      end
    end

    def initialize(up_to:, on:, delay: Tryer.delay, before_retry: Tryer.before_retry, after_call: Tryer.after_call)
      @enumerable = up_to.respond_to?(:each) ? up_to : up_to.times
      @before_retry = before_retry
      @after_call = after_call
      @delay = delay
      @retried_errors = [on].flatten
    end

    def reliably(&block)
      tries = 0
      last_value = nil
      last_error = nil

      @enumerable.each do
        tries += 1

        begin
          if tries > 1
            @before_retry[e: last_error, tries: tries]
            sleep @delay[tries-1]
          end

          last_error = nil
          last_value = block.call
          return last_value
        rescue *@retried_errors => e
          last_error = e
        ensure
          @after_call[value: last_value, error: last_error, tries: tries]
        end
      end

      raise last_error
    end
  end
end
