local env=env
local chart=env.class(env.graph)

function chart:ctor()
    self.db=env.db2
    self.command={"chart","ch"}
    self.help_title='Show graph chart. '
    self.script_dir=env.WORK_DIR.."db2"..env.PATH_DEL.."chart"
end

return chart.new()