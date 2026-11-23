local actions, calls, answer = {}, {}, nil
local ctx = { session_id = 's', block_id = 'b' }
rex = {
  action = function(a) actions[a.name] = a.run end, bind = function() end, mode = function() end,
  ui = {pick = function(prompt) ctx.block_id = 'changed'; return answer, 'cancelled' end},
  exec = function(argv)
    calls[#calls+1] = argv
    return {ok=true, stdout={window='w', scope='tab', detail='1 shell', title='api › logs'}}
  end,
  json = {decode = function(x) return x end}, log = function() end,
}
dofile('rex/.config/rex/init.lua')
assert(actions.archive_this_tab, 'missing Archive This Tab action')
actions.archive_this_tab(ctx)
assert(#calls == 1, 'cancel must not archive')
ctx.block_id, answer = 'b', 'archive'
actions.archive_this_tab(ctx)
local argv = calls[3]
assert(argv[#argv-3] == 'archive-confirmed' and argv[#argv-2] == 's' and argv[#argv-1] == 'w')
local restored, selected, choices = false, false, {}
rex.exec = function(argv)
  if argv[#argv] == 'catalog' then
    return {ok=true, stdout={archives={{id='archive:logs',title='logs',destination='choose'}},
      sessions={{id='session:dest',title='api'}}}}
  end
  assert(argv[#argv-2]=='restore-to' and argv[#argv-1]=='archive:logs' and argv[#argv]=='session:dest')
  restored = true
  return {ok=true, stdout={session='session:dest'}}
end
rex.ui.pick = function() return table.remove(choices, 1), nil end
rex.client = {queue=function(action, args) selected = action=='session.select' and args.session_id=='session:dest' end}
choices = {'archive:logs', 'session:dest'}
actions.restore_archived_work(ctx)
assert(restored and selected)
print('archive UI tests passed')
