require 'terminal-table'

TOO_MANY_ARGUMENT = Proc.new { print "\033[31m[-]\033[0m Too many arguments (expected 0)\n" }
UNKNOWN_COMMAND = Proc.new { |cmd| print "\033[31m[-]\033[0m Unknown command: #{cmd}\n\nType \033[34mhelp\033[0m to see commands acceptable\n\n" }
DID_YOU_MEAN = Proc.new { |cmd| print "Did you mean? \033[1m#{cmd}\033[0m\n"}
MUST_SPECIFY = Proc.new { |item| print "\033[33m[!]\033[0m You must specify a #{item}\n" }
USAGE_FOR_MULTI = Proc.new { |cmd| print "\nUsage: \033[34m#{cmd}\033[0m option value\n\n" }
UNKNOWN_OPTION = Proc.new { |option| print "\033[31m[-]\033[0m Unknown option: #{option}\n" }
VALUE_OUT_OF_RANGE = Proc.new { print "\033[31m[-]\033[0m Wrong assignment (value out of length)\n" }
EMPTY_SHOULD_EXEC = Proc.new { |arr, cmd| print "\033[33m[!]\033[0m #{arr} list empty\n"; print "\nYou should exec \033[34m#{cmd}\033[0m firstly\n\n" }
ONLY_NUMBER_ACCEPTABLE = Proc.new { print "\033[33m[!]\033[0m Only number larger than or equal to 0 acceptable\n" }

def cmd_without_args(cmd, rest, &block)
  if rest.empty?
    block.call
  elsif rest.start_with? " "
    TOO_MANY_ARGUMENT.call
  else
    UNKNOWN_COMMAND.call(cmd + rest)
    DID_YOU_MEAN.call(cmd)
  end
end

def cmd_with_args(cmd, rest, &block)
  if rest.empty?
    USAGE_FOR_MULTI.call(cmd)
  elsif rest.start_with? " "
    args = rest.split(" ")
    if args.length == 2
      option, value = args
      block.call(option, value)
    else
      USAGE_FOR_MULTI.call(cmd)
    end
  else
    UNKNOWN_COMMAND.call(cmd + rest)
    DID_YOU_MEAN.call(cmd)
  end
end

def cmd_exit(cmd, args)
  cmd_without_args(cmd, args) { exit }
end

def cmd_help(cmd, args)
  cmd_without_args(cmd,args) do
    table = Terminal::Table.new headings: %w(Command Description)
    info = {
      :course  => "Get present course assigned before",
      :courses => "Show current user's courses which have unfinished tasks",
      :exit    => "Exit the console",
      :get     => "get attachment included in specified task",
      :help    => "Help menu",
      :info    => "Display detailed infomation",
      :informs => "Display the newest informs of present course",
      :quit    => "Alias for exit",
      :set     => "Set a global variable to a value",
      :show    => "Alias for info",
      :task    => "Get present task",
      :tasks   => "Get tasks in present course",
      :user    => "Show current user"
    }
    info.inject([], :<<).each { |row| table << row }
    puts table
  end
end

def cmd_user(cmd, args)
  cmd_without_args(cmd, args) { print @user.name, "\n" }
end

def cmd_course(cmd, args)
  cmd_without_args(cmd, args) do
    if defined? @course
      print "#{@course.name}\n"
    else
      MUST_SPECIFY.call("course")
    end
  end
end

def cmd_courses(cmd, args)
  cmd_without_args(cmd, args) do
    recv = @user.courses.empty? ? @user.homework : @user.courses
    table = Terminal::Table.new title: "Courses", headings: %w(Id Name)
    recv.map.with_index { |x, idx| [idx, x.name] }.inject([], :<<).each { |row| table << row }
    puts table
  end
end

def cmd_tasks(cmd, args)
  cmd_without_args(cmd, args) do
    if defined? @course
      table = Terminal::Table.new title: "Tasks", headings: %w(Id Name Deadline Finished)
      @course.tasks.map.with_index { |x, idx| [idx, x.title, x.deadline, x.finished?.to_s] }.inject([], :<<).each { |row| table << row }
      puts table
    else
      MUST_SPECIFY.call("course")
    end
  end
end

def cmd_task(cmd, args)
  cmd_without_args(cmd, args) do
    if defined? @task
      print "#{@task.title}\n"
    else
      MUST_SPECIFY.call("task")
    end
  end
end

def cmd_informs(cmd, args)
  cmd_without_args(cmd, args) do
    if defined? @course
      table = Terminal::Table.new title: "Informs", headings: %w(Id Name)
      @course.informs.map.with_index { |x, idx| [idx, x.title] }.inject([], :<<).each { |row| table << row }
      puts table
    else
      MUST_SPECIFY.call("course")
    end
  end
end

def cmd_set(cmd, args)
  cmd_with_args(cmd, args) do |option, value|
    case option
    when "course" then set_course(value)
    when "task"   then set_task(value)
    else UNKNOWN_OPTION.call(option)
    end
  end
end

def cmd_show(cmd, args)
  cmd_with_args(cmd, args) do |option, value|
    case option
    when "task" then show_task(value)
    else UNKNOWN_OPTION.call(option)
    end
  end
end

def cmd_get(cmd, args)
  cmd_without_args(cmd, args) do
    if defined? @task
      if @task.attachment != "无"
        file_name = @task.attachment_name
        File.open(file_name, "w") { |f| f.puts @user.clnt.get_content(@task.attachment) }
        print "<#{file_name}> saved in \033[35m#{Dir.getwd}\033[0m\n"
      else
        print "\033[33m[!]\033[0m No attachment in this task\n"
      end
    else
      MUST_SPECIFY.call("task")
    end
  end
end

def set_course(value)
  if (value =~ /^(\d+)$/) == 0
    if @user.courses.length > value.to_i
      @course = @user.courses[value.to_i]
      print "course => #{@course.name}\n"
    elsif @user.courses.empty?
      EMPTY_SHOULD_EXEC.call("Course", "courses")
    else
      VALUE_OUT_OF_RANGE.call
    end
  else
    ONLY_NUMBER_ACCEPTABLE.call
  end
end

def set_task(value)
  if (value =~ /^(\d+)$/) == 0
    begin
      if @course.tasks.length > value.to_i
        @task = @course.tasks[value.to_i]
        print "task => #{@task.title}\n"
      elsif @course.tasks.empty?
        EMPTY_SHOULD_EXEC.call("Task", "tasks")
      else
        VALUE_OUT_OF_RANGE.call
      end
    rescue NoMethodError
      MUST_SPECIFY.call("course")
    end
  else
    ONLY_NUMBER_ACCEPTABLE.call
  end
end

def show_task(value)
  if (value =~ /^(\d+)$/) == 0
    begin
      if @course.tasks.length > value.to_i
        task = @course.tasks[value.to_i]
        table = Terminal::Table.new do |t|
          t.title = "Task"
          t.add_row ["标题", task.title]
          t.add_row ["链接", task.submit]
          t.add_row ["发布人", task.issuer]
          t.add_row ["发布时间", task.pubtime]
          t.add_row ["截止时间", task.deadline]
          t.add_row ["评分方式", task.judgement]
          t.add_row ["作业内容", task.content]
          t.add_row ["附件", task.attachment]
          t.style = { :all_separators => true }
        end
        puts table
      else
        VALUE_OUT_OF_RANGE.call
      end
    rescue NoMethodError
      EMPTY_SHOULD_EXEC.call("Task", "tasks")
    end
  else
    ONLY_NUMBER_ACCEPTABLE.call
  end
end