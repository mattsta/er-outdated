-module(erldis).

-compile(export_all).

%%%%%%%%%%%%%%%%%%%%%%%
%% Client Connection %%
%%%%%%%%%%%%%%%%%%%%%%%

connect() -> erldis_client:connect().

connect(Host) -> erldis_client:connect(Host).

connect(Host, Port) -> erldis_client:connect(Host, Port).

connect(Host, Port, Options) -> erldis_client:connect(Host, Port, Options).

quit(Client) -> erldis_client:stop(Client).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Commands operating on every value %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

exists(Client, Key) -> tfstat(erldis_client:sr_scall(Client, [<<"exists">>, Key])).

del(Client, Key) -> erldis_client:sr_scall(Client, [<<"del">>, Key]).

type(Client, Key) -> erldis_client:sr_scall(Client, [<<"type">>, Key]).

keys(Client, Pattern) ->
	% TODO: tokenize the binary directly (if is faster)
	% NOTE: with binary-list conversion, timer:tc says 26000-30000 microseconds
	case erldis_client:scall(Client, [<<"keys">>, Pattern]) of
		[] -> [];
		[B] -> [list_to_binary(S) || S <- string:tokens(binary_to_list(B), " ")]
	end.

% TODO: test randomkey, rename, renamenx, dbsize, expire, ttl

randomkey(Client, Key) ->
	erldis_client:sr_scall(Client, [<<"randomkey">>, Key]).

rename(Client, OldKey, NewKey) ->
	erldis_client:sr_scall(Client, [<<"rename">>, OldKey, NewKey]).

renamenx(Client, OldKey, NewKey) ->
	erldis_client:sr_scall(Client, [<<"renamenx">>, OldKey, NewKey]).

dbsize(Client) -> numeric(erldis_client:sr_scall(Client, [<<"dbsize">>])).

expire(Client, Key, Seconds) ->
	erldis_client:sr_scall(Client, [<<"expire">>, Key, Seconds]).

ttl(Client, Key) -> erldis_client:sr_scall(Client, [<<"ttl">>, Key]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Commands operating on string values %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set(Client, Key, Value) ->
	erldis_client:sr_scall(Client, [<<"set">>, Key, Value]).

get(Client, Key) -> erldis_client:sr_scall(Client, [<<"get">>, Key]).

getset(Client, Key, Value) ->
	erldis_client:sr_scall(Client, [<<"getset">>, Key, Value]).

mget(Client, Keys) -> erldis_client:scall(Client, [<<"mget">> | Keys]).

setnx(Client, Key, Value) ->
	tfstat(erldis_client:sr_scall(Client, [<<"setnx">>, Key, Value])).

incr(Client, Key) ->
	numeric(erldis_client:sr_scall(Client, [<<"incr">>, Key])).

incrby(Client, Key, By) ->
	numeric(erldis_client:sr_scall(Client, [<<"incrby">>, Key, By])).

decr(Client, Key) ->
	numeric(erldis_client:sr_scall(Client, [<<"decr">>, Key])).

decrby(Client, Key, By) ->
	numeric(erldis_client:sr_scall(Client, [<<"decrby">>, Key, By])).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Commands operating on lists %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rpush(Client, Key, Value) ->
	numeric(erldis_client:sr_scall(Client, [<<"rpush">>, Key, Value])).

lpush(Client, Key, Value) ->
	numeric(erldis_client:sr_scall(Client, [<<"lpush">>, Key, Value])).

llen(Client, Key) ->
	numeric(erldis_client:sr_scall(Client, [<<"llen">>, Key])).

lrange(Client, Key, Start, End) ->
	erldis_client:scall(Client, [<<"lrange">>, Key, Start, End]).

ltrim(Client, Key, Start, End) ->
	erldis_client:sr_scall(Client, [<<"ltrim">>, Key, Start, End]).
	
lindex(Client, Key, Index) ->
	erldis_client:sr_scall(Client, [<<"lindex">>, Key, Index]).

lset(Client, Key, Index, Value) ->
	erldis_client:sr_scall(Client, [<<"lset">>, Key, Index, Value]).

lrem(Client, Key, Number, Value) ->
	numeric(erldis_client:sr_scall(Client, [<<"lrem">>, Key, Number, Value])).

lpop(Client, Key) -> erldis_client:sr_scall(Client, [<<"lpop">>, Key]).

rpop(Client, Key) -> erldis_client:sr_scall(Client, [<<"rpop">>, Key]).

% TODO: multibulk_cmd
blpop(Client, Keys) -> erldis_client:bcall(Client, [<<"blpop">> | Keys], infinity).
blpop(Client, Keys, Timeout) -> erldis_client:bcall(Client, [<<"blpop">> | Keys], Timeout).

brpop(Client, Keys) -> erldis_client:bcall(Client, [<<"brpop">> | Keys], infinity).
brpop(Client, Keys, Timeout) -> erldis_client:bcall(Client, [<<"brpop">> | Keys], Timeout).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Commands operating on sets %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sadd(Client, Key, Member) ->
	updatestat(erldis_client:sr_scall(Client, [<<"sadd">>, Key, Member])).

srem(Client, Key, Member) ->
	erldis_client:sr_scall(Client, [<<"srem">>, Key, Member]).

spop(Client, Key) ->
	erldis_client:sr_scall(Client, [<<"spop">>, Key]).

% TODO: test
smove(Client, SrcKey, DstKey, Member) ->
	erldis_client:sr_scall(Client, [<<"smove">>, SrcKey, DstKey, Member]).

scard(Client, Key) ->
	numeric(erldis_client:sr_scall(Client, [<<"scard">>, Key])).

sismember(Client, Key, Member) ->
	tfstat(erldis_client:sr_scall(Client, [<<"sismember">>, Key, Member])).

sintersect(Client, Keys) -> sinter(Client, Keys).

sinter(Client, Keys) -> erldis_client:scall(Client, [<<"sinter">> | Keys]).

sinterstore(Client, DstKey, Keys) ->
	numeric(erldis_client:sr_scall(Client, [<<"sinterstore">>, DstKey | Keys])).

sunion(Client, Keys) ->
	erldis_client:scall(Client, [<<"sunion">> | Keys]).

sunionstore(Client, DstKey, Keys) ->
	numeric(erldis_client:sr_scall(Client, [<<"sunionstore">>, DstKey | Keys])).

sdiff(Client, Keys) -> erldis_client:scall(Client, [<<"sdiff">> | Keys]).

sdiffstore(Client, DstKey, Keys) ->
	numeric(erldis_client:sr_scall(Client, [<<"sdiffstore">>, DstKey | Keys])).

smembers(Client, Key) ->
	erldis_client:scall(Client, [<<"smembers">>, Key]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Commands operating on ordered sets %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

zadd(Client, Key, Score, Member) ->
	updatestat(erldis_client:sr_scall(Client, [<<"zadd">>, Key, Score, Member])).

zrem(Client, Key, Member) ->
	tfstat(erldis_client:sr_scall(Client, [<<"zrem">>, Key, Member])).

zincrby(Client, Key, By, Member) ->
	numeric(erldis_client:sr_scall(Client, [<<"zincrby">>, Key, By, Member])).

zrange(Client, Key, Start, End) ->
	erldis_client:scall(Client, [<<"zrange">>, Key, Start, End]).

zrange_withscores(Client, Key, Start, End) ->
	withscores(erldis_client:scall(Client, [<<"zrange">>, Key, Start, End, <<"withscores">>])).

zrevrange(Client, Key, Start, End) ->
	erldis_client:scall(Client, [<<"zrevrange">>, Key, Start, End]).

zrevrange_withscores(Client, Key, Start, End) ->
	withscores(erldis_client:scall(Client, [<<"zrevrange">>, Key, Start, End, <<"withscores">>])).

zrangebyscore(Client, Key, Min, Max) ->
	erldis_client:scall(Client, [<<"zrangebyscore">>, Key, Min, Max]).

zrangebyscore(Client, Key, Min, Max, Offset, Count) ->
	Cmd = [<<"zrangebyscore">>, Key, Min, Max, <<"limit">>, Offset, Count],
	erldis_client:scall(Client, Cmd).

zcard(Client, Key) ->
	numeric(erldis_client:sr_scall(Client, [<<"zcard">>, Key])).

zscore(Client, Key, Member) ->
	numeric(erldis_client:sr_scall(Client, [<<"zscore">>, Key, Member])).

zremrangebyscore(Client, Key, Min, Max) ->
	Cmd = [<<"zremrangebyscore">>, Key, Min, Max],
	numeric(erldis_client:sr_scall(Client, Cmd)).

%%%%%%%%%%%%%%%%%%%
%% Hash commands %%
%%%%%%%%%%%%%%%%%%%

hset(Client, Key, Field, Value) ->
	numeric(erldis_client:sr_scall(Client, [<<"hset">>, Key, Field, Value])).

hget(Client, Key, Field) ->
	erldis_client:sr_scall(Client, [<<"hget">>, Key, Field]).

hmset(Client, Key, Fields) ->
	erldis_client:sr_scall(Client, [<<"hmset">>, Key | Fields]).

hincrby(Client, Key, Field, Incr) ->
	numeric(erldis_client:sr_scall(Client, [<<"hincrby">>, Key, Field, Incr])).

hdel(Client, Key, Field) ->
	tfstat(erldis_client:sr_scall(Client, [<<"hdel">>, Key, Field])).

hlen(Client, Key) ->
	numeric(erldis_client:sr_scall(Client, [<<"hlen">>, Key])).

hexists(Client, Key, Field) ->
	tfstat(erldis_client:sr_scall(Client, [<<"hexists">>, Key, Field])).

hkeys(Client, Key) ->
	erldis_client:scall(Client, [<<"hkeys">>, Key]).

hgetall(Client, Key) ->
	erldis_client:scall(Client, [<<"hgetall">>, Key]).

%%%%%%%%%%%%%
%% Sorting %%
%%%%%%%%%%%%%

sort(Client, Key) -> erldis_client:scall(Client, [<<"sort">>, Key]).

% TODO: better support for Extra options (LIMIT, ASC|DESC, BY, GET, STORE)
sort(Client, Key, Extra) when is_binary(Key), is_binary(Extra) ->
	ExtraParts = re:split(Extra, <<" ">>),
	erldis_client:scall(Client, [<<"sort">>, Key | ExtraParts]).
	
%%%%%%%%%%%%%
%% PubSub  %%
%%%%%%%%%%%%%

publish(Client, Channel, Value) ->
  numeric(
    erldis_client:sr_scall(Client, [<<"publish">>, Channel, Value])).
unsubscribe(Client)->
  unsubscribe(Client, <<"">>).
unsubscribe(Client, Channel) ->
   U = <<"unsubscribe">>,
   Cmd = case Channel of
           <<"">> -> [U];
                _ -> [U, Channel]
         end,
   case erldis_client:unsubscribe(Client, multibulk_cmd(Cmd), Channel) of 
      [<<"unsubscribe">>, FirstChan, N] ->
        {FirstChan, numeric(N)};
     E ->
        E
    end.
subscribe(Client, Channel, Pid) ->
   case erldis_client:subscribe(Client, multibulk_cmd([<<"subscribe">>, Channel]), Channel, Pid) of
     [<<"subscribe">>, Channel, N] ->
       numeric(N);
      _ ->
        error
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Multiple DB commands %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

select(Client, Index) ->
	erldis_client:sr_scall(Client, [<<"select">>, Index]).

move(Client, Key, DBIndex) ->
	erldis_client:sr_scall(Client, [<<"move">>, Key, DBIndex]).

flushdb(Client) -> erldis_client:sr_scall(Client, <<"flushdb">>).

flushall(Client) -> erldis_client:sr_scall(Client, <<"flushall">>).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Persistence control commands %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save(Client) -> erldis_client:scall(Client, <<"save">>).

bgsave(Client) -> erldis_client:scall(Client, <<"bgsave">>).

lastsave(Client) -> erldis_client:scall(Client, <<"lastsave">>).

shutdown(Client) -> erldis_client:scall(Client, <<"shutdown">>).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Remote server control commands %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

auth(Client, Password) ->
	erldis_client:scall(Client, [<<"auth">>, Password]).

info(Client) -> erldis_client:scall(Client, <<"info">>).

slaveof(Client, Host, Port) ->
	erldis_client:scall(Client, [<<"slaveof">>, Host, Port]).

slaveof(Client) ->
	erldis_client:scall(Client, [<<"slaveof">>, <<"no one">>]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Multi/Exec Pipelining %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

get_all_results(Client) -> gen_server2:call(Client, get_all_results).

set_pipelining(Client, Bool) -> gen_server2:cast(Client, {pipelining, Bool}).

exec(Client, Fun) ->
	case erldis_client:sr_scall(Client, <<"multi">>) of
		ok ->
			set_pipelining(Client, true),
			Fun(Client),
			get_all_results(Client),
			set_pipelining(Client, false),
			erldis_client:scall(Client, <<"exec">>);
		_ ->
			{error, unsupported}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%
%% command generators %%
%%%%%%%%%%%%%%%%%%%%%%%%

-define(i2l(X), integer_to_list(X)).
multibulk_cmd(Args) when is_binary(Args) ->
  multibulk_cmd([Args]);
multibulk_cmd(Args) when is_list(Args) ->
  TotalLength = length(Args),
 
  ArgCount = [<<"*">>, ?i2l(TotalLength), <<"\r\n">>],
  ArgBin = [[<<"$">>, ?i2l(iolist_size(A)), <<"\r\n">>, 
             A, <<"\r\n">>] || A <- [erldis_binaries:to_binary(B) || B <- Args]],

  [ArgCount, ArgBin].


%%%%%%%%%%%%%%%%%%%%%%
%% reply conversion %%
%%%%%%%%%%%%%%%%%%%%%%

numeric(false) -> 0;
numeric(true) -> 1;
numeric(nil) -> 0;
numeric(I) when is_binary(I) -> numeric(binary_to_list(I));
numeric(I) when is_list(I) ->
	try list_to_integer(I)
	catch
		error:badarg ->
			try list_to_float(I)
			catch error:badarg -> I
			end
	end;
numeric(I) -> I.

updatestat(<<"1">>) -> added;
updatestat(<<"0">>) -> updated.

tfstat(<<"1">>) -> true;
tfstat(<<"0">>) -> false.

withscores(L) -> 
	withscores(L,[]).
withscores([], Acc) ->
	lists:reverse(Acc);
withscores([_], _Acc) ->
	erlang:error(badarg);
withscores([Member, Score | T], Acc) ->
	withscores(T, [{Member, numeric(Score)} | Acc]).
