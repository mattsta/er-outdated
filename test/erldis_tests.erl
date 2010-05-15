-module(erldis_tests).

-include_lib("eunit/include/eunit.hrl").
-include("erldis.hrl").

quit_test() ->
	{ok, Client} = erldis:connect("localhost", 6379),
	?assertEqual(shutdown, erldis:quit(Client)),
	false = is_process_alive(Client).

utils_test() ->
	?assertEqual(<<"1">>, erldis_binaries:to_binary(1)),
	?assertEqual(<<"atom">>, erldis_binaries:to_binary(atom)).

basic_test() ->
	{ok, Client} = erldis:connect("localhost", 6379),
	?assertEqual(ok, er:flushdb(Client)),

	?assertEqual(nil, erldis:get(Client, <<"pippo">>)),
	<<"OK">> = erldis:set(Client, <<"hello">>, <<"kitty!">>),
	?assertEqual(true, erldis:setnx(Client, <<"foo">>, <<"bar">>)),
	?assertNot(erldis:setnx(Client, <<"foo">>, <<"bar">>)),
	
	?assert(erldis:exists(Client, <<"hello">>)),
	?assert(erldis:exists(Client, <<"foo">>)),
	?assertEqual(<<"bar">>, erldis:get(Client, <<"foo">>)),
	?assertEqual([<<"kitty!">>, <<"bar">>], erldis:mget(Client, [<<"hello">>, <<"foo">>])),
	?assertEqual([<<"foo">>], erldis:keys(Client, <<"f*">>)),
	
	erldis:del(Client, <<"hello">>),
	erldis:del(Client, <<"foo">>),
	?assertNot(erldis:exists(Client, <<"hello">>)),
	?assertNot(erldis:exists(Client, <<"foo">>)),
	
	?assertEqual(shutdown, erldis:quit(Client)).

set_test() ->
	{ok, Client} = erldis:connect("localhost", 6379),
	?assertEqual(ok, er:flushdb(Client)),
	erldis:sadd(Client, <<"set">>, <<"toto">>),
	?assertEqual([<<"toto">>], erldis:smembers(Client, <<"set">>)),
	erldis:srem(Client, <<"set">>, <<"toto">>),
	?assertEqual([], erldis:smembers(Client, <<"set">>)),
	?assertEqual(shutdown, erldis:quit(Client)).

hash_test() ->
	{ok, Client} = erldis:connect(),
	?assertEqual(ok, er:flushdb(Client)),
	?assertEqual(1, erldis:hset(Client, <<"key">>, <<"field">>, <<"value">>)),
	?assertEqual(<<"OK">>, erldis:hmset(Client, <<"key2">>, [<<"field">>, <<"value2">>])),
	?assertEqual(<<"OK">>, erldis:hmset(Client, <<"key2">>, [<<"fieldM">>, <<"valueM">>, <<"fieldK">>, <<"valueK">>])),
	?assertEqual(<<"value">>, erldis:hget(Client, <<"key">>, <<"field">>)),
	?assertEqual(<<"value2">>, erldis:hget(Client, <<"key2">>, <<"field">>)),
	?assertEqual(<<"valueK">>, erldis:hget(Client, <<"key2">>, <<"fieldK">>)),
	?assertEqual(20, erldis:hincrby(Client, <<"increment-key">>, <<"by-20">>, 20)),
	?assertEqual(40, erldis:hincrby(Client, <<"increment-key">>, <<"by-20">>, 20)),
	?assertEqual(<<"40">>, erldis:hget(Client, <<"increment-key">>, <<"by-20">>)),
	?assertEqual(true, erldis:hdel(Client, <<"increment-key">>, <<"by-20">>)),
	?assertEqual(false, erldis:hdel(Client, <<"increment-key">>, <<"by-20">>)),
	?assertEqual(20, erldis:hincrby(Client, <<"increment-key">>, <<"by-20">>, 20)),
	?assertEqual(1, erldis:hlen(Client, <<"increment-key">>)),
	?assertEqual(1, erldis:hlen(Client, <<"key">>)),
	?assertEqual(true, erldis:hexists(Client, <<"key">>, <<"field">>)),
	?assertEqual(false, erldis:hexists(Client, <<"key">>, <<"non-field">>)),
	?assertEqual([<<"field">>], erldis:hkeys(Client, <<"key">>)),
	?assertEqual([<<"by-20">>], erldis:hkeys(Client, <<"increment-key">>)),
	?assertEqual([<<"by-20">>, <<"20">>], erldis:hgetall(Client, <<"increment-key">>)),
	?assertEqual([<<"field">>, <<"value">>], erldis:hgetall(Client, <<"key">>)).

list_test() ->
	{ok, Client} = erldis:connect("localhost", 6379),
	?assertEqual(ok, er:flushdb(Client)),
	
	?assertEqual([], erldis:lrange(Client, <<"foo">>, 1, 2)),
	erldis:rpush(Client, <<"a_list">>, <<"1">>),
	erldis:rpush(Client, <<"a_list">>, <<"2">>),
	erldis:rpush(Client, <<"a_list">>, <<"3">>),
	erldis:rpush(Client, <<"a_list">>, <<"1">>),
	?assertEqual(1, erldis:lrem(Client, <<"a_list">>, 1, <<"1">>)),
	?assertEqual([<<"2">>, <<"3">>, <<"1">>], erldis:lrange(Client, <<"a_list">>, 0, 2)),
	?assertEqual([<<"1">>, <<"2">>, <<"3">>], erldis:sort(Client, <<"a_list">>)),
	?assertEqual([<<"3">>, <<"2">>, <<"1">>], erldis:sort(Client, <<"a_list">>, <<"DESC">>)),
	?assertEqual([<<"1">>, <<"2">>], erldis:sort(Client, <<"a_list">>, <<"LIMIT 0 2 ASC">>)),
	
	?assertEqual(shutdown, erldis:quit(Client)).

zset_test() ->
	{ok, Client} = erldis:connect("localhost", 6379),
	?assertEqual(ok, er:flushdb(Client)),
	
	?assertEqual(0, erldis:zcard(Client, <<"foo">>)),
	?assertEqual([], erldis:zrange(Client, <<"foo">>, 0, 1)),
	?assertEqual(0, erldis:zscore(Client, <<"foo">>, <<"elem1">>)),
	
	?assertEqual(added, erldis:zadd(Client, <<"foo">>, 5, <<"elem1">>)),
	?assertEqual([<<"elem1">>], erldis:zrange(Client, <<"foo">>, 0, 1)),
	?assertEqual([<<"elem1">>], erldis:zrevrange(Client, <<"foo">>, 0, 1)),
	?assertEqual([{<<"elem1">>, 5}], erldis:zrange_withscores(Client, <<"foo">>, 0, 1)),
	?assertEqual([{<<"elem1">>, 5}], erldis:zrevrange_withscores(Client, <<"foo">>, 0, 1)),
	?assertEqual(updated, erldis:zadd(Client, <<"foo">>, 6, <<"elem1">>)),
	?assertEqual(1, erldis:zcard(Client, <<"foo">>)),
	?assertEqual(6, erldis:zscore(Client, <<"foo">>, <<"elem1">>)),
	?assertEqual(8, erldis:zincrby(Client, <<"foo">>, 2, <<"elem1">>)),
	% can use list keys & values too
	?assertEqual(added, erldis:zadd(Client, "foo", 15, "a-elem")),
	?assertEqual(2, erldis:zcard(Client, "foo")),
	?assertEqual(15, erldis:zscore(Client, "foo", "a-elem")),
	?assertEqual([<<"elem1">>, <<"a-elem">>], erldis:zrange(Client, "foo", 0, 20)),
	?assertEqual([<<"a-elem">>, <<"elem1">>], erldis:zrevrange(Client, "foo", 0, 20)),
	?assertEqual([{<<"a-elem">>, 15}, {<<"elem1">>, 8}], erldis:zrevrange_withscores(Client, "foo", 0, 20)),
	?assertEqual([{<<"elem1">>, 8}, {<<"a-elem">>, 15}], erldis:zrange_withscores(Client, "foo", 0, 20)),
	?assertEqual([<<"a-elem">>], erldis:zrangebyscore(Client, "foo", 15, 20)),
	?assertEqual([<<"a-elem">>], erldis:zrangebyscore(Client, "foo", 15, 20, 0, 1)),
	?assertEqual([<<"elem1">>, <<"a-elem">>], erldis:zrangebyscore(Client, "foo", 1, 20, 0, 20)),
	?assertEqual([<<"a-elem">>], erldis:zrangebyscore(Client, "foo", 1, 20, 1, 2)),
	?assertEqual([], erldis:zrangebyscore(Client, "foo", 1, 10, 2, 2)),
	?assertEqual(2, erldis:zremrangebyscore(Client, "foo", 1, 20)),
	?assertEqual(false, erldis:zrem(Client, "foo", "a-elem")),
	?assertEqual(0, erldis:zcard(Client, "foo")),
	?assertEqual([], erldis:zrevrange(Client, "foo", 0, 20)),
	
	?assertEqual(false, erldis:zrem(Client, <<"foo">>, <<"elem1">>)),
	?assertEqual(false, erldis:zrem(Client, <<"foo">>, <<"elem1">>)),
	?assertEqual(0, erldis:zcard(Client, <<"foo">>)),
	?assertEqual([], erldis:zrange(Client, <<"foo">>, 0, 2)),
	
	?assertEqual(shutdown, erldis:quit(Client)).

% inline_tests(Client) ->
%	  [?_assertMatch(ok, erldis:set(Client, <<"hello">>, <<"kitty!">>)),
%	   ?_assertMatch(false, erldis:setnx(Client, <<"hello">>, <<"kitty!">>)),
%	   ?_assertMatch(true, erldis:exists(Client, <<"hello">>)),
%	   ?_assertMatch(true, erldis:del(Client, <<"hello">>)),
%	   ?_assertMatch(false, erldis:exists(Client, <<"hello">>)),
%
%	   ?_assertMatch(true, erldis:setnx(Client, <<"hello">>, <<"kitty!">>)),
%	   ?_assertMatch(true, erldis:exists(Client, <<"hello">>)),
%	   ?_assertMatch("kitty!">>, erldis:get(Client, <<"hello">>)),
%	   ?_assertMatch(true, erldis:del(Client, <<"hello">>)),
%
%
%	   ?_assertMatch(1, erldis:incr(Client, <<"pippo">>))
%	   ,?_assertMatch(2, erldis:incr(Client, <<"pippo">>))
%	   ,?_assertMatch(1, erldis:decr(Client, <<"pippo">>))
%	   ,?_assertMatch(0, erldis:decr(Client, <<"pippo">>))
%	   ,?_assertMatch(-1, erldis:decr(Client, <<"pippo">>))
%
%	   ,?_assertMatch(6, erldis:incrby(Client, <<"pippo">>, 7))
%	   ,?_assertMatch(2, erldis:decrby(Client, <<"pippo">>, 4))
%	   ,?_assertMatch(-2, erldis:decrby(Client, <<"pippo">>, 4))
%	   ,?_assertMatch(true, erldis:del(Client, <<"pippo">>))
%	  ].
