local function slice(arr,first,last)
	local new_arr={}
	if first<1 then first=1 end
	if last>#arr then last=#arr end
	for i=first,last do
		new_arr[#new_arr+1]=arr[i]
	end
	return new_arr
end

return {
	slice=slice
}
