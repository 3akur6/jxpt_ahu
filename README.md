***jxpt_ahu*** - A simple client for site [jxpt.ahu.edu.cn](http://jxpt.ahu.edu.cn)

## Feature

* interactive user interface
* command extendable
* output formed in table

## Usage

Login:   
`jxpt_ahu -u username -p password`

then you will see a `cmd >` prompt   
type `help` to access commands description

## Function

* list courses teacher assigned some tasks which haven't been finished
* get tasks in more detail, such as pubtime, deadline, submit link, attachment
* easily download attachments (just type get since you set task)
* have a glance at the announcement from teacher
* involve in course topics (only see teachers in fact >\_<|||)
* query online resources' visit times and learning time
* use `boost` to add some time to online resources (Tips: remember to give reasonable time)

### For example:

>`cmd > courses`   
\#\# output here (courses that have some unfinished tasks)   
`cmd > set course [id]`  
course => \[course name\] (specify a course for further operations)   
`cmd > tasks`   
\#\# output here (display tasks of current course)   
`cmd > info task [id]`   
\#\# output here (detailed information for task)
