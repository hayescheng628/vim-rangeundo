let s:states={}

function! s:GetRange()
	return {
				\'firstline':line("'<"),
				\'lastline':line("'>")
				\}
endfunction

function! s:CompareState(state,cur_changenr,range)
	if !has_key(a:state,'cur_changenr')||!has_key(a:state,'range')
		return 0
	endif
	return a:state.cur_changenr==#a:cur_changenr&&
				\a:state.range.firstline==#a:range.firstline&&
				\a:state.range.lastline==#a:range.lastline
endfunction

function! s:GetState()
	let l:buf=bufnr('%')
	if !has_key(s:states,buf)
		let s:states[buf]={}
	endif
	let l:state=s:states[buf]
	let l:cur_changenr=changenr()
	let l:range=s:GetRange()
	if !s:CompareState(l:state,l:cur_changenr,l:range)
		let l:state.cur_changenr=l:cur_changenr
		let l:state.range=l:range
		let l:state.changenr=l:cur_changenr
		let l:state.offset=0
	endif
	return l:state
endfunction

function! s:Undo(n)
	execute 'silent undo '.a:n
endfunction

function! s:LinesDiff(prev_lines,cur_lines)
	let l:firstline=1
	let l:lastline=len(a:prev_lines)
	let l:new_lastline=len(a:cur_lines)
	while l:lastline>0&&l:new_lastline>0&&a:prev_lines[l:lastline-1]==#a:cur_lines[l:new_lastline-1]
		let l:lastline-=1
		let l:new_lastline-=1
	endwhile
	while l:firstline<=l:lastline&&l:firstline<=l:new_lastline&&a:prev_lines[l:firstline-1]==#a:cur_lines[l:firstline-1]
		let l:firstline+=1
	endwhile
	return {
				\'firstline':l:firstline,
				\'lastline':l:lastline,
				\'new_lastline':l:new_lastline
				\}
endfunction

function! s:SetLines(start,end,replacement)
	let l:new_len=len(a:replacement)
	let l:old_len=a:end-a:start+1
	if l:new_len<l:old_len
		execute 'silent '.a:start.','.(a:start+l:old_len-l:new_len-1).'delete _'
	elseif l:new_len>l:old_len
		call append(a:end,a:replacement[l:old_len :])
	endif
	call setline(a:start,a:replacement)
endfunction

function! s:RangeUndo()
	let l:state=s:GetState()
	call s:Undo(l:state.changenr)
	let l:undotree=undotree()
	let l:cur_lines=[]
	let l:prev_lines=getline(1,'$')
	let l:undo_count=0
	while l:undotree.seq_cur>=l:undotree.entries[0].seq
		let l:undo_count+=1
		if exists('g:rangeundo_max_undo')&&l:undo_count>g:rangeundo_max_undo
			break
		endif
		silent undo
		let l:cur_lines=l:prev_lines
		let l:prev_lines=getline(1,'$')
		let l:diff=s:LinesDiff(l:prev_lines,l:cur_lines)
		if l:diff.new_lastline<l:state.range.firstline+l:state.offset
			let l:state.offset+=l:diff.lastline-l:diff.new_lastline
		elseif l:diff.firstline>l:state.range.lastline+l:state.offset
		elseif l:state.range.firstline+l:state.offset<=l:diff.firstline&&l:diff.new_lastline<=l:state.range.lastline+l:state.offset
			let l:state.changenr=changenr()
			call s:Undo(l:state.cur_changenr)
			call s:SetLines(
						\l:diff.firstline-l:state.offset,
						\l:diff.new_lastline-l:state.offset,
						\(['']+l:prev_lines)[l:diff.firstline : l:diff.lastline]
						\)
			normal! gv
			let l:state.cur_changenr=changenr()
			let l:state.range=s:GetRange()
			return
		else
			break
		end
		let l:undotree=undotree()
	endwhile
	call s:Undo(l:state.cur_changenr)
	normal! gv
	echom 'Already at oldest change'
endfunction

if has('nvim-0.2.1')&&!exists('g:rangeundo_use_vimscript')
	function! rangeundo#rangeundo()
		lua require('rangeundo').rangeundo()
	endfunction
else
	function! rangeundo#rangeundo()
		call s:RangeUndo()
	endfunction
endif
