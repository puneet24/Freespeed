# Provides Ruby interface for Native system call libraries of linux.

require "rb-inotify"

module Freespeed
  # Freespeed module provides the alternative way of implementing File
  # checker API. This module is currently implemented for linux system
  # and is limited to files only.
  #
  # * +initialize+ which expects two parameters and one block as
  #   described below. 
  #
  # * +updated?+ which returns a boolean if there were updates in
  #   the filesystem or not.
  #
  # * +start_file_notifier+ which just start the file notifier on thread.
  #
  # * +stop_file_notifier+ which just stops the file notifier.
  #
  # * +execute_if_updated+ which just executes the block if it was updated.

  class EventedMonitorChecker
    # It accepts two parameters on initialization. The first is an array
    # of files and the second is an optional hash of directories. The hash must
    # have directories as keys and the value is an array of extensions to be
    # watched under that directory.
    #
    # This method must also receive a block that will be called once a path
    # changes. The array of files and list of directories cannot be changed
    # after FileUpdateChecker has been initialized.
    def initialize(files, dirs={}, &block)
      @files = files.freeze
      @glob = compile_glob(dirs)
      @block = block
      @events_captured = []
      @modified = false
      @thr = nil
      @watched = watched
      @dir_hash = Hash.new
      @files_hash = Hash.new
      @last_mtime = Time.now

      @notifier = INotify::Notifier.new

      @watched.each do |n_file|
      		abs_path = File.expand_path(n_file)
      		if @files_hash[abs_path].nil?
      			@files_hash[abs_path] = true
      		end
      		dir_path = File.dirname(abs_path)
      		abs_dir_path = File.expand_path(dir_path)
      		if @dir_hash[abs_dir_path].nil?
      			@dir_hash[abs_dir_path] = Array.new
      			@dir_hash[abs_dir_path] << abs_path
      		else
      			@dir_hash[abs_dir_path] << abs_path
      		end
      end

      # #printing dir_hash
      # @dir_hash.each do |key,pair|
      # 	puts "key - #{key} and pair - #{pair}"
      # end

      # #printing files_hash
      # @files_hash.each do |key,pair|
      # 	puts "key - #{key} and pair - #{pair}"
      # end

      #Adding watch to the file, it will execute the block if any file event is occured on the file.
      @dir_hash.each do |key,pair| 
      	@notifier.watch(key,:all_events) do |event|
      		#puts "#{event.absolute_name} on #{event.flags}"
      		@events_captured << "#{event.absolute_name}"
      		check_status
      	end
      end
      
      start_file_notifier
    end

    # this method is to check updations in any of the watched file.
    def check_status
    	# @files_hash contains key as files to be watched and value as true.
    	@events_captured.each do |event|
    		if @files_hash[event.to_s] && ( !File.exists?(event.to_s) || @last_mtime < File.mtime(event.to_s))
    			@modified = true
    			stop_file_notifier
    			@events_captured = []
    			break
    		end
    	end
    end

    # This method prints all the events captured by the notifier.
    def print_events_captured 
        @events_captured.each do |event|
          puts event
        end
    end

    # This method starts taking events by starting the notifier in thread.
    def start_file_notifier
      @modified = false
      stop_file_notifier
      @thr = Thread.new {@notifier.run}
    end

    # This method stops taking the events and stops the thread.
    def stop_file_notifier
      @notifier.stop
      @thr.exit if !@thr.nil?
      @thr = nil
    end

    # This method returns the status, returns 'true' if file system updated else 'false'.
    def updated?
      @modified
    end

    def execute
    	@block.call
    	@last_mtime = Time.now
        @modified = false
    end

    # This method executes the block and return 'true' if file system is updated else false.
    def execute_if_updated
      #check_status
      #puts updated?
      if updated?
       	execute
        start_file_notifier
        true
      else
        false
      end
    end

    def compile_glob(hash)
      hash.freeze # Freeze so changes aren't accidentally pushed
      return if hash.empty?

      globs = hash.map do |key, value|
        "#{escape(key)}/**/*#{compile_ext(value)}"
      end
      "{#{globs.join(",")}}"
    end

    def escape(key)
      key.gsub(',','\,')
    end

    def compile_ext(array)
      array = Array(array)
      return if array.empty?
      ".{#{array.join(",")}}"
    end

    def watched
        all = @files.select { |f| File.exist?(f) }
        all.concat(Dir[@glob]) if @glob
        all
    end

  end
end



