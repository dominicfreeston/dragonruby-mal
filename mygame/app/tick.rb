$mal  ||= Mal::Repl.new
$file ||= "app/game.mal"
  
def tick args
  last_modified = $gtk.stat_file($file).mod_time
  if args.state.last_modified != last_modified
    $mal.RE("(load-file \"" + $file + "\")")
    args.state.last_modified = last_modified
    puts "reloading file"
  end

  $mal.RE("(tick)")
  args.outputs.primitives << $mal.RE("@graphics")
  args.outputs.primitives << args.gtk.framerate_diagnostics_primitives
end
