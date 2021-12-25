local function list_slice(list,start,finish)
	local new_list={}
	if start<1 then start=1 end
	if finish>#list then finish=#list end
	for i=start,finish do
		new_list[#new_list+1]=list[i]
	end
	return new_list
end

local function table_copy(tbl)
	local new_tbl={}
	for key,value in pairs(tbl) do
		new_tbl[key]=value
	end
	return new_tbl
end

local function table_equals(tbl1,tbl2)
	for key,value in pairs(tbl1) do
		if tbl2[key]~=value then return false end
	end
	for key,value in pairs(tbl2) do
		if tbl1[key]~=value then return false end
	end
	return true
end

return {
	list_slice=list_slice,
	table_copy=table_copy,
	table_equals=table_equals
}
