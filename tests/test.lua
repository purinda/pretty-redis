-- Following lua script can be used for retrieving hierarchically constructed keys from Redis.
-- redis-cli "keys" "*" | grep -o -E "^[[:alpha:]]+:^C| sort | uniq

local pattern = 'srt:article-article:249:articles:*';

-- Count the Nth tree-level within the data structure
local _, count = string.gsub(pattern, ':', ':')
local key_pattern = '^';

-- Build string matching pattern for branch nodes as per provided keys pattern
if (count == 0) then
    key_pattern = key_pattern .. '(%w+):.*'
elseif (count == 1) then
    key_pattern = key_pattern .. '.*:(.+):.*$'
else
    key_pattern = key_pattern .. string.rep('[%a%d\-]+:', count)
    key_pattern = key_pattern .. '([%a%d\-]+).*$';
--    key_pattern = key_pattern .. string.gsub(pattern, ':*', ']:(.+)') .. '$'

    -- doc:article:* -> ^.+:.+:(.+)[:.*]?$
    -- srt:article-article:* -> ^[%a%d\-]+:[%a%d\-]+:([%a%d\-]+).*$

--    key_pattern = '^[%a%d\-]+:([%a%d\-]+).*$'
end

local matches = redis.call('KEYS', pattern)
local matching_keys = {}
local none_matching_keys = {}

for _, key in ipairs(matches) do
    local segment = string.match(key, key_pattern)
    local datatype = redis.call('TYPE', key)

    if (segment ~= nil) then
        -- Filter out unique key segment matches
        matching_keys[segment] = datatype
    else
        local unstructured_key = string.match(key, '^' .. string.gsub(pattern, '*', '.*'))

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
