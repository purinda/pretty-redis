-- Following lua script can be used for retrieving hierarchically constructed keys from Redis.
local pattern = 'doc:*';

-- Count the Nth tree-level within the data structure
local _, count = string.gsub(pattern, ':', ':')
local key_pattern = '^';

-- Build string matching pattern for branch nodes as per provided keys pattern
if (count == 0) then
    key_pattern = key_pattern .. '([%a%d_\-]+):.*'
elseif (count == 1) then
    key_pattern = key_pattern .. '[%a%d_\-]+:([%a%d_\-]+).*$'
else
    key_pattern = key_pattern .. string.rep('[%a%d_\-]+:', count)
    key_pattern = key_pattern .. '([%a%d_\-]+):.*$';
end

local matches = redis.call('KEYS', pattern)
local matching_keys = {}
local none_matching_keys = {}

for _, key in ipairs(matches) do
    local segment = string.match(key, key_pattern)
    local datatype = 'container';

    if (segment ~= nil) then

        -- Filter out unique key segment matches
        matching_keys[segment] = datatype
    else
        local unstructured_key = string.match(key, '^' .. string.gsub(pattern, '*', '.*'))
        datatype = redis.call('TYPE', key)

        -- Sort out the index for non-matching keys
        none_matching_keys[unstructured_key] = datatype
    end
end

local result = {}
local index = 1

-- Sort out the index for unique key segment matches
for k, v in pairs(matching_keys) do
    result[index] = {k, v}
    index = index + 1
end

-- Append unstructured keys
for k, v in pairs(none_matching_keys) do
    result[index] = {k, v}
    index = index + 1
end

return result
