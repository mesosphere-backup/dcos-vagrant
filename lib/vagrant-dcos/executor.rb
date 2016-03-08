# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'thread'

module VagrantPlugins
  module DCOS
    class Executor

      # create a pool of worker threads to drain the work queue
      # join the threads to block until they are finished
      def self.exec(proc_queue, max_worker_pool_size)
        worker_pool_size = [proc_queue.size, max_worker_pool_size].min

        worker_pool = (0...worker_pool_size).map do
          Thread.new do
            begin
              while work = proc_queue.pop(true)
                work.call
              end
            rescue ThreadError
              # empty queue - exit loop
            end
          end
        end

        # block until finished
        worker_pool.map(&:join)
      end

    end
  end
end