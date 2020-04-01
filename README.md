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

### For example:

>`cmd > courses`   
\#\# output here (courses that have some tasks unfinished)   
`cmd > set course [id]`  
course => \[course name\] (specify a course for further operations)   
`cmd > tasks`   
\#\# output here (display tasks of current course)   
`cmd > info task [id]`   
\#\# output here (detailed information for task)
