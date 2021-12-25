local util=require('rangeundo.util')
local fn=require('rangeundo.fn')

local states={}

local function get_range()
	return {
		firstline=fn.line("'<"),
		lastline=fn.line("'>")
	}
end

local function get_cur_range()
	vim.api.nvim_command('normal! gv')
	local first=fn.getpos("'<")
	local last=fn.getpos("'>")
	local curpos=fn.getpos('.')
	vim.api.nvim_command('execute "normal! \\<ESC>"')
	if fn.visualmode()=='V' then
		if curpos[2]~=last[2] then first=last end
	else
		if not util.table_equals(curpos,last) then first=last end
	end
	return {
		first=first,
		last=curpos
	}
end

local function restore_cur_range(cur_range,offset)
	local new_cur_range=get_cur_range()
	local first=util.table_copy(cur_range.first)
	local last=util.table_copy(cur_range.last)
	if last[2]>=first[2] then
		last[2]=last[2]+offset
		if last[2]<first[2] then
			return {
				first=0,
				last=0
			}
		end
	else
		first[2]=first[2]+offset
		if first[2]<last[2] then
			return {
				first=0,
				last=0
			}
		end
	end
	if new_cur_range.first[2]~=first[2] then
		fn.setpos("'<",first)
	end
	if new_cur_range.last[2]~=last[2] then
		fn.setpos("'>",last)
	end
	vim.api.nvim_command('normal! gv')
	return get_range()
end

local function compare_state(state,cur_changenr,range)
	if not state.cur_changenr or not state.range then return false end
	return (
		state.cur_changenr==cur_changenr and
		state.range.firstline==range.firstline and 
		state.range.lastline==range.lastline
	)
end

local function get_state()
	local buf=fn.bufnr('%')
	if not states[buf] then states[buf]={} end
	local state=states[buf]
	local cur_changenr=fn.changenr()
	local range=get_range()
	if not compare_state(state,cur_changenr,range) then
		state.cur_changenr=cur_changenr
		state.range=range
		state.changenr=cur_changenr
		state.offset=0
	end
	return state
end

local function undo(n)
	if n then vim.api.nvim_command('silent undo '..n)
	else vim.api.nvim_command('silent undo') end
end

local function lines_diff(prev_lines,cur_lines)
	local firstline=1
	local lastline=#prev_lines
	local new_lastline=#cur_lines
	while lastline>0 and new_lastline>0 and prev_lines[lastline]==cur_lines[new_lastline] do
		lastline=lastline-1
		new_lastline=new_lastline-1
	end
	while firstline<=lastline and firstline<=new_lastline and prev_lines[firstline]==cur_lines[firstline] do
		firstline=firstline+1
	end
	return {
		firstline=firstline,
		lastline=lastline,
		new_lastline=new_lastline
	}
end

local function rangeundo()
	local cur_range=get_cur_range()
	local state=get_state()
	undo(state.changenr)
	local undotree=fn.undotree()
	local cur_lines={}
	local prev_lines=vim.api.nvim_buf_get_lines(0,0,-1,true)
	local undo_count=0
	while #undotree.entries>0 and undotree.seq_cur>=undotree.entries[1].seq do
		undo_count=undo_count+1
		if vim.g.rangeundo_max_undo and undo_count>vim.g.rangeundo_max_undo then break end
		undo()
		cur_lines=prev_lines
		prev_lines=vim.api.nvim_buf_get_lines(0,0,-1,true)
		local diff=lines_diff(prev_lines,cur_lines)
		if diff.new_lastline<state.range.firstline+state.offset then
			state.offset=state.offset+diff.lastline-diff.new_lastline
		elseif diff.firstline>state.range.lastline+state.offset then
		elseif state.range.firstline+state.offset<=diff.firstline and diff.new_lastline<=state.range.lastline+state.offset then
			state.changenr=fn.changenr()
			undo(state.cur_changenr)
			vim.api.nvim_buf_set_lines(0,
				diff.firstline-state.offset-1,
				diff.new_lastline-state.offset,
				true,
				util.list_slice(prev_lines,diff.firstline,diff.lastline))
			state.cur_changenr=fn.changenr()
			state.range=restore_cur_range(cur_range,diff.lastline-diff.new_lastline)
			return
		else
			break
		end
		undotree=fn.undotree()
	end
	undo(state.cur_changenr)
	restore_cur_range(cur_range,0)
	print('Already at oldest change')
end

return {
	rangeundo=rangeundo
}
