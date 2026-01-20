-- Wally entrypoint: expose original Cut3r assets without restructuring upstream files.
local cut3r = script.Parent:FindFirstChild("Cut3r")
if not cut3r then
	error("Cut3r folder not found; package contents are incomplete.")
end

return cut3r
