require 'log4jruby/log4j_args'

# Slightly Modified JRuby Logger
require 'log4jruby/jruby/logger'

module Log4jruby
  
  # Author::    Lenny Marks
  #
  # Wrapper around org.apache.log4j.Logger with interface similar to standard ruby Logger.
  #
  # * Ruby and Java exceptions are logged with backtraces.
  # * fileName, lineNumber, methodName available to appender layouts via MDC variables(e.g. %X{lineNumber}) 
  class Logger
    BLANK_CALLER = ['', '', ''] #:nodoc:

    LOG4J_LEVELS = {
        Java::org.apache.log4j.Level::DEBUG => ::StdLogger::DEBUG,
        Java::org.apache.log4j.Level::INFO => ::StdLogger::INFO,
        Java::org.apache.log4j.Level::WARN => ::StdLogger::WARN,
        Java::org.apache.log4j.Level::ERROR => ::StdLogger::ERROR,
        Java::org.apache.log4j.Level::FATAL => ::StdLogger::FATAL,
        Java::org.apache.log4j.Level::ALL => ::StdLogger::UNKNOWN,
    }

    LOGGER_LEVELS = {
        ::StdLogger::DEBUG => Java::org.apache.log4j.Level::DEBUG,
        ::StdLogger::INFO => Java::org.apache.log4j.Level::INFO,
        ::StdLogger::WARN => Java::org.apache.log4j.Level::WARN,
        ::StdLogger::ERROR => Java::org.apache.log4j.Level::ERROR,
        ::StdLogger::FATAL => Java::org.apache.log4j.Level::FATAL,
        ::StdLogger::UNKNOWN => Java::org.apache.log4j.Level::ALL,
    }

    include StdLogger::Severity

    class Error < StdLogger::Error
    end

    class ShiftingError < StdLogger::ShiftingError
    end

    class Application < StdLogger::Application
    end

    class Formatter
      def initialize
        raise 'Unimplemented Functionality.'
      end
    end

    class LogDevice
      def initialize
        raise 'Unimplemented Functionality.'
      end
    end

    # turn tracing on to make fileName, lineNumber, and methodName available to 
    # appender layout through MDC(ie. %X{fileName} %X{lineNumber} %X{methodName})
    attr_accessor :tracing

    class << self
      def logger_mapping
        @logger_mapping ||= {}
      end
      
      # get Logger for name
      def[](name)
        name = name.nil? ? 'jruby' : "jruby.#{name.gsub('::', '.')}"
       
        log4j = Java::org.apache.log4j.Logger.getLogger(name)
        log4jruby = logger_mapping[log4j]
        
        unless log4jruby
          log4jruby = new(log4j)
        end
        
        log4jruby
      end

      # same as [] but accepts attributes
      def get(name = nil, values = {})
        logger = self[name]
        logger.attributes = values
        logger
      end
      
      # Return root Logger(i.e. jruby)
      def root
        log4j = Java::org.apache.log4j.Logger.getLogger('jruby')
        
        log4jruby = logger_mapping[log4j]
        unless log4jruby
          log4jruby = new(log4j)
        end
        log4jruby
      end   
    end
    
    def attributes=(values)
      if values
        values.each_pair do |k, v|
          setter = "#{k}="
          send(setter, v) if respond_to?(setter)
        end
      end
    end
    
    # Shortcut for setting log levels. (:debug, :info, :warn, :error, :fatal)
    def level=(level_given)
      level_chosen = case level_given
      when :debug, DEBUG, ::StdLogger::DEBUG, :DEBUG
        Java::org.apache.log4j.Level::DEBUG
      when :info, INFO, ::StdLogger::INFO, :INFO
        Java::org.apache.log4j.Level::INFO
      when :warn, WARN, ::StdLogger::WARN, :WARN
        Java::org.apache.log4j.Level::WARN
      when :error, ERROR, ::StdLogger::ERROR, :ERROR
        Java::org.apache.log4j.Level::ERROR
      when :fatal, FATAL, ::StdLogger::FATAL, :FATAL
        Java::org.apache.log4j.Level::FATAL
      when :unknown, UNKNOWN, ::StdLogger::UNKNOWN, :UNKNOWN
        Java::org.apache.log4j.Level::ALL
      else
        raise NotImplementedError
      end
      @logger.setLevel level_chosen
    end

    def level
      level_chosen = @logger.effectiveLevel
      case level_chosen
      when Java::org.apache.log4j.Level::DEBUG
        DEBUG
      when Java::org.apache.log4j.Level::INFO
        INFO
      when Java::org.apache.log4j.Level::WARN
        WARN
      when Java::org.apache.log4j.Level::ERROR
        ERROR
      when Java::org.apache.log4j.Level::FATAL
        FATAL
      when Java::org.apache.log4j.Level::ALL
        UNKNOWN
      else
        raise NotImplementedError
      end
    end
    
    def flush
      #rails compatability
    end

    def debug(object = nil, &block)
      if debug?
        send_to_log4j(:debug, object, nil, &block)
      end
    end

    def info(object = nil, &block)
      if info?
        send_to_log4j(:info, object, nil, &block)
      end
    end

    def warn(object = nil, &block)
      if warn?
        send_to_log4j(:warn, object, nil, &block)
      end
    end

    def error(object = nil, &block)
      send_to_log4j(:error, object, nil, &block)
    end

    def log_error(msg, error)
      send_to_log4j(:error, msg, error)
    end

    def fatal(object = nil, &block)
      send_to_log4j(:fatal, object, nil, &block)
    end

    def log_fatal(msg, error)
      send_to_log4j(:fatal, msg, error)
    end

    def unknown(object = nil, &block)
      send_to_log4j(:unknown, object, nil, &block)
    end

    def log_unknown(msg, error)
      send_to_log4j(:unknown, msg, error)
    end

    # return org.apache.log4j.Logger instance backing this Logger
    def log4j_logger
      @logger
    end
    
    def debug?
      @logger.isEnabledFor(Java::org.apache.log4j.Priority::DEBUG)
    end
    
    def info?
      @logger.isEnabledFor(Java::org.apache.log4j.Priority::INFO)
    end
    
    def warn?
      @logger.isEnabledFor(Java::org.apache.log4j.Priority::WARN)
    end
    
    def tracing?
      if tracing.nil?
        if parent == Logger.root
          Logger.root.tracing == true
        else 
         parent.tracing?
        end
      else
        tracing == true
      end
    end
    
    def parent
      logger_mapping[log4j_logger.parent] || Logger.root
    end
    
    def initialize(logger=nil, *values) # :nodoc:
      if logger && logger.class.to_s === 'Java::OrgApacheLog4j::Logger'
        @logger = logger
        Logger.logger_mapping[@logger] = self
      else
        unless logger
	  if STDOUT === logger
            name = 'STDOUT'
          end
	  if STDERR === logger
            name = 'STDERR'
          end
	  name = logger.to_s unless name
        else
          name = nil
        end
        name = name.nil? ? 'jruby' : "jruby.#{name.gsub('::', '.')}"
        @logger = Java::org.apache.log4j.Logger.getLogger(name)
        Logger.logger_mapping[@logger] = self
      end
    end
    
    private
    
    def logger_mapping
      Logger.logger_mapping
    end

    def with_context # :nodoc:
      file_line_method = tracing? ? parse_caller(caller(3).first) : BLANK_CALLER

      mdc.put("fileName", file_line_method[0])
      mdc.put("lineNumber", file_line_method[1])
      mdc.put("methodName", file_line_method[2].to_s)

      begin
        yield
      ensure
        mdc.remove("fileName")
        mdc.remove("lineNumber")
        mdc.remove("methodName")
      end
    end

    def send_to_log4j(level, object, error, &block)
      msg, throwable = Log4jArgs.convert(object, error, &block)
      with_context do
        @logger.send(level, msg, throwable)
      end
    end

    def parse_caller(at) # :nodoc:
      at.match(/^(.+?):(\d+)(?::in `(.*)')?/).captures
    end
    
    def mdc
      Java::org.apache.log4j.MDC 
    end
    
  end
end

include Log4jruby
