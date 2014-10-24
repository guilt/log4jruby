require 'java'

$CLASSPATH << File.dirname(__FILE__) + "/"
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require File.dirname(__FILE__) + '/../log4j/log4j-1.2.17.jar'
