require 'readline'
require 'optparse'

require_relative 'jxpt_ahu/lib/banner'
require_relative 'jxpt_ahu/lib/commands'
require_relative 'jxpt_ahu/models/user'

PROMPT = "\033[4mcmd\033[0m > "

options = {}
option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: jxpt.rb [options]"

  opts.on("-u", "--username USERNAME") { |username| options[:username] = username }
  opts.on("-p", "--password PASSWORD") { |password| options[:password] = password }
  opts.on("-h", "--help") { puts opts;exit }
end

option_parser.parse!

if options.length != 2
  puts option_parser
  exit
end

@user = User.new(options)

if @user.login
  print BANNER
  loop do
  	cmd = Readline.readline(PROMPT, true).strip
    case cmd
    when /^(help)(.*)$/      then cmd_help($1, $2)
    when /^(exit|quit)(.*)$/ then cmd_exit($1, $2)
    when /^(user)(.*)$/      then cmd_user($1, $2)
    when /^(courses)(.*)$/   then cmd_courses($1, $2)
    when /^(course)(.*)$/    then cmd_course($1, $2)
    when /^(informs)(.*)$/   then cmd_informs($1, $2)
    when /^(tasks)(.*)$/     then cmd_tasks($1, $2)
    when /^(task)(.*)$/      then cmd_task($1, $2)
    when /^(set)(.*)$/       then cmd_set($1, $2)
    when /^(show|info)(.*)$/ then cmd_show($1, $2)
    when /^(get)(.*)$/       then cmd_get($1, $2)
    else UNKNOWN_COMMAND.call(cmd)
    end
  end
end