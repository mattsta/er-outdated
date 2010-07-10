{application, er,
 [
  {description, "Erlang Redis Library Application"},
  {vsn, "0.1.4"},
  {modules, [
             % new, good, er modules
             er,
             er_app,
             er_pool,
             er_server,
             er_sup,
             erp,

             % Brought in from redis-erl
             er_redis
            ]},
  {registered, [er_sup]},
  {applications, [
                  kernel,
                  stdlib
                 ]},
  {mod, {er_app, []}},
  {env, []}
 ]}.