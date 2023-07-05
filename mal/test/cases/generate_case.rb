s = $gtk.cli_arguments[:step].trim
print s + "\n"
f = $gtk.read_file "mal/test/cases/step_template.rb"
f.gsub! "<step>", s
$gtk.write_file "test/cases/" + s + ".rb", f
