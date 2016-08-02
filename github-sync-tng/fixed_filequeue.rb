# Copyright (c) 2011 Max Ogden and daddz
# Licensed under the MIT License
# Pending https://github.com/pezra/filequeue/pull/4

require 'timeout'

class FileQueue
	attr_accessor :file_name, :delimiter
	
  def initialize(file_name, delimiter="\n")
    @delimiter = delimiter
    @file_name = file_name
  end

  def push(obj)
    if obj.match Regexp.new @delimiter
      raise "Queue objects cannot contain the queue delimiter"
    end
    safe_open 'a' do |file|
      file.write(obj + @delimiter)
    end
  end

  alias << push
	
  def pop
    value = nil
    rest = nil
    safe_open 'r' do |file|
      value = file.gets @delimiter
      rest = file.read
    end
    safe_open 'w+' do |file|
      file.write rest
    end
    value ? value[0..-(@delimiter.length) - 1] : nil
  end

  def length
    count = 0
    unless(File.exist?(@file_name))
      return 0
    end
    safe_open 'r' do |file|
      count = file.read.count @delimiter
    end
    count
  end

  def empty?
    return length == 0
  end

  def clear
    safe_open 'w' do |file| end
  end

  protected

  def safe_open(mode)
    File.open(@file_name, mode) do |file|
      lock file
      yield file
    end
  end

  # Locks the queue file for exclusive access.
  #
  # Raises `FileLockError` if unable to acquire a lock.
  #
  # Return is undefined.
  def lock(file)
    tries = 1000
    until tries == 0 || lock_acquired = file.flock(File::LOCK_NB|File::LOCK_EX)
      tries -= 1
      Thread.pass
    end

    (raise FileLockError, "Queue file appears to be permanently lockecd") unless lock_acquired
  end

  FileLockError = Class.new(Timeout::Error)
end

