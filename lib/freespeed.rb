# Provides Ruby interface for Native system call libraries of linux.

require "freespeed/version"
require "rb-inotify"

module Freespeed
  # Freespeed module provides the alternative way of implementing File
  # checker API. This module is currently implemented for linux system
  # and is limited to files only.
  #
  # * +initialize+ which expects two parameters and one block as
  #   described below. 
  #
  # * +modified?+ which returns a boolean if there were updates in
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
      @block = block
      @events_captured = []
      @modified = false
      @thr = nil

      @notifier = INotify::Notifier.new
      
      @files.each do |n_file|
  	
  	# Adding watch to the file, it will execute the block if any file event is occured on the file.
        @notifier.watch("#{n_file.to_s}", :modify,:delete_self) do |event| 
              @events_captured << "#{event.flags} event has occured on #{n_file.to_s} at #{Time.now}"
              @modified = true
              stop_file_notifier
        end 
      end 
      start_file_notifier
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
      stop_file_notifier if !@thr.nil?
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

    # This method executes the block and return 'true' if file system is updated else false.
    def execute_if_updated?
      if updated?
        @block.call
        start_file_notifier
        true
      else
        false
      end
    end

  end
end



