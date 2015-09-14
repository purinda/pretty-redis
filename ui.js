/* global node */
'use strict';

var remote = require('remote');
var app = remote.require('app');
var browserWindow = remote.require('browser-window');
var currentWindow = remote.getCurrentWindow();

var Redis = require('ioredis');
var redis = new Redis({
    port: 6379,
    host: '10.11.0.4',
    family: 4,
    db: 0
});

redis.defineCommand('keysegments', {
    numberOfKeys: 0,
    lua: "\
        local matches = redis.call('KEYS', '*') \
        local words = {} \
        local unique_matches = {} \
        local index = 0 \
        \
        for _,key in ipairs(matches) do \
            local word = string.match(key, \"^%w+:%w+:(%w+)\") \
        if (word ~= nil) then \
        words[word] = true \
        end \
        end \
        \
        for k,_ in pairs(words) do \
            unique_matches[index] = k \
            index = index + 1 \
        end \
        \
        return unique_matches \
    "
});

redis.keys('*').then(function (result) {
    var keys = [];

    result.forEach(function(item, key) {
        keys.push(
            {
                id: key,
                value: item
            }
        );
    });

    return keys;
}).then(function(keys) {

    //webix.ui({
    //    rows:[
    //        {
    //            type:"header",
    //            template: 'Connected: 127.0.0.1'
    //        },
    //        {
    //            cols:[
    //                { view: "tree", data: keys, gravity:0.5, select:true },
    //                { view: "resizer" },
    //                { view: "datatable", autoConfig:true, data: [] }
    //            ]
    //        }
    //    ]
    //});

});