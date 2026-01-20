-- Wally entrypoint: expose original Cut3r assets without restructuring upstream files.
local cut3r = require(script.Parent:FindFirstChild("Cut3r").Cut3rCode)

return cut3r
