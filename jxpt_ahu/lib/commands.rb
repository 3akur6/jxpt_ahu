require 'terminal-table'

require_relative '../module/jxpt_ahu'

include JxptAhu

def cmd_exit(cmd, args)
  cmd_without_args(cmd, args) { exit }
end

def cmd_help(cmd, args)
  cmd_without_args(cmd,args) do
    table = Terminal::Table.new headings: %w(Command Description)
    info = {
      :boost     => "Add some time to online resources",
      :course    => "Get present course assigned before",
      :courses   => "Show current user's courses",
      :exit      => "Exit the console",
      :get       => "get attachment included in specified task",
      :help      => "Help menu",
      :info      => "Display detailed infomation",
      :informs   => "Display the newest informs of present course",
      :payload   => "Show current payload",
      :payloads  => "Query resources that support boost function",
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
    if @space.dig(@space[:user], :course)
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
    if @space.dig(@space[@space[:user]][:course], :task)
      print "#{@space[@space[@space[:user]][:course]][:task].title}\n"
    else
      MUST_SPECIFY.call("task")
    end
  end
end

def cmd_informs(cmd, args)
  cmd_without_args(cmd, args) do
    @space[@space[:user]] ||= {}
    if @space.dig(@space[:user], :course)
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
    when "course"   then set_course(value)
    when "task"     then set_task(value)
    when "payload"  then set_payload(value)
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
  cmd_with_args(cmd, args) do |value, _|
    if (value =~ /^(\d+)$/) == 0
      payload = [@space[@space[@space[:user]][:course]][:payload]].flatten
      threads = []
      payload.each do |x|
        threads << Thread.new do
          value.to_i.times { x.boost }
          now = x.time :sec
          before = now - value.to_i * 60
          puts "\033[32m[+]\033[0m from: #{before / 60} (sec: #{before}) to: #{now / 60} (sec: #{now})"
        end
      end
      threads.each(&:join)
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
    if course = @space.dig(@space[:user], :course)
      table = Terminal::Table.new do |t|
        t.title = "Payloads"
        t.add_row %w(Id Name Online\ Time)
        unless payloads = @space.dig(course, :payloads)
          threads = []
          @space[course] ||= {}
          @space[course][:payloads] = []
          course.resources.select { |r| r.type == OnlinePreview }.each_with_index do |op, idx|
            threads << Thread.new do
              tries = 0
              begin
                @space[course][:payloads][idx] = op.detail
              rescue RuntimeError
                sleep(2 ** tries)
                tries += 1
                retry
              end
            end
          end
          threads.each(&:join)
          payloads = @space.dig(course, :payloads)
        end
        payloads.each_with_index { |p, idx| t.add_row [idx, p.name, p.time] }
      end
      puts table
    else
      MUST_SPECIFY.call("course")
    end
  end
end

def cmd_payload(cmd, args)
  cmd_without_args(cmd, args) do
    if payload = @space.dig(@space[@space[:user]][:course], :payload)
      [payload].flatten.each { |x| puts x.name }
    else
      MUST_SPECIFY.call("payload")
    end
  end
end

def set_course(value)
  if (value =~ /^(\d+)$/) == 0
    if @space[:user].courses.length > value.to_i
      @space[@space[:user]] ||= {}
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
    if @space[@space[:user]].dig(:course).respond_to? :tasks
      if @space[@space[:user]][:course].tasks.length > value.to_i
        @space[@space[@space[:user]][:course]] ||= {}
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
  value = value.split(",").map(&:strip)
  if value.all? { |x| (x =~ /^(\*|\d+|\d+-\d+)$/) == 0 }
    if course = @space.dig(@space[:user], :course)
      if payloads = @space.dig(course, :payloads)
        if value.include? "*"
          @space[@space[@space[:user]][:course]][:payload] = payloads
          print "payloads => [all!]\n"
        else
          idx = value.map do |x|
            if x.include? "-"
              range = x.split("-").map(&:to_i)
              Range.new(*range).to_a
            else
              x.to_i
            end
          end.flatten.uniq
          accept = payloads.length
          if idx.all? { |x| x < accept }
            @space[@space[@space[:user]][:course]][:payload] = idx.inject([]) { |memo, v| memo << payloads[v] }
            print "payloads => #{idx.to_s}\n"
          else
            VALUE_OUT_OF_RANGE.call
          end
        end
      else
        EMPTY_SHOULD_EXEC.call("Payload", "payloads")
      end
    else
      MUST_SPECIFY.call("course")
    end
  else
    print "\033[33m[!]\033[0m Only numbers (>= 0) or ranges (like: 1-19) or * (select all) acceptable\n"
  end
end

def show_task(value)
  if (value =~ /^(\d+)$/) == 0
    @space[@space[:user]] ||= {}
    if @space[@space[:user]].dig(:course).respond_to? :tasks
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
    @space[@space[:user]] ||= {}
    if @space[@space[:user]].dig(:course).respond_to? :informs
      if @space[@space[:user]][:course].informs.length > value.to_i
        @space[@space[@space[:user]][:course]] ||= {}
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