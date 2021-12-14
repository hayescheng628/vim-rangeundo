local function slice(arr,first,last)
	local new_arr={}
	if first<1 then first=1 end
	if last>#arr then last=#arr end
	for i=first,last do
		new_arr[#new_arr+1]=arr[i]
	end
	return new_arr
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
	slice=slice,
	table_copy=table_copy,
	table_equals=table_equals
}
