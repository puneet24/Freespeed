require 'freespeed'

# Testing Freespeed API #

FILES = %w(1.txt 2.txt 3.txt)

FileUtils.touch(FILES)

paths = FILES
a = Freespeed::EventedMonitorChecker.new(paths) do 
		puts "Rails is awesome."
	end
count = 0
while count < 5
	if a.execute_if_updated?
		puts "*"*50
		a.print_events_captured
		puts "*"*50
		count += 1
	end
end