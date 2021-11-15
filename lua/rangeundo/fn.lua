local util=require('rangeundo.util')

if vim.fn then return vim.fn end

return setmetatable({},{
	__index=function(tbl,key)
		tbl[key]=function(...)
			return vim.api.nvim_call_function(key,{...})
		end
		return tbl[key]
	end
})
