if exists("g:loaded_rangeundo")
	finish
end
let g:loaded_rangeundo=1

let s:save_cpo=&cpo
set cpo&vim

xnoremap <silent> <Plug>(rangeundo) :<C-U>call rangeundo#rangeundo()<CR>

let &cpo=s:save_cpo
unlet s:save_cpo
