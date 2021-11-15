local util=require('rangeundo.util')
local fn=require('rangeundo.fn')

local states={}

local function get_range()
	return {
		firstline=fn.line("'<"),
		lastline=fn.line("'>")
	}
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
	local state=get_state()
	undo(state.changenr)
	local undotree=fn.undotree()
	local cur_lines={}
	local prev_lines=vim.api.nvim_buf_get_lines(buf,0,-1,true)
	local undo_count=0
	while undotree.seq_cur>=undotree.entries[1].seq do
		undo_count=undo_count+1
		if vim.g.rangeundo_max_undo and undo_count>vim.g.rangeundo_max_undo then break end
		undo()
		cur_lines=prev_lines
		prev_lines=vim.api.nvim_buf_get_lines(buf,0,-1,true)
		local diff=lines_diff(prev_lines,cur_lines)
		if diff.new_lastline<state.range.firstline+state.offset then
			state.offset=state.offset+diff.lastline-diff.new_lastline
		elseif diff.firstline>state.range.lastline+state.offset then
		elseif state.range.firstline+state.offset<=diff.firstline and diff.new_lastline<=state.range.lastline+state.offset then
			state.changenr=fn.changenr()
			undo(state.cur_changenr)
			vim.api.nvim_buf_set_lines(buf,
				diff.firstline-state.offset-1,
				diff.new_lastline-state.offset,
				true,
				util.slice(prev_lines,diff.firstline,diff.lastline))
			vim.api.nvim_command('normal! gv')
			state.cur_changenr=fn.changenr()
			state.range=get_range()
			return
		else
			break
		end
		undotree=fn.undotree()
	end
	undo(state.cur_changenr)
	vim.api.nvim_command('normal! gv')
	print('Already at oldest change')
end

return {
	rangeundo=rangeundo
}
