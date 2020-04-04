module JxptAhu
  TOO_MANY_ARGUMENT = Proc.new { print "\033[31m[-]\033[0m Too many arguments (expected 0)\n" }
  UNKNOWN_COMMAND = Proc.new { |cmd| print "\033[31m[-]\033[0m Unknown command: #{cmd}\n\nType \033[34mhelp\033[0m to see commands acceptable\n\n" }
  DID_YOU_MEAN = Proc.new { |cmd| print "Did you mean? \033[1m#{cmd}\033[0m\n"}
  MUST_SPECIFY = Proc.new { |item| print "\033[33m[!]\033[0m You must specify a #{item}\n" }
  USAGE_FOR_MULTI = Proc.new { |cmd| print "\nUsage: \033[34m#{cmd}\033[0m option value\n\n" }
  UNKNOWN_OPTION = Proc.new { |option| print "\033[31m[-]\033[0m Unknown option: #{option}\n" }
  VALUE_OUT_OF_RANGE = Proc.new { print "\033[31m[-]\033[0m Wrong assignment (value out of length)\n" }
  EMPTY_SHOULD_EXEC = Proc.new { |arr, cmd| print "\033[33m[!]\033[0m #{arr} list empty\n"; print "\nYou should exec \033[34m#{cmd}\033[0m firstly\n\n" }
  ONLY_NUMBER_ACCEPTABLE = Proc.new { print "\033[33m[!]\033[0m Only number larger than or equal to 0 acceptable\n" }
end