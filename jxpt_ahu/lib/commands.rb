require 'terminal-table'

require_relative '../module/jxpt_ahu'

include JxptAhu

def cmd_without_args(cmd, rest, &block)
  if rest.empty?
    tries = 0
    begin
      block.call
    rescue HTTPClient::ConnectTimeoutError
      sleep(2 ** tries)
      tries += 1
      retry
    end
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
    if args.length >= 2
      option, *value = args
      tries = 0
      begin
        block.call(option, value)
      rescue HTTPClient::ConnectTimeoutError
        sleep(2 ** tries)
        tries += 1
        retry
      end
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
      :course    => "Get present course assigned before",
      :courses   => "Show current user's courses",
      :exit      => "Exit the console",
      :get       => "get attachment included in specified task",
      :help      => "Help menu",
      :info      => "Display detailed infomation",
      :informs   => "Display the newest informs of present course",
      :quit      => "Alias for exit",
      :resources => "Show resources in given course",
      :set       => "Set a global variable to a value",
      :show      => "Alias for info",
      :task      => "Get present task",
      :tasks     => "Get tasks in present course",
      :user      => "Show current user"
    }
    info.each { |row| table << row }
    puts table
  end
end

def cmd_user(cmd, args)
  cmd_without_args(cmd, args) { print @space[:user].name, "\n" }
end

def cmd_course(cmd, args)
  cmd_without_args(cmd, args) do
    if @space.dig(@space[:user], :course)
      print "#{@space[@space[:user]][:course].name}\n"
    else
      MUST_SPECIFY.call("course")
    end
  end
end

def cmd_courses(cmd, args)
  cmd_without_args(cmd, args) do
    table = Terminal::Table.new title: "Courses", headings: %w(Id Name Tasks Resources)
    @space[:user].courses.map
                         .with_index { |x, idx| [idx, x.name, @space[:user].homework.include?(x) ? "✔" : "", x.resources? ? "✔" : ""] }
                         .inject([], :<<).each { |row| table << row }
    puts table
  end
end

def cmd_tasks(cmd, args)
  cmd_without_args(cmd, args) do
    if @space[@space[:user]].respond_to?(:has_key?) && @space[@space[:user]].has_key?(:course)
      table = Terminal::Table.new title: "Tasks", headings: %w(Id Name Deadline Finished)
      @space[@space[:user]][:course].tasks.map.with_index { |x, idx| [idx, x.title, x.deadline, x.finished?.to_s] }.inject([], :<<).each { |row| table << row }
      puts table
    else
      MUST_SPECIFY.call("course")
    end
  end
end

def cmd_task(cmd, args)
  cmd_without_args(cmd, args) do
    if @space[@space[@space[:user]][:course]].has_key? :task
      print "#{@space[@space[@space[:user]][:course]][:task].title}\n"
    else
      MUST_SPECIFY.call("task")
    end
  end
end

def cmd_informs(cmd, args)
  cmd_without_args(cmd, args) do
    @space[@space[:user]] = {} if !@space[@space[:user]].is_a? Hash
    if @space[@space[:user]].has_key? :course
      table = Terminal::Table.new title: "Informs", headings: %w(Id Name)
      @space[@space[:user]][:course].informs.map.with_index { |x, idx| [idx, x.title] }.inject([], :<<).each { |row| table << row }
      puts table
    else
      MUST_SPECIFY.call("course")
    end
  end
end

def cmd_set(cmd, args)
  cmd_with_args(cmd, args) do |option, value|
    case option
    when "course"   then set_course(value[0])
    when "task"     then set_task(value[0])
    when "payload"  then set_payload(value[0])
    when "payloads" then set_payloads(value)
    else UNKNOWN_OPTION.call(option)
    end
  end
end

def cmd_show(cmd, args)
  cmd_with_args(cmd, args) do |option, value|
    case option
    when "task" then show_task(value)
    when "inform" then show_inform(value)
    else UNKNOWN_OPTION.call(option)
    end
  end
end

def cmd_get(cmd, args)
  cmd_without_args(cmd, args) do
    begin
      if @space[@space[@space[:user]][:course]][:task].attachment != "无"
        file_name = @space[@space[@space[:user]][:course]][:task].attachment_name
        if !File.exist? file_name
          File.open(file_name, "w") { |f| f.puts @space[:user].clnt.get_content(@space[@space[@space[:user]][:course]][:task].attachment) }
          print "\033[35m#{file_name}\033[0m saved in \033[35m#{Dir.getwd}\033[0m\n"
        else
          print "\033[35m#{file_name}\033[0m already exist\n"
        end
      else
        print "\033[33m[!]\033[0m No attachment in this task\n"
      end
    rescue NoMethodError
      MUST_SPECIFY.call("task")
    end
  end
end

def cmd_boost(cmd, args)
  cmd_with_args(cmd, args) do |value, desert|
    if (value =~ /^(\d+)$/) == 0
      @space[@space[@space[:user]]][:course][:payload].boost(value.to_i)
      now = @space[@space[@space[:user]]][:course][:payload].time :sec
      before = now - value * 60
      puts "\033[32m[+]\033[0m from: #{before % 60} (sec: #{before}) to: #{now % 60} (sec: #{now})"
    end
  end
end

def cmd_resources(cmd, args)
  cmd_without_args(cmd, args) do
    if course = @space.dig(@space[:user], :course).dup
      table = Terminal::Table.new do |t|
        t.add_row ["Chapters", "Resources"]
        course.chapters.each do |c|
          t.add_row [
            "#{c.to_s}\n\n\n" + c.subtitles.inject("") { |smemo, s| smemo << "#{s.to_s}\n\n" + (s.sections.empty? ? "" : (s.sections.map(&:to_s).join("\n") + "\n\n")) },
            c.subtitles
             .inject("") { |smemo, s| smemo << (s.resources.empty? ? "" : "#{s.resources.map(&:to_s).join("\n")}\n") + 
                                               (s.sections.empty? ? "" : s.sections.inject("") { |scmemo, sc| scmemo << sc.resources.map(&:to_s).join("\n") + "\n" }) }
             .strip
          ]
        end
        t.style = { :all_separators => true }
      end
      puts table
    else
      MUST_SPECIFY.call("course")
    end
  end
end

def cmd_payloads(cmd, args)
  cmd_without_args(cmd, args) do
    @space[@space[:user]] ||= {}
    @space[@space[:user]][:cache] ||= {}
    cache_payloads = @space[@space[:user]][:cache][:payloads]
    if !cache_payloads.nil?
      puts cache_payloads
      return
    end
    if course = @space.dig(@space[:user], :course)
      table = Terminal::Table.new do |t|
        t.title = "Payloads"
        t.add_row %w(Id Name Visit\ Times Online\ Time)
        threads = []
        @space[course] ||= {}
        @space[course][:payloads] = []
        course.resources.select { |r| r.type == OnlinePreview }.each_with_index { |op, idx| threads << Thread.new { @space[course][:payloads][idx] = op.detail } }
        threads.each(&:join)
        @space[course][:payloads].each_with_index { |p, idx| t.add_row [idx, p.name, p.visit_times, p.time] }
      end
      @space[@space[:user]][:cache][:payloads] = table
      puts table
    else
      MUST_SPECIFY.call("course")
    end
  end
end

def cmd_payload(cmd, args)
  cmd_without_args(cmd, args) do
    if @space[@space[@space[:user]][:course]].has_key? :payload
      puts @space[@space[@space[:user]][:course]][:payload].name
    else
      MUST_SPECIFY.call("payload")
    end
  end
end

def set_course(value)
  if (value =~ /^(\d+)$/) == 0
    if @space[:user].courses.length > value.to_i
      @space[@space[:user]] = {} if !@space[@space[:user]].is_a? Hash
      @space[@space[:user]][:course] = @space[:user].courses[value.to_i]
      print "course => #{@space[@space[:user]][:course].name}\n"
    elsif @space[:user].courses.empty?
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
    if @space[@space[:user]][:course].respond_to? :tasks
      if @space[@space[:user]][:course].tasks.length > value.to_i
        @space[@space[@space[:user]][:course]] = {} if !@space[@space[@space[:user]][:course]].is_a? Hash
        @space[@space[@space[:user]][:course]][:task] = @space[@space[:user]][:course].tasks[value.to_i]
        print "task => #{@space[@space[@space[:user]][:course]][:task].title}\n"
      elsif @space[@space[:user]][:course].tasks.empty?
        EMPTY_SHOULD_EXEC.call("Task", "tasks")
      else
        VALUE_OUT_OF_RANGE.call
      end
    else
      MUST_SPECIFY.call("course")
    end
  else
    ONLY_NUMBER_ACCEPTABLE.call
  end
end

def set_payload(value)
  if (value =~ /^(\d+)$/) == 0
    if course = @space.dig(@space[:user], :course)
      if payloads = @space.dig(course, :payloads)
        if payloads.length > value.to_i
          payload = @space[@space[@space[:user]][:course]][:payload] = payloads[value.to_i]
          print "payload => #{payload.name}\n"
        else
          VALUE_OUT_OF_RANGE.call
        end
      else
        EMPTY_SHOULD_EXEC.call("Payload", "payloads")
      end
    else
      MUST_SPECIFY.call("course")
    end
  else
    ONLY_NUMBER_ACCEPTABLE.call
  end
end

def set_payloads(value)
  if value.all? { |x| (x =~ /^(\d+)$/) == 0 }
  end
end

def show_task(value)
  if (value =~ /^(\d+)$/) == 0
    if @space[@space[:user]][:course].respond_to? :tasks
      if @space[@space[:user]][:course].tasks.length > value.to_i
        task = @space[@space[:user]][:course].tasks[value.to_i]
        table = task.table
        puts table
      else
        VALUE_OUT_OF_RANGE.call
      end
    else
      EMPTY_SHOULD_EXEC.call("Task", "tasks")
    end
  else
    ONLY_NUMBER_ACCEPTABLE.call
  end
end

def show_inform(value)
  if (value =~ /^(\d+)$/) == 0
    if @space[@space[:user]][:course].respond_to? :informs
      if @space[@space[:user]][:course].informs.length > value.to_i
        @space[@space[@space[:user]][:course]] = {} if !@space[@space[@space[:user]][:course]].is_a? Hash
        if !@space[@space[@space[:user]][:course]].has_key? :informs
          @space[@space[@space[:user]][:course]][:informs] = []
          threads = []
          @space[@space[:user]][:course].informs.each_with_index do |i, idx|
            threads << Thread.new do
              @space[@space[@space[:user]][:course]][:informs][idx] = i.detail
            end
          end
          threads.each(&:join)
        end
        inform = @space[@space[@space[:user]][:course]][:informs][value.to_i]
        table = inform.table
        puts table
      else
        VALUE_OUT_OF_RANGE.call
      end
    else
      EMPTY_SHOULD_EXEC.call("Inform", "informs")
    end
  else
    ONLY_NUMBER_ACCEPTABLE.call
  end
end