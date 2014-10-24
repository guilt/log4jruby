require File.dirname(__FILE__) + '/setup'

require 'logger'

logger = Logger.new(STDOUT, 2, 3)
logger.level= Logger::DEBUG

logger.debug("Created logger")
logger.info("Program started")
logger.warn("Nothing to do!")
