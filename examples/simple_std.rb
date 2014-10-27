require File.dirname(__FILE__) + '/setup'

require 'logger'

logger = Logger.new(STDOUT)
logger2 = Logger.new('file.txt')

logger.level= Logger::DEBUG

logger.debug("Created logger")
logger.info("Program started")
logger.warn("Nothing to do!")

logger2.error("My God.")
x = [2, 3, 4]
logger2.fatal("My God #{x.inspect} ")
