#!/usr/bin/python

# Todo: shoul be '\hbox ... too wide.' (add '\hbox to the message).


# Author: Marcin Szamotulski
# http://atp-vim.sourceforge.net
#
# Copyright Statement: 
#     This file is a part of Automatic Tex Plugin for Vim.
#
#     Automatic Tex Plugin for Vim is free software: you can redistribute it
#     and/or modify it under the terms of the GNU General Public License as
#     published by the Free Software Foundation, either version 3 of the
#     License, or (at your option) any later version.
# 
#     Automatic Tex Plugin for Vim is distributed in the hope that it will be
#     useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#     General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License along
#     with Automatic Tex Plugin for Vim.  If not, see <http://www.gnu.org/licenses/>.

# Info: this is a python script which reads latex log fiele (which path is gven
# as the only argument) and it writes back a log messages which are in the
# following format:
# WARNING_TYPE::FILE::INPUT_LINE::INPUT_COL::MESSAGE (ADDITIONAL_INFO)
# this was intendent to be used for vim quick fix:
# set errorformat=LaTeX\ %tarning::%f::%l::%c::%m,Citation\ %tarning::%f::%l::%c::%m,Reference\ %tarning::%f::%l::%c::%m,Package\ %tarning::%f::%l::%c::%m,Overfull\ %tarning::%f::%l::%c::%m,LaTeX\ %tnfo::%f::%l::%c::%m,LaTeX\ %trror::%f::%l::%c::%m
# The fowllowing WARNING_TYPEs are available:
# LaTeX Warning
# Citation Warning
# Reference Warning
# Package Warning
# Overfull Warning
# LaTeX Font Warning
# LaTeX Font Info
# LaTeX Info
# LaTeX Error
# Input File
# Input Package                 : includes packges and document class

# Note: when FILE,INPUT_LINE,INPUT_COL doesn't exists 0 is put.
# for Input Package FILE is 0.


# It will work well when the tex file was compiled with a big value of 
# max_print_line (for example with `max_print_line=2000 latex file.tex')
# so that latex messages are not broken into lines.

import sys, re, os, os.path, fnmatch

def shift_dict( dictionary, nr ):
# add nr to every value of dictionary

    for key in dictionary.keys():
        dictionary[key]+=nr
    return dictionary

def rewrite_log(input_fname, output_fname=None, check_path=False, project_dir="", project_tmpdir=""):
# this function rewrites LaTeX log file (input_fname) to output_fname,
# changeing its format to something readable by Vim.
# check_path -- ATP process files in tmp directories, with this option the
# files under project_tmpdir will be written using project_dir
# (this is for the aux file)

    if output_fname == None:
        output_fname = os.path.splitext(input_fname)[0]+"._log"

    try:
        log_file = open(input_fname, 'r')
    except IOError:
        sys.exit(1)
    log_stream = log_file.read()
    log_file.close()

    dir = os.path.dirname(os.path.abspath(input_fname))
    os.chdir(dir)

    # Filter the log_stream: remoove all unbalanced brackets (:)
    # some times the log file contains unbalanced brackets!
    # This removes all the lines after 'Overfull \hbox' message until first non
    # empty line.
    log_lines = log_stream.split("\n")
    output_lines = []
    idx = 0
    remove = False
    for line in log_lines:
        idx+=1
        match = re.match('^Overfull \\\\hbox ',line)
        if match:
            remove = True
        elif re.match('^\s*$', line):
            remove = False
        if not remove or match:
            output_lines.append(line)
    log_stream='\n'.join(output_lines)
    output_lines = []
    log_lines = log_stream.split("\n")
    log=open("/tmp/log", 'w')
    log.write(log_stream)
    log.close()

    log_file.close()

    # File stack
    file_stack = []

    line_nr = 1
    col_nr = 1

    # Message Patterns:
    latex_warning_pat = re.compile('(LaTeX Warning: )')
    latex_warning= "LaTeX Warning"

    font_warning_pat = re.compile('LaTeX Font Warning: ')
    font_warning = "LaTeX Font Warning"

    font_info_pat = re.compile('LaTeX Font Info: ')
    font_info = "LaTeX Font Info"

    package_warning_pat = re.compile('Package (\w+) Warning: ')
    package_warning = "Package Warning"

    package_info_pat = re.compile('Package (\w+) Info: ')
    package_info = "Package Info"

    hbox_info_pat = re.compile('Overfull \\\\hbox')
    hbox_info = "Overfull Warning"

    latex_info_pat = re.compile('LaTeX Info: ')
    latex_info = "LaTeX Info"

    latex_emergency_stop_pat = re.compile('\! Emergency stop\.')
    latex_emergency_stop = "LaTeX Error"

    latex_error_pat = re.compile('\! (?:LaTeX Error: |Package (\w+) Error: )?')
    latex_error = "LaTeX Error"

    input_package_pat = re.compile('(?:Package: |Document Class: )')
    input_package = 'Input Package'

    open_dict = {}
    # This dictionary is of the form:
    # { file_name : number_of_brackets_opened_after_the_file_name_was_found ... }

    idx=-1
    for char in log_stream:
        idx+=1
        if char == "\n":
            line_nr+=1
            col_nr=0
        else:
            col_nr+=1
        if char == "(":
            # If we are at the '(' bracket, check for the file name just after it.
            line = log_lines[line_nr-1][col_nr:]
            fname_re = re.match('([^\(\)]*\.(?:tex|sty|cls|cfg|def|aux|fd|out|bbl|blg|bcf|lof|toc|lot|ind|idx|thm|synctex\.gz|pdfsync|clo|lbx|mkii|run\.xml|spl|snm|nav|brf|mpx|ilg|maf|glo|mtc[0-9]+))', line)
            if fname_re:
                fname = os.path.abspath(fname_re.group(1))
                output_lines.append("Input File::"+fname+"::0::0::Input File")
                file_stack.append(fname)
                open_dict[fname]=0
            open_dict = shift_dict(open_dict, 1)
        elif char == ")":
            if len(file_stack) and not( re.match('\!', log_lines[line_nr-1]) or re.match('\s{5,}',log_lines[line_nr-1]) or re.match('l\.\d+', log_lines[line_nr-1])):
            # If the ')' is in line that we check, then substrackt 1 from values of
            # open_dict and pop both the open_dict and the file_stack. 
                open_dict = shift_dict(open_dict, -1)
                if open_dict[file_stack[-1]] == 0:
                    open_dict.pop(file_stack[-1])
                    file_stack.pop()

        line = log_lines[line_nr-1][col_nr:]
        if col_nr == 0:
            # Check for the error message in the current line 
            # (that's why we only check it when col_nr == 0)
            try:
                last_file = file_stack[-1]
            except IndexError:
                last_file = "0"
            if check_path and fnmatch.fnmatch(last_file, project_tmpdir+"*"):
                last_file = os.path.normpath(os.path.join(project_dir, os.path.relpath(last_file, project_tmpdir)))
            if re.match(latex_warning_pat, line):
                # Log Message: 'LaTeX Warning: '
                input_line = re.search('on input line (\d+)', line)
                warning_type = re.match('LaTeX Warning: (Citation|Reference)', line)
                if warning_type:
                    wtype = warning_type.group(1)
                else:
                    wtype = ""
                msg = re.sub('\s+on input line (\d+)', '', re.sub(latex_warning_pat,'', line))
                if msg == "":
                    msg = " "
                if input_line:
                    output_lines.append(wtype+" "+latex_warning+"::"+last_file+"::"+input_line.group(1)+"::0::"+msg)
                else:
                    output_lines.append(latex_warning+"::"+last_file+"::0::0::"+msg)
            elif re.match(font_warning_pat, line):
                # Log Message: 'LaTeX Font Warning: '
                input_line = re.search('on input line (\d+)', line)
                if not input_line and line_nr < len(log_lines) and re.match('\(Font\)', log_lines[line_nr]):
                    input_line = re.search('on input line (\d+)', line)
                if not input_line and line_nr+1 < len(log_lines) and re.match('\(Font\)', log_lines[line_nr+1]):
                    input_line = re.search('on input line (\d+)', log_lines[line_nr+1])
                msg = re.sub(' on input line \d+', '', re.sub(font_warning_pat,'', line))
                if msg == "":
                    msg = " "
                i=0
                while line_nr+i < len(log_lines) and re.match('\(Font\)', log_lines[line_nr+i]):
                    msg += re.sub(' on input line \d+', '', re.sub('\(Font\)\s*', ' ', log_lines[line_nr]))
                    i+=1
                if not re.search("\.\s*$", msg):
                    msg = re.sub("\s*$", ".", msg)
                if input_line:
                    output_lines.append(font_warning+"::"+last_file+"::"+input_line.group(1)+"::0::"+msg)
                else:
                    output_lines.append(font_warning+"::"+last_file+"::0::0::"+msg)
            elif re.match(font_info_pat, line):
                # Log Message: 'LaTeX Font Info: '
                input_line = re.search('on input line (\d+)', line)
                if not input_line and line_nr < len(log_lines) and re.match('\(Font\)', log_lines[line_nr]):
                    input_line = re.search('on input line (\d+)', log_lines[line_nr])
                if not input_line and line_nr+1 < len(log_lines) and re.match('\(Font\)', log_lines[line_nr+1]):
                    input_line = re.search('on input line (\d+)', log_lines[line_nr+1])
                msg = re.sub(' on input line \d+', '', re.sub(font_info_pat,'', line))
                if msg == "":
                    msg = " "
                i=0
                while line_nr+i < len(log_lines) and re.match('\(Font\)', log_lines[line_nr+i]):
                    msg += re.sub(' on input line \d+', '', re.sub('\(Font\)\s*', ' ', log_lines[line_nr]))
                    i+=1
                if not re.search("\.\s*$", msg):
                    msg = re.sub("\s*$", ".", msg)
                if input_line:
                    output_lines.append(font_info+"::"+last_file+"::"+input_line.group(1)+"::0::"+msg)
                else:
                    output_lines.append(font_info+"::"+last_file+"::0::0::"+msg)
            elif re.match(package_warning_pat, line):
                # Log Message: 'Package (\w+) Warning: '
                package = re.match(package_warning_pat, line).group(1)
                input_line = re.search('on input line (\d+)', line)
                msg = re.sub(package_warning_pat,'', line)
                if line_nr < len(log_lines):
                    nline = log_lines[line_nr]
                    i=0
                    while re.match('\('+package+'\)',nline):
                        msg+=re.sub('\('+package+'\)\s*', ' ', nline)
                        if not input_line:
                            input_line = re.search('on input line (\d+)', nline)
                        i+=1
                        if line_nr+i < len(log_lines):
                            nline = log_lines[line_nr+i]
                        else:
                            break
                if msg == "":
                    msg = " "
                msg = re.sub(' on input line \d+', '', msg)
                if input_line:
                    output_lines.append(package_warning+"::"+last_file+"::"+input_line.group(1)+"::0::"+msg+" ("+package+")")
                else:
                    output_lines.append(package_warning+"::"+last_file+"::0::0::"+msg+" ("+package+")")
            elif re.match(package_info_pat, line):
                # Log Message: 'Package (\w+) Info: '
                package = re.match(package_info_pat, line).group(1)
                input_line = re.search('on input line (\d+)', line)
                msg = re.sub(package_info_pat,'', line)
                if line_nr < len(log_lines):
                    nline = log_lines[line_nr]
                    i=0
                    while re.match('\('+package+'\)',nline):
                        msg+=re.sub('\('+package+'\)\s*', ' ', nline)
                        if not input_line:
                            input_line = re.search('on input line (\d+)', nline)
                        i+=1
                        if line_nr+i < len(log_lines):
                            nline = log_lines[line_nr+i]
                        else:
                            break
                if msg == "":
                    msg = " "
                msg = re.sub(' on input line \d+', '', msg)
                if input_line:
                    output_lines.append(package_info+"::"+last_file+"::"+input_line.group(1)+"::0::"+msg+" ("+package+")")
                else:
                    output_lines.append(package_info+"::"+last_file+"::0::0::"+msg+" ("+package+")")
            elif re.match(hbox_info_pat, line):
                # Log Message: 'Overfull \\\\hbox'
                input_line = re.search('at lines (\d+)--(\d+)', line)
                msg = '\\hbox '+re.search('\((.*)\)', str(re.sub(hbox_info_pat,'', line))).group(1)
                if msg == "":
                    msg = " "
                if input_line:
                    output_lines.append(hbox_info+"::"+last_file+"::"+input_line.group(1)+"::0::"+msg)
                else:
                    output_lines.append(hbox_info+"::"+last_file+"::0::"+msg)
            elif re.match(latex_info_pat, line):
                # Log Message: 'LaTeX Info: '
                input_line = re.search('on input line (\d+)', line)
                msg = re.sub(' on input line \d+', '', re.sub(latex_info_pat,'', line))
                if msg == "":
                    msg = " "
                if input_line:
                    output_lines.append(latex_info+"::"+last_file+"::"+input_line.group(1)+"::0::"+msg)
                else:
                    output_lines.append(latex_info+"::"+last_file+"::0::0::"+msg)
            elif re.match(input_package_pat, line):
                # Log Message: 'Package: ', 'Document Class: '
                msg = re.sub(input_package_pat, '', line)
                if msg == "":
                    msg = " "
                output_lines.append(input_package+"::"+last_file+"::0::0::"+msg)
            elif re.match(latex_emergency_stop_pat, line):
                # Log Message: '! Emergency stop.'
                msg = "Emergency stop."
                nline = log_lines[line_nr]
                match = re.match('<\*>\s+(.*)', nline)
                if match:
                    e_file = match.group(1)
                else:
                    e_file = "0"
                i=-1
                while True:
                    i+=1
                    try:
                        nline = log_lines[line_nr-1+i]
                        line_m = re.match('\*\*\*\s+(.*)', nline)
                        if line_m:
                            rest = line_m.group(1)
                            break
                        elif i>50:
                            rest = ""
                            break
                    except IndexError:
                        rest = ""
                        break
                msg += " "+rest
                output_lines.append(latex_emergency_stop+"::"+e_file+"::0::0::"+msg)
            elif re.match(latex_error_pat, line):
                # Log Message: '\! (?:LaTeX Error: |Package (\w+) Error: )?'
                # get the line unmber of the error
                i=-1
                while True:
                    i+=1
                    try:
                        nline = log_lines[line_nr-1+i]
                        line_m = re.match('l\.(\d+) (.*)', nline)
                        if line_m:
                            input_line = line_m.group(1)
                            rest = line_m.group(2)+re.sub('^\s*', ' ', log_lines[line_nr+i])
                            break
                        elif i>50:
                            input_line="0"
                            rest = ""
                            break
                    except IndexError:
                        input_line="0"
                        rest = ""
                        break
                msg = re.sub(latex_error_pat, '', line)
                if msg == "":
                    msg = " "
                match = re.match('! Package (\w+) Error', line)
                if match:
                    info = match.group(1)
                elif rest:
                    info = rest
                else:
                    info = ""
                if re.match('\s*\\\\]\s*', info) or re.match('\s*$', info):
                    info = ""
                if info != "":
                    info = " |"+info
                verbose_msg = ""
                for j in range(1,i):
                    if not re.match("See\s+the\s+\w+\s+manual\s+or\s+\w+\s+Companion\s+for\s+explanation\.|Type\s+[HI]", log_lines[line_nr-1+j]):
                        verbose_msg+=re.sub("^\s*", " ", log_lines[line_nr-1+j])
                    else:
                        break
                if re.match('\s*<(?:inserted text|to be read again|recently read)>', verbose_msg) or \
                        re.match('\s*See the LaTeX manual', verbose_msg):
                    verbose_msg = ""
                if not re.match('\s*$',verbose_msg):
                    verbose_msg = " |"+verbose_msg

                if last_file == "0":
                    i=-1
                    while True:
                        i+=1
                        try:
                            nline = log_lines[line_nr-1+i]
                            line_m = re.match('<\*>\s+(.*)', nline)
                            if line_m:
                                e_file = line_m.group(1)
                                break
                            elif i>50:
                                e_file="0"
                                break
                        except IndexError:
                            e_file="0"
                            break
                else:
                    e_file = last_file
                output_lines.append(latex_error+"::"+e_file+"::"+input_line+"::0::"+msg+info+verbose_msg)


    output=open(output_fname, 'w')
    output.write('\n'.join(output_lines)+'\n')
    output.close()


# Main call
if __name__ == '__main__':
    try:
        rewrite_log(sys.argv[1])
    except IOError:
        pass
